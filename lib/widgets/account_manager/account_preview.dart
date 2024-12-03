// widgets/account_preview.dart
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/widgets/account_manager/add_income_modal.dart';
import 'package:flutter/material.dart';

class AccountPreview extends StatelessWidget {
  final List<Account> accounts;
  final VoidCallback onAccountUpdated;

  const AccountPreview({
    super.key,
    required this.accounts,
    required this.onAccountUpdated,
  });

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
    final width = MediaQuery.of(context).size.width - 32;

    return SizedBox(
      height: height,
      width: width,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: accounts.map((account) {
          return Expanded(
            child: Container(
              margin: const EdgeInsets.fromLTRB(0, 6, 6, 0),
              padding: const EdgeInsets.fromLTRB(16, 0, 0, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    Theme.of(context).colorScheme.primary.withOpacity(0.0),
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
                        account.iconData,
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
            ),
          );
        }).toList(),
      ),
    );
  }
}
