import 'package:expense_tracker/widgets/transactions_list/transaction_item.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction/financial_transaction.dart';

class TransactionsList extends StatelessWidget {
  const TransactionsList({
    super.key,
    required this.transactions,
    required this.onRemoveTransaction,
  });

  final List<FinancialTransaction> transactions;
  final void Function(FinancialTransaction transaction) onRemoveTransaction;

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          final tx = transactions[index];
          return Dismissible(
            key: ValueKey(tx.id),
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
              onRemoveTransaction(tx);
            },
            child: TransactionItem(transaction: tx),
          );
        },
        childCount: transactions.length,
      ),
    );
  }
}
