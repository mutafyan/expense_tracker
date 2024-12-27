import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/currency/currency.dart';
import 'package:expense_tracker/provider/currency_provider.dart';
import 'package:expense_tracker/widgets/expense_manager/amount_input.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction/financial_transaction.dart';
import 'package:expense_tracker/models/transaction/financial_transaction_type.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddIncomeModal extends ConsumerStatefulWidget {
  final Account account;
  final VoidCallback onIncomeAdded;

  const AddIncomeModal({
    super.key,
    required this.account,
    required this.onIncomeAdded,
  });

  @override
  ConsumerState<AddIncomeModal> createState() => _AddIncomeModalState();
}

class _AddIncomeModalState extends ConsumerState<AddIncomeModal> {
  final _formKey = GlobalKey<FormState>();
  double _incomeAmount = 0;
  final dbHelper = DatabaseHelper.instance;
  Currency? _selectedCurrency;

  Future<Category> _getUncategorizedCategory() async {
    final categories = await dbHelper.getAllCategories();
    // Assuming 'Uncategorized' category always exists due to initial setup
    return categories.firstWhere(
      (c) => c.name == 'Uncategorized',
      orElse: () => Category(
        name: "Uncategorized",
        iconCodePoint: Icons.help_outline.codePoint,
        isDefault: true,
        isVisible: true,
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    // Update the account balance
    widget.account.addIncome(_incomeAmount);
    await dbHelper.updateAccount(widget.account);

    // Insert a transaction record for this income
    final uncategorizedCategory = await _getUncategorizedCategory();
    final incomeTransaction = FinancialTransaction(
      title: 'Income to ${widget.account.name}',
      amount: _incomeAmount,
      date: DateTime.now(),
      currency: _selectedCurrency!, // !!
      category: uncategorizedCategory,
      account: widget.account,
      type: FinancialTransactionType.income,
    );
    await dbHelper.insertTransaction(incomeTransaction);

    widget.onIncomeAdded();
    Navigator.pop(context);
  }

  void _onAmountEntered(double newAmount) {
    _incomeAmount = newAmount;
  }

  @override
  Widget build(BuildContext context) {
    _selectedCurrency = ref.watch(currencyProvider);
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 16,
        left: 16,
        right: 16,
      ),
      child: Column(
        children: [
          const Center(
            child: Text(
              'Add Income',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                AmountInput(onAmountEntered: _onAmountEntered),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Add Income'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
