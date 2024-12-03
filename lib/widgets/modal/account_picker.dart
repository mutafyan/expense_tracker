import 'package:expense_tracker/models/account/account.dart';
import 'package:flutter/material.dart';

class AccountPicker extends StatelessWidget {
  const AccountPicker({
    required this.selectedAccount,
    required this.availableAccounts,
    required this.onChange,
    super.key,
  });
  final void Function(dynamic) onChange;
  final Account? selectedAccount;
  final List<Account> availableAccounts;
  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<Account>(
      value: selectedAccount,
      hint: const Text("Select Account"),
      onChanged: onChange,
      decoration: const InputDecoration(
        border: OutlineInputBorder(),
        labelText: "Account",
      ),
      selectedItemBuilder: (BuildContext context) {
        return availableAccounts.map<Widget>((Account account) {
          return Row(
            children: [
              Icon(account.iconData),
              const SizedBox(width: 5),
              Text(account.displayName),
            ],
          );
        }).toList();
      },
      items: availableAccounts
          .map(
            (account) => DropdownMenuItem(
              value: account,
              child: Expanded(
                child: Row(
                  children: [
                    Icon(account.iconData),
                    const SizedBox(width: 5),
                    Text(account.displayName),
                    const Spacer(),
                    Text("֏ ${account.displayBalance.toString()}"),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
