import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/widgets/modal/account_picker.dart';
import 'package:expense_tracker/widgets/modal/category_picker.dart';
import 'package:flutter/material.dart';

class AddExpenseModal extends StatefulWidget {
  const AddExpenseModal({super.key, required this.onAddExpense});
  final void Function(Expense expense) onAddExpense;

  @override
  State<StatefulWidget> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final dbHelper = DatabaseHelper.instance;
  String? _titleError, _amountError;
  DateTime? _pickedDate;
  Category? _selectedCategory;
  Account? _selectedAccount;
  List<Account> availableAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  void _goBack() {
    Navigator.pop(context);
  }

  Future<void> _loadAccounts() async {
    final accounts = await dbHelper.getAllAccounts();
    setState(() {
      availableAccounts = accounts;
      if (availableAccounts.isNotEmpty) {
        _selectedAccount = availableAccounts[0];
      }
    });
  }

  void _saveNewExpense(String title, int amount) {
    final newExpense = Expense(
      title: title,
      amount: amount,
      date: _pickedDate!,
      category: _selectedCategory!,
      account: _selectedAccount!,
    );

    widget.onAddExpense(newExpense);
    _goBack();
  }

  void _validateInput() {
    int? amount = int.tryParse(_amountController.text);
    String title = _titleController.text;

    if (!(_validateTitle(title) &&
        _validateAmount(amount) &&
        _validateCategoryAndDate() &&
        _validateAccount())) return;

    _saveNewExpense(title, amount!);
  }

  bool _validateCategoryAndDate() {
    if (_selectedCategory == null || _pickedDate == null) {
      _showErrorDialog("Invalid input", "Please select a date and category.");
      return false;
    }
    return true;
  }

  bool _validateAccount() {
    if (_selectedAccount == null) {
      _showErrorDialog("No account selected", "Please select an account.");
      return false;
    }
    return true;
  }

  bool _validateAmount(int? amount) {
    if (amount == null || amount <= 0) {
      setState(() {
        _amountError = "Please enter a valid positive amount.";
      });
      return false;
    } else {
      setState(() {
        _amountError = null;
      });
      return true;
    }
  }

  bool _validateTitle(String title) {
    if (title.trim().isEmpty) {
      setState(() {
        _titleError = "Title cannot be empty.";
      });
      return false;
    } else {
      setState(() {
        _titleError = null;
      });
      return true;
    }
  }

  void _openDatePicker() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 1, now.month, now.day);
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: firstDate,
      lastDate: now,
    );
    setState(() {
      _pickedDate = pickedDate;
    });
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Okay"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _onCategorySelect(value) {
    if (value != null) {
      setState(() {
        _selectedCategory = value;
      });
    }
  }

  void _onAccountSelect(value) {
    if (value != null) {
      setState(() {
        _selectedAccount = value;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardSize = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, keyboardSize + 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimaryContainer),
            maxLength: 50,
            decoration: InputDecoration(
              label: const Text("Enter Title"),
              errorText: _titleError,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  controller: _amountController,
                  maxLength: 7,
                  decoration: InputDecoration(
                    prefixText: '֏ ',
                    label: const Text("Enter Amount"),
                    errorText: _amountError,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: _openDatePicker,
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: "Select Date",
                      border: OutlineInputBorder(),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _pickedDate == null
                              ? "No date chosen"
                              : formatter.format(_pickedDate!),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.calendar_today),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CategoryPicker(
                  selectedCategory: _selectedCategory,
                  onChange: _onCategorySelect,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: AccountPicker(
                  selectedAccount: _selectedAccount,
                  availableAccounts: availableAccounts,
                  onChange: _onAccountSelect,
                ),
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              const Spacer(),
              TextButton(onPressed: _goBack, child: const Text("Cancel")),
              ElevatedButton(
                  onPressed: _validateInput, child: const Text("Save"))
            ],
          ),
        ],
      ),
    );
  }
}
