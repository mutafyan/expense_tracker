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

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await dbHelper.getAllAccounts(includeHidden: true);
    setState(() {
      _accounts = accounts;
    });
  }

  void _toggleVisibility(Account account) async {
    setState(() {
      account.isVisible = !account.isVisible;
    });
    await dbHelper.updateAccount(account);
  }

  void _deleteAccount(Account account) async {
    if (account.isDefault) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${account.displayName}?'),
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

    await dbHelper.deleteAccount(account.id);
    await _loadAccounts();
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
    return Scaffold(
        appBar: AppBar(
          title: const Text("Account Settings"),
        ),
        body: _accounts.isEmpty
            ? const Center(child: Text("No accounts available."))
            : ListView.builder(
                itemCount: _accounts.length,
                itemBuilder: (context, index) {
                  final account = _accounts[index];
                  return ListTile(
                    leading: Icon(
                      account.iconData,
                      color: Theme.of(context).colorScheme.secondary,
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
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteAccount(account),
                          ),
                        // Visibility Toggle
                        Switch(
                          value: account.isVisible,
                          onChanged: (value) => _toggleVisibility(account),
                        ),
                      ],
                    ),
                  );
                },
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: _openAddAccountModal,
          child: const Icon(Icons.add),
        ));
  }
}
