import 'package:expense_tracker/widgets/expense_manager/amount_input.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/models/transaction/financial_transaction.dart';
import 'package:expense_tracker/models/transaction/financial_transaction_type.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/category/category.dart';

class AddTransactionModal extends StatefulWidget {
  final List<Category> categories;
  final List<Account> accounts;
  final Future<int> Function(FinancialTransaction) onAddTransaction;

  const AddTransactionModal({
    super.key,
    required this.categories,
    required this.accounts,
    required this.onAddTransaction,
  });

  @override
  State<AddTransactionModal> createState() => _AddTransactionModalState();
}

class _AddTransactionModalState extends State<AddTransactionModal> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  int _enteredAmount = 0;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  Account? _selectedAccount;

  void _presentDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate() ||
        _selectedCategory == null ||
        _selectedAccount == null) {
      return;
    }
    _formKey.currentState!.save();

    final newTransaction = FinancialTransaction(
      title: _title,
      amount: _enteredAmount,
      date: _selectedDate,
      category: _selectedCategory!,
      account: _selectedAccount!,
      type: FinancialTransactionType.expense,
    );

    int result = await widget.onAddTransaction(newTransaction);
    if (result == 0) return; // balance not enough, display alert

    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("\"${newTransaction.title}\" added successfully!")),
    );
  }

  void _onAmountEntered(int newAmount) {
    _enteredAmount = newAmount;
  }

  @override
  void initState() {
    super.initState();
    if (widget.categories.isNotEmpty) {
      _selectedCategory = widget.categories.first;
    }
    if (widget.accounts.isNotEmpty) {
      _selectedAccount = widget.accounts.first;
    }
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
              'Add Expense',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Title'),
                  style: TextStyle(
                      color:
                          Theme.of(context).colorScheme.onSecondaryContainer),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a title';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    _title = value!.trim();
                  },
                ),
                const SizedBox(height: 16),
                AmountInput(
                  onAmountEntered: _onAmountEntered,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                          'Date: ${_selectedDate.toLocal()}'.split(' ')[0]),
                    ),
                    TextButton(
                      onPressed: _presentDatePicker,
                      child: const Text('Choose Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Category>(
                  decoration: const InputDecoration(labelText: 'Category'),
                  value: _selectedCategory,
                  items: widget.categories.map((Category category) {
                    return DropdownMenuItem<Category>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            IconData(category.iconCodePoint,
                                fontFamily: 'MaterialIcons'),
                          ),
                          const SizedBox(width: 8),
                          Text(category.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (Category? newValue) {
                    setState(() {
                      _selectedCategory = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Account>(
                  decoration: const InputDecoration(labelText: 'Account'),
                  value: _selectedAccount,
                  items: widget.accounts.map((Account account) {
                    return DropdownMenuItem<Account>(
                      value: account,
                      child: Row(
                        children: [
                          Icon(
                            IconData(account.iconData.codePoint,
                                fontFamily: 'MaterialIcons'),
                          ),
                          const SizedBox(width: 8),
                          Text(account.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (Account? newValue) {
                    setState(() {
                      _selectedAccount = newValue;
                    });
                  },
                  validator: (value) {
                    if (value == null) {
                      return 'Please select an account';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Save Expense'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
