import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction/financial_transaction.dart';
import 'package:expense_tracker/models/transaction/financial_transaction_type.dart';

class TransactionItem extends StatelessWidget {
  const TransactionItem({super.key, required this.transaction});

  final FinancialTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final isExpense = transaction.type == FinancialTransactionType.expense;
    final amountColor = isExpense ? Colors.red : Colors.green;
    final amountPrefix = isExpense ? '-' : '+';
    final currencySymbol = transaction.currency.displaySymbol;

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
                  transaction.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Icon(transaction.account.iconData),
              ],
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  '$amountPrefix${transaction.amount} $currencySymbol',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: amountColor),
                ),
                const Spacer(),
                Row(
                  children: [
                    if (isExpense)
                      Icon(
                        IconData(
                          transaction.category.iconCodePoint,
                          fontFamily: 'MaterialIcons',
                        ),
                      ),
                    const SizedBox(width: 5),
                    Text(
                      transaction.formattedDate,
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
