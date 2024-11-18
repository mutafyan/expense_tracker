import 'package:expense_tracker/widgets/modal/add_button.dart';
import 'package:expense_tracker/widgets/modal/add_expense_modal.dart';
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
    final height = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: (height < 600) ? true : false,
      scrollControlDisabledMaxHeightRatio: 0.75,
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

  void _openAddCategoryModal() {}

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    Widget mainContent = const Center(
      child: Text("No recorded expenses, add a new one"),
    );
    if (_registeredExpenses.isNotEmpty) {
      mainContent = Column(
        children: [
          Expanded(
            child: ExpensesList(
                expenses: _registeredExpenses, onRemoveExpense: _removeExpense),
          ),
        ],
      );
    }
    return Scaffold(
      floatingActionButton: AddButton(onPress: _openAddExpenseModal),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        actions: [
          PopupMenuButton<int>(
            onSelected: (value) {
              switch (value) {
                case 0:
                  _openAddCategoryModal;
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Text('Add Category'),
              ),
            ],
          ),
        ],
        title: const Text("Expense Tracker"),
      ),
      body: width < 600
          ? Column(
              children: [
                Chart(expenses: _registeredExpenses),
                Expanded(
                  child: mainContent,
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: Chart(expenses: _registeredExpenses),
                ),
                Expanded(
                  child: mainContent,
                ),
              ],
            ),
    );
  }
}
