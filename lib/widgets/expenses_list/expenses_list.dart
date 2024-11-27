import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/widgets/expenses_list/expense_item.dart';
import 'package:flutter/material.dart';

class ExpensesList extends StatelessWidget {
  const ExpensesList({
    super.key,
    required this.expenses,
    required this.onRemoveExpense,
  });

  final List<Expense> expenses;
  final void Function(Expense expense) onRemoveExpense;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final expense = expenses[index];
          return Dismissible(
            key: ValueKey(expense),
            direction: DismissDirection.endToStart,
            background: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.error,
              ),
              child: const Row(
                children: [
                  Spacer(),
                  Icon(
                    Icons.delete_outline,
                    size: 30,
                  ),
                  SizedBox(width: 16),
                ],
              ),
            ),
            onDismissed: (direction) {
              onRemoveExpense(expense);
            },
            child: ExpenseItem(expense),
          );
        },
        childCount: expenses.length,
      ),
    );
  }
}
