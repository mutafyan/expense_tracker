import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/widgets/account_manager/add_account_modal.dart';
import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  List<Account> _accounts = [];
  final dbHelper = DatabaseHelper.instance;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await dbHelper.getAllAccounts(includeHidden: true);
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load accounts: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleVisibility(Account account) async {
    // Prevent hiding all default accounts
    if (account.isDefault &&
        _accounts.where((cat) => cat.isDefault && cat.isVisible).length == 1 &&
        account.isVisible) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("At least one default account must be visible.")),
      );
      return;
    }

    final updatedAccount = Account(
      id: account.id,
      name: account.name,
      balance: account.balance,
      isDefault: account.isDefault,
      isVisible: !account.isVisible,
      iconData: account.iconData,
    );

    try {
      await dbHelper.updateAccount(updatedAccount);
      await _loadAccounts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update account: $e')),
      );
    }
  }

  Future<void> _deleteAccount(Account account) async {
    if (account.isDefault) {
      // Prevent deletion of default accounts
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cannot delete a default account.')),
      );
      return;
    }

    // Confirm deletion
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${account.displayName}" Account?'),
        content: const Text(
            'Are you sure you want to delete this account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await dbHelper.deleteAccount(account.id);
      await _loadAccounts();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Account "${account.displayName}" deleted successfully.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete account: $e')),
      );
    }
  }

  void _openAddAccountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddAccountModal(
        onAccountAdded: () async {
          await _loadAccounts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine the number of active accounts
    final activeAccountsCount = _accounts.where((acc) => acc.isVisible).length;
    final isLimitReached = activeAccountsCount >= 10;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Account Settings"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    // Account List
                    Expanded(
                      child: _accounts.isEmpty
                          ? const Center(
                              child: Text("No accounts available."),
                            )
                          : ListView.builder(
                              itemCount: _accounts.length,
                              itemBuilder: (context, index) {
                                final account = _accounts[index];
                                return ListTile(
                                  leading: Icon(
                                    IconData(
                                      account.iconData.codePoint,
                                      fontFamily: 'MaterialIcons',
                                    ),
                                    color: account.isVisible
                                        ? Theme.of(context)
                                            .colorScheme
                                            .secondary
                                        : Colors.grey,
                                  ),
                                  title: Text(account.displayName),
                                  subtitle: account.isDefault
                                      ? const Text('Default Account')
                                      : const Text('Custom Account'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Delete Button for non-default accounts
                                      if (!account.isDefault)
                                        IconButton(
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                          ),
                                          onPressed: () =>
                                              _deleteAccount(account),
                                        ),
                                      // Visibility Toggle
                                      Switch(
                                        value: account.isVisible,
                                        onChanged: (value) =>
                                            _toggleVisibility(account),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      child: Column(
                        children: [
                          isLimitReached
                              ? Text(
                                  'You have reached the maximum of 10 active accounts.',
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                )
                              : Text(
                                  'Maximum 10 active accounts are allowed',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall!
                                      .copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSecondaryContainer),
                                  textAlign: TextAlign.center,
                                ),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed:
                                isLimitReached ? null : _openAddAccountModal,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Account'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 20),
                              textStyle: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
