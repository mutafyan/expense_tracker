import 'package:flutter/material.dart';
import 'package:expense_tracker/widgets/chart/chart_bar.dart';
import 'package:expense_tracker/models/expense_bucket.dart';
import 'package:expense_tracker/models/expense.dart';

class ExpandedChart extends StatelessWidget {
  const ExpandedChart({super.key, required this.expenses});

  final List<Expense> expenses;

  List<ExpenseBucket> get buckets {
    return [
      ExpenseBucket.forCategory(expenses, Category.food),
      ExpenseBucket.forCategory(expenses, Category.leisure),
      ExpenseBucket.forCategory(expenses, Category.health),
      ExpenseBucket.forCategory(expenses, Category.transport),
    ];
  }

  int get maxTotalExpense {
    int maxTotalExpense = 0;

    for (final bucket in buckets) {
      if (bucket.totalAmount > maxTotalExpense) {
        maxTotalExpense = bucket.totalAmount;
      }
    }

    return maxTotalExpense;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        // Define proportions for each section
        final barSectionHeight = availableHeight * 0.6;
        final iconSectionHeight = availableHeight * 0.2;
        final spacingHeight = availableHeight * 0.01;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: availableHeight * 0.08,
            vertical: availableHeight * 0.01,
          ),
          padding: EdgeInsets.symmetric(
            vertical: availableHeight * 0.08,
            horizontal: availableHeight * 0.02,
          ),
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.3),
                Theme.of(context).colorScheme.primary.withOpacity(0.0)
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: barSectionHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final bucket in buckets)
                      ChartBar(
                        fill: maxTotalExpense == 0
                            ? 0
                            : bucket.totalAmount / maxTotalExpense,
                      )
                  ],
                ),
              ),
              SizedBox(height: spacingHeight),
              SizedBox(
                height: iconSectionHeight,
                child: Row(
                  children: buckets
                      .map(
                        (bucket) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: availableHeight * 0.01,
                            ),
                            child: Icon(
                              categoryIcons[bucket.category],
                              size: iconSectionHeight * 0.6,
                              color: isDarkMode
                                  ? Theme.of(context).colorScheme.secondary
                                  : Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.7),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
