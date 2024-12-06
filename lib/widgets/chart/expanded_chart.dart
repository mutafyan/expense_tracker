import 'package:flutter/material.dart';
import 'package:expense_tracker/widgets/chart/chart_bar.dart';
import 'package:expense_tracker/models/expense/expense_bucket.dart';
import 'package:expense_tracker/models/expense/expense.dart';
import 'package:expense_tracker/models/category/category.dart';

class ExpandedChart extends StatelessWidget {
  const ExpandedChart({
    super.key,
    required this.expenses,
    required this.categories,
  });

  final List<Expense> expenses;
  final List<Category> categories;

  List<ExpenseBucket> get buckets {
    return categories
        .map((category) => ExpenseBucket.forCategory(expenses, category))
        .toList();
  }

  int get totalExpenses {
    int total = 0;
    for (final bucket in buckets) {
      total += bucket.totalAmount;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        MediaQuery.of(context).platformBrightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableHeight = constraints.maxHeight;

        // Define proportions for each section
        final barSectionHeight = availableHeight * 0.8;

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: availableHeight * 0.07,
            vertical: availableHeight * 0.01,
          ),
          padding: EdgeInsets.symmetric(
            vertical: availableHeight * 0.05,
            horizontal: availableHeight * 0.01,
          ),
          width: double.infinity,
          height: availableHeight,
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
                    for (int i = 0; i < buckets.length; i++)
                      Expanded(
                        child: ChartBar(
                          label: buckets[i].category.name,
                          showLabel: buckets.length < 5 ? true : false,
                          fill: totalExpenses == 0
                              ? 0
                              : buckets[i].totalAmount / totalExpenses,
                          iconCodePoint: buckets[i].category.iconCodePoint,
                        ),
                      )
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
