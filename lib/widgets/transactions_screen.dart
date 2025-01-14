import 'package:expense_tracker/models/transaction/financial_transaction_type.dart';
import 'package:expense_tracker/screens/settings/settings_screen.dart';
import 'package:expense_tracker/widgets/account_manager/account_preview.dart';
import 'package:expense_tracker/widgets/account_manager/add_account_modal.dart';
import 'package:expense_tracker/widgets/chart/expanded_chart.dart';
import 'package:expense_tracker/widgets/expense_manager/add_button.dart';
import 'package:expense_tracker/widgets/expense_manager/add_transaction_modal.dart';
import 'package:expense_tracker/widgets/transactions_list/transactions_list.dart';
import 'package:expense_tracker/models/transaction/financial_transaction.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/data/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:expense_tracker/models/category/category.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen>
    with SingleTickerProviderStateMixin {
  final dbHelper = DatabaseHelper.instance;
  List<FinancialTransaction> _registeredTransactions = [];
  List<Account> _accounts = [];
  List<Category> _categories = [];
  final _scrollController = ScrollController();
  bool _isFabVisible = true;
  bool _isLoading = true;
  String? _error;
  bool _isDropdownVisible = false;
  String _selectedCategory = "All Transactions";

  // Animation controller for sliding dropdown
  late AnimationController _animationController;
  late Animation<double> _dropdownAnimation;

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);

    // Initialize animation
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _dropdownAnimation =
        Tween<double>(begin: -200.0, end: 0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final visibleAccounts = await _loadVisibleAccounts();
    final visibleCategories = await _loadVisibleCategories();

    List<FinancialTransaction> transactions;
    if (_selectedCategory == "All Transactions") {
      transactions = await dbHelper.getAllTransactions();
    } else if (_selectedCategory == "Incomes") {
      transactions = await dbHelper.getAllIncomes();
    } else {
      transactions = await dbHelper.getAllExpenses();
    }

    setState(() {
      _accounts = visibleAccounts;
      _categories = visibleCategories;
      _registeredTransactions = transactions;
      _isLoading = false;
    });
  }

  Future<List<Account>> _loadVisibleAccounts() async {
    try {
      List<Account> newAccounts =
          await dbHelper.getAllAccounts(includeHidden: false);
      setState(() {
        _accounts = newAccounts;
      });
      return _accounts;
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

  Future<void> _refreshAccounts() async {
    final updatedAccounts = await _loadVisibleAccounts();
    setState(() {
      _accounts = updatedAccounts;
    });
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

    // Temporarily remove the transaction from the list for UI update
    setState(() {
      _registeredTransactions.removeAt(index);
    });

    await dbHelper.deleteTransaction(transaction.id);

    if (transaction.type == FinancialTransactionType.expense) {
      updatedAccount.addIncome(transaction.amount);
    } else {
      updatedAccount.deductExpense(transaction.amount);
    }
    await dbHelper.updateAccount(updatedAccount);

    // Refresh accounts to update balances in the UI
    await _refreshAccounts();

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
            // Check if the transaction already exists to prevent duplication
            if (!_registeredTransactions.contains(transaction)) {
              await dbHelper.insertTransaction(transaction);

              // Adjust the account balance accordingly
              if (transaction.type == FinancialTransactionType.expense) {
                updatedAccount.deductExpense(transaction.amount);
              } else {
                updatedAccount.addIncome(transaction.amount);
              }

              await dbHelper.updateAccount(updatedAccount);

              // Refresh accounts and transactions
              await _refreshAccounts();
              await _refreshData();

              setState(() {
                _registeredTransactions.insert(index, transaction);
              });
            }
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

  List<String> _getOptions() {
    const allCategories = ["All Transactions", "Incomes", "Expenses"];
    return allCategories
        .where((category) => category != _selectedCategory)
        .toList();
  }

  void _toggleDropdown() {
    setState(() {
      _isDropdownVisible = !_isDropdownVisible;
      if (_isDropdownVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  Future<void> _selectCategory(String category) async {
    setState(() {
      _selectedCategory = category;
      _isDropdownVisible = false;
      _animationController.reverse();
    });

    // Reload only transactions
    List<FinancialTransaction> updatedTransactions;
    if (category == "All Transactions") {
      updatedTransactions = await dbHelper.getAllTransactions();
    } else if (category == "Incomes") {
      updatedTransactions = await dbHelper.getAllIncomes();
    } else {
      updatedTransactions = await dbHelper.getAllExpenses();
    }

    setState(() {
      _registeredTransactions = updatedTransactions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:
          _isFabVisible ? AddButton(onPress: _openAddTransactionModal) : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      appBar: AppBar(
        title: GestureDetector(
          onTap: _toggleDropdown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _selectedCategory,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer),
              ),
              AnimatedRotation(
                turns: _isDropdownVisible ? 0.5 : 1.0, // Rotate 180 degrees
                duration: const Duration(milliseconds: 200),
                child: const Icon(Icons.keyboard_arrow_down_rounded),
              ),
            ],
          ),
        ),
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
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 100.0,
                          child: AccountPreview(
                            accounts: _accounts,
                            onAccountUpdated: _refreshData,
                            onAddAccount: _openAddAccountModal,
                            isAddAccountEnabled: _accounts.length < 10,
                          ),
                        ),
                        const Divider(height: 1),
                        _registeredTransactions.isEmpty
                            ? const Expanded(
                                child: Center(
                                  child: Text(
                                    "No registered transactions, create a new one!",
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              )
                            : Expanded(
                                child: NestedScrollView(
                                  controller: _scrollController,
                                  headerSliverBuilder:
                                      (context, innerBoxIsScrolled) {
                                    return [
                                      SliverOverlapAbsorber(
                                        handle: NestedScrollView
                                            .sliverOverlapAbsorberHandleFor(
                                                context),
                                        sliver: SliverAppBar(
                                          expandedHeight: 200,
                                          floating: false,
                                          pinned: false,
                                          snap: false,
                                          backgroundColor: Colors.transparent,
                                          flexibleSpace: FlexibleSpaceBar(
                                            background: ExpandedChart(
                                              transactions:
                                                  _registeredTransactions,
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
                                                .sliverOverlapAbsorberHandleFor(
                                                    context),
                                          ),
                                          TransactionsList(
                                            transactions:
                                                _registeredTransactions,
                                            onRemoveTransaction:
                                                _removeTransaction,
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                              ),
                      ],
                    ),
                    AnimatedBuilder(
                      animation: _dropdownAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top: _dropdownAnimation.value,
                          left: 4.0,
                          child: Material(
                            elevation: 8,
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .secondaryContainer,
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _getOptions().map((option) {
                                  return GestureDetector(
                                    onTap: () => _selectCategory(option),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16.0,
                                        vertical: 8.0,
                                      ),
                                      child: Text(
                                        option,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
    );
  }
}
