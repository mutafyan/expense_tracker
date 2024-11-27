import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';

class CollapsedChart extends StatelessWidget {
  final List<Expense> expenses;

  const CollapsedChart({super.key, required this.expenses});

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        child: const SizedBox(
          width: 0,
          height: 0,
        ));
  }
}