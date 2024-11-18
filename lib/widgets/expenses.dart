import 'package:expense_tracker/widgets/add_expense_modal.dart';
import 'package:expense_tracker/widgets/chart/chart.dart';
import 'package:expense_tracker/widgets/expenses_list/expenses_list.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/data/dummy_expenses.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});
  @override
  State<Expenses> createState() {
    return _ExpensesState();
  }
}

class _ExpensesState extends State<Expenses> {
  final List<Expense> _registeredExpenses = expenses;

  void _openAddExpenseModal() {
    showModalBottomSheet(
      useSafeArea: true,
      showDragHandle: true,
      scrollControlDisabledMaxHeightRatio: 0.8,
      context: context,
      builder: (ctx) => AddExpenseModal(
        onAddExpense: _addExpense,
      ),
    );
  }

  void _addExpense(Expense expense) {
    setState(() {
      _registeredExpenses.add(expense);
    });
  }

  void _removeExpense(Expense expense) {
    final index = _registeredExpenses.indexOf(expense);
    setState(() {
      _registeredExpenses.remove(expense);
    });
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: const Text("Expense deleted."),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
              label: "Undo",
              onPressed: () {
                setState(() {
                  _registeredExpenses.insert(index, expense);
                });
              })),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget mainContent = const Center(
      child: Text("No recorded expenses, add a new one"),
    );
    if (_registeredExpenses.isNotEmpty) {
      mainContent = Column(
        children: [
          Chart(expenses: _registeredExpenses),
          Expanded(
            child: ExpensesList(
                expenses: _registeredExpenses, onRemoveExpense: _removeExpense),
          ),
        ],
      );
    }
    return Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
                onPressed: _openAddExpenseModal, icon: const Icon(Icons.add))
          ],
          title: const Text("Expense Tracker"),
        ),
        body: Column(
          children: [
            Expanded(
              child: mainContent,
            ),
          ],
        ));
  }
}
