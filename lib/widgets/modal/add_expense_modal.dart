// lib/widgets/modal/add_expense_modal.dart
import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/expense/expense.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:flutter/material.dart';

class AddExpenseModal extends StatefulWidget {
  final void Function(Expense) onAddExpense;

  const AddExpenseModal({super.key, required this.onAddExpense});

  @override
  State<AddExpenseModal> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _formKey = GlobalKey<FormState>();
  String _title = '';
  int _amount = 0;
  DateTime _selectedDate = DateTime.now();
  Category? _selectedCategory;
  Account? _selectedAccount;

  final dbHelper = DatabaseHelper.instance;

  List<Category> _categories = [];
  List<Account> _accounts = [];

  @override
  void initState() {
    super.initState();
    _loadCategoriesAndAccounts();
  }

  Future<void> _loadCategoriesAndAccounts() async {
    final categories = await dbHelper.getAllCategories();
    final accounts = await dbHelper.getAllAccounts();

    setState(() {
      _categories = categories;
      _accounts = accounts;
      if (_categories.isNotEmpty) {
        _selectedCategory = _categories.first;
      }
      if (_accounts.isNotEmpty) {
        _selectedAccount = _accounts.first;
      }
    });
  }

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

    final newExpense = Expense(
      title: _title,
      amount: _amount,
      date: _selectedDate,
      category: _selectedCategory!,
      account: _selectedAccount!,
    );

    widget.onAddExpense(newExpense);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("\"${newExpense.title}\" added successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            children: [
              const Center(
                child: Text(
                  'Add New Expense',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Expense Title
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Expense Title'),
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
                    // Expense Amount
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Amount'),
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
                        _amount = int.parse(value!.trim());
                      },
                    ),
                    const SizedBox(height: 16),
                    // Date Picker
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Date: ${_selectedDate.toLocal()}'.split(' ')[0],
                          ),
                        ),
                        TextButton(
                          onPressed: _presentDatePicker,
                          child: const Text('Choose Date'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Category Dropdown
                    DropdownButtonFormField<Category>(
                      decoration: const InputDecoration(labelText: 'Category'),
                      value: _selectedCategory,
                      items: _categories.map((Category category) {
                        return DropdownMenuItem<Category>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                IconData(
                                  category.iconCodePoint,
                                  fontFamily: 'MaterialIcons',
                                ),
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
                      onSaved: (value) {
                        _selectedCategory = value;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Account Dropdown
                    DropdownButtonFormField<Account>(
                      decoration: const InputDecoration(labelText: 'Account'),
                      value: _selectedAccount,
                      items: _accounts.map((Account account) {
                        return DropdownMenuItem<Account>(
                          value: account,
                          child: Row(
                            children: [
                              Icon(
                                IconData(
                                  account.iconData.codePoint,
                                  fontFamily: 'MaterialIcons',
                                ),
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
                      onSaved: (value) {
                        _selectedAccount = value;
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Add Expense'),
                    )
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
