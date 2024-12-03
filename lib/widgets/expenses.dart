import 'package:expense_tracker/screens/settings/settings_screen.dart';
import 'package:expense_tracker/widgets/account_manager/account_preview.dart';
import 'package:expense_tracker/widgets/chart/collapsible.dart';
import 'package:expense_tracker/widgets/modal/add_button.dart';
import 'package:expense_tracker/widgets/modal/add_expense_modal.dart';
import 'package:expense_tracker/widgets/chart/expanded_chart.dart';
import 'package:expense_tracker/widgets/chart/collapsed_chart.dart';
import 'package:expense_tracker/widgets/expenses_list/expenses_list.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/data/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

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
  final _scrollController = ScrollController();
  bool _isFabVisible = true;

  @override
  void initState() {
    super.initState();
    _loadData(); // Load accounts and expenses from the database when initializing
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await dbHelper.addDefaultAccounts(); // Ensure default accounts are added
    final visibleAccounts = await _loadVisibleAccounts();
    final expenses = await dbHelper.getAllExpenses(visibleAccounts);
    setState(() {
      _accounts = visibleAccounts;
      _registeredExpenses = expenses;
    });
  }

  Future<List<Account>> _loadVisibleAccounts() async {
    final allAccounts = await dbHelper.getAllAccounts();

    final visibleAccounts =
        allAccounts.where((account) => account.isVisible).toList();
    return visibleAccounts;
  }

  Future<void> _refreshAccounts() async {
    final visibleAccounts = await _loadVisibleAccounts();
    setState(() {
      _accounts = visibleAccounts;
    });
  }

  void _onScroll() {
    _toggleFabVisibility();
  }

  void _toggleFabVisibility() {
    if (_scrollController.position.userScrollDirection ==
        ScrollDirection.reverse) {
      if (_isFabVisible) {
        setState(() {
          _isFabVisible = false;
        });
      }
    } else if (_scrollController.position.userScrollDirection ==
        ScrollDirection.forward) {
      if (!_isFabVisible) {
        setState(() {
          _isFabVisible = true;
        });
      }
    }
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
    await _refreshAccounts();
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
    await _refreshAccounts();

    setState(() {
      _registeredExpenses.removeAt(index);
    });

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
            await dbHelper.insertExpense(expense);
            updatedAccount.deductExpense(expense.amount);
            await dbHelper.updateAccount(updatedAccount);
            await _refreshAccounts();

            setState(() {
              _registeredExpenses.insert(index, expense);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          _isFabVisible ? AddButton(onPress: _openAddExpenseModal) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
                );
                _refreshAccounts(); // Refresh data after returning from settings
                _loadData(); // Reload data to reflect changes
              },
              icon: const Icon(Icons.settings))
        ],
        title: const Text("Expense Tracker"),
      ),
      body: Column(
        children: [
          SizedBox(
            height: 100.0,
            child: AccountPreview(
              accounts: _accounts,
              onAccountUpdated: _refreshAccounts,
            ),
          ),
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverPersistentHeader(
                  pinned: false,
                  floating: false,
                  delegate: CollapsibleChartDelegate(
                    expandedChart: ExpandedChart(expenses: _registeredExpenses),
                    collapsedChart:
                        CollapsedChart(expenses: _registeredExpenses),
                    expandedHeight: 200.0,
                    collapsedHeight: 20.0,
                  ),
                ),
                ExpensesList(
                  expenses: _registeredExpenses,
                  onRemoveExpense: _removeExpense,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
