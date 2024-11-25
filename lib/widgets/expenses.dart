import 'package:expense_tracker/widgets/modal/add_button.dart';
import 'package:expense_tracker/widgets/modal/add_expense_modal.dart';
import 'package:expense_tracker/widgets/chart/chart.dart';
import 'package:expense_tracker/widgets/expenses_list/expenses_list.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/data/db_helper.dart';
import 'package:flutter/material.dart';

class Expenses extends StatefulWidget {
  const Expenses({super.key});

  @override
  State<Expenses> createState() {
    return _ExpensesState();
  }
}

class _ExpensesState extends State<Expenses> {
  final dbHelper = DatabaseHelper.instance;
  List<Expense> _registeredExpenses = [];
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadData(); // Load accounts and expenses from the database when initializing
  }

  Future<void> _loadData() async {
    await dbHelper
        .addDefaultAccounts(); // add cash and card as default accounts
    final accounts = await dbHelper.getAllAccounts();
    final expenses = await dbHelper.getAllExpenses(accounts);
    setState(() {
      _accounts = accounts;
      _registeredExpenses = expenses;
    });
  }

  void _openAddExpenseModal() {
    final height = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: height < 600,
      scrollControlDisabledMaxHeightRatio: 0.85,
      context: context,
      builder: (ctx) => AddExpenseModal(
        onAddExpense: _addExpense,
      ),
    );
  }

  void _addExpense(Expense expense) async {
    await dbHelper.insertExpense(expense);
    final updatedAccount = expense.account;
    updatedAccount.deductExpense(expense.amount);
    await dbHelper.updateAccount(updatedAccount);

    setState(() {
      _registeredExpenses.add(expense);
    });
  }

  void _removeExpense(Expense expense) async {
    final index = _registeredExpenses.indexOf(expense);
    final updatedAccount = expense.account;
    await dbHelper.deleteExpense(expense.id);
    updatedAccount.addIncome(expense.amount);
    await dbHelper.updateAccount(updatedAccount);

    setState(() {
      _registeredExpenses.removeAt(index);
    });

    // Show snackbar with undo option
    _showSnackBar(expense, updatedAccount, index);
  }

  void _showSnackBar(Expense expense, Account updatedAccount, int index) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Expense deleted."),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () async {
            // Re-add the expense to the database and the local list
            await dbHelper.insertExpense(expense);
            updatedAccount.deductExpense(expense.amount);
            await dbHelper.updateAccount(updatedAccount);
            setState(() {
              _registeredExpenses.insert(index, expense);
            });
          },
        ),
      ),
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
      mainContent = ExpensesList(
        expenses: _registeredExpenses,
        onRemoveExpense: _removeExpense,
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
                  _openAddCategoryModal();
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
