import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/widgets/account_manager/add_income_modal.dart';
import 'package:flutter/material.dart';

class AccountPreview extends StatelessWidget {
  final List<Account> accounts;
  final VoidCallback onAccountUpdated;
  final VoidCallback onAddAccount; // Callback to open add account modal
  final bool isAddAccountEnabled; // Indicates if adding accounts is allowed

  const AccountPreview({
    Key? key,
    required this.accounts,
    required this.onAccountUpdated,
    required this.onAddAccount,
    required this.isAddAccountEnabled,
  }) : super(key: key);

  void _openAddIncomeModal(BuildContext context, Account account) {
    showModalBottomSheet(
      useSafeArea: true,
      showDragHandle: true,
      context: context,
      builder: (context) => AddIncomeModal(
        account: account,
        onIncomeAdded: onAccountUpdated, // Notify parent to refresh accounts
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height / 9;
    final itemCount =
        isAddAccountEnabled ? accounts.length + 1 : accounts.length;

    return SizedBox(
      height: height,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < accounts.length) {
            final account = accounts[index];
            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  ],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                border: const Border(
                  right: BorderSide(
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        IconData(
                          account.iconData.codePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        account.displayName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          _openAddIncomeModal(context, account);
                        },
                        icon: Icon(
                          Icons.add_circle,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    "֏${account.displayBalance}",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          } else {
            // Add Account Button
            return GestureDetector(
              onTap: onAddAccount,
              child: Container(
                width: 150,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    Icons.add,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 40,
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
