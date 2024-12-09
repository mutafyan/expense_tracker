import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction/financial_transaction.dart';
import 'package:expense_tracker/models/transaction/financial_transaction_type.dart';
import 'package:expense_tracker/models/category/category.dart';

class AddIncomeModal extends StatefulWidget {
  final Account account;
  final VoidCallback onIncomeAdded;

  const AddIncomeModal({
    super.key,
    required this.account,
    required this.onIncomeAdded,
  });

  @override
  State<AddIncomeModal> createState() => _AddIncomeModalState();
}

class _AddIncomeModalState extends State<AddIncomeModal> {
  final _formKey = GlobalKey<FormState>();
  int _incomeAmount = 0;
  final dbHelper = DatabaseHelper.instance;

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
      category: uncategorizedCategory,
      account: widget.account,
      type: FinancialTransactionType.income,
    );
    await dbHelper.insertTransaction(incomeTransaction);

    widget.onIncomeAdded();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
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
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Income Amount',
                    prefix: Text("֏ "),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (int.tryParse(value.trim()) == null ||
                        int.parse(value.trim()) <= 0) {
                      return 'Please enter a valid positive number';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _incomeAmount = int.parse(value!.trim());
                  },
                ),
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
