import 'package:expense_tracker/models/transaction/financial_transaction_type.dart';
import 'package:expense_tracker/screens/settings/settings_screen.dart';
import 'package:expense_tracker/widgets/account_manager/account_preview.dart';
import 'package:expense_tracker/widgets/account_manager/add_account_modal.dart';
import 'package:expense_tracker/widgets/chart/expanded_chart.dart';
import 'package:expense_tracker/widgets/modal/add_button.dart';
import 'package:expense_tracker/widgets/modal/add_transaction_modal.dart';
import 'package:expense_tracker/widgets/transactions_list/transactions_list.dart';
import 'package:expense_tracker/models/transaction/financial_transaction.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/data/db_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:expense_tracker/models/category/category.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final dbHelper = DatabaseHelper.instance;
  List<FinancialTransaction> _registeredTransactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  final _scrollController = ScrollController();
  bool _isFabVisible = true;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await dbHelper.addDefaultCategories();
    await dbHelper.addDefaultAccounts();
    final visibleAccounts = await _loadVisibleAccounts();
    final visibleCategories = await _loadVisibleCategories();
    final transactions = await dbHelper.getAllTransactions();
    setState(() {
      _accounts = visibleAccounts;
      _categories = visibleCategories;
      _registeredTransactions = transactions;
      _isLoading = false;
    });
  }

  Future<List<Account>> _loadVisibleAccounts() async {
    try {
      return await dbHelper.getAllAccounts(includeHidden: false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load accounts: $e';
        _isLoading = false;
      });
      return [];
    }
  }

  Future<List<Category>> _loadVisibleCategories() async {
    final allCategories = await dbHelper.getAllCategories();
    return allCategories.where((category) => category.isVisible).toList();
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  void _onScroll() {
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

  void _openAddTransactionModal() {
    final height = MediaQuery.of(context).size.height;
    showModalBottomSheet(
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: height < 600,
      scrollControlDisabledMaxHeightRatio: 0.85,
      context: context,
      builder: (ctx) => AddTransactionModal(
        categories: _categories,
        accounts: _accounts,
        onAddTransaction: _addTransaction,
      ),
    );
  }

  Future<int> _addTransaction(FinancialTransaction transaction) async {
    final result = await dbHelper.insertTransaction(transaction);
    if (result == 402) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          actions: [
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
          ],
          title: const Text("Balance not enough"),
          content: const Text(
              "Not enough balance on the selected account to complete transaction"),
        ),
      );
      return 0;
    } else {
      final updatedAccount = transaction.account;
      // If it's an expense, deduct; if income, add
      if (transaction.type == FinancialTransactionType.expense) {
        updatedAccount.deductExpense(transaction.amount);
      } else {
        updatedAccount.addIncome(transaction.amount);
      }
      await dbHelper.updateAccount(updatedAccount);
      await _refreshData();
      return 1;
    }
  }

  void _removeTransaction(FinancialTransaction transaction) async {
    final index = _registeredTransactions.indexOf(transaction);
    final updatedAccount = transaction.account;
    await dbHelper.deleteTransaction(transaction.id);

    // If we removed an expense, add back income. If we removed income, deduct
    if (transaction.type == FinancialTransactionType.expense) {
      updatedAccount.addIncome(transaction.amount);
    } else {
      updatedAccount.deductExpense(transaction.amount);
    }

    await dbHelper.updateAccount(updatedAccount);
    await _refreshData();
    setState(() {
      _registeredTransactions.removeAt(index);
    });
    _showSnackBar(transaction, updatedAccount, index);
  }

  void _showSnackBar(
      FinancialTransaction transaction, Account updatedAccount, int index) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("Transaction deleted."),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: "Undo",
          onPressed: () async {
            await dbHelper.insertTransaction(transaction);
            // Revert the account balance
            if (transaction.type == FinancialTransactionType.expense) {
              updatedAccount.deductExpense(transaction.amount);
            } else {
              updatedAccount.addIncome(transaction.amount);
            }
            await dbHelper.updateAccount(updatedAccount);
            await _refreshData();
            setState(() {
              _registeredTransactions.insert(index, transaction);
            });
          },
        ),
      ),
    );
  }

  void _openAddAccountModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => AddAccountModal(
        onAccountAdded: () async {
          await _loadVisibleAccounts();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isAddAccountEnabled = _accounts.length < 10;
    return Scaffold(
      floatingActionButton:
          _isFabVisible ? AddButton(onPress: _openAddTransactionModal) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
              );
              await _refreshData();
            },
            icon: const Icon(Icons.settings),
          )
        ],
        title: const Text("Expense Tracker"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Column(
                  children: [
                    SizedBox(
                      height: 100.0,
                      child: AccountPreview(
                        accounts: _accounts,
                        onAccountUpdated: _refreshData,
                        onAddAccount: _openAddAccountModal,
                        isAddAccountEnabled: isAddAccountEnabled,
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: NestedScrollView(
                        controller: _scrollController,
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverOverlapAbsorber(
                              handle: NestedScrollView
                                  .sliverOverlapAbsorberHandleFor(context),
                              sliver: SliverAppBar(
                                expandedHeight: 200,
                                floating: false,
                                pinned: false,
                                snap: false,
                                backgroundColor: Colors.transparent,
                                flexibleSpace: FlexibleSpaceBar(
                                  background: ExpandedChart(
                                    transactions: _registeredTransactions,
                                    categories: _categories,
                                  ),
                                ),
                              ),
                            ),
                          ];
                        },
                        body: Builder(
                          builder: (context) {
                            return CustomScrollView(
                              slivers: [
                                SliverOverlapInjector(
                                  handle: NestedScrollView
                                      .sliverOverlapAbsorberHandleFor(context),
                                ),
                                TransactionsList(
                                  transactions: _registeredTransactions,
                                  onRemoveTransaction: _removeTransaction,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
