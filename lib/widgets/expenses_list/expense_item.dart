// lib/widgets/expenses_list/expense_item.dart
import 'package:expense_tracker/models/expense/expense.dart';
import 'package:flutter/material.dart';

class ExpenseItem extends StatelessWidget {
  const ExpenseItem(this.expense, {super.key});
  final Expense expense;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  expense.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Icon(
                  expense.account.iconData,
                ),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  '֏${expense.amount.toString()}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      IconData(
                        expense.category.iconCodePoint,
                        fontFamily: 'MaterialIcons',
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      expense.formattedDate,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
