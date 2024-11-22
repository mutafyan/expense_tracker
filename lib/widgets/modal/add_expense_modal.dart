import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:expense_tracker/widgets/modal/dropdown_item.dart';
import 'package:flutter/material.dart';

List<Account> accounts = [Account(name: "cash"), Account(name: "card")];

class AddExpenseModal extends StatefulWidget {
  const AddExpenseModal({super.key, required this.onAddExpense});
  final void Function(Expense expense) onAddExpense;
  @override
  State<StatefulWidget> createState() => _AddExpenseModalState();
}

class _AddExpenseModalState extends State<AddExpenseModal> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String? _titleError, _amountError;
  DateTime? _pickedDate;
  Category? _selectedCategory;
  Account? _selectedAccount;
  void _goBack() {
    Navigator.pop(context);
  }

  void _saveNewExpense(String title, int amount) {
    widget.onAddExpense(
      Expense(
          title: title,
          amount: amount,
          date: _pickedDate!,
          category: _selectedCategory!,
          account: _selectedAccount!),
    );
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
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Invalid input"),
          content: const Text("Please re-check entered date and category"),
          actions: [
            ElevatedButton(
              onPressed: _goBack,
              child: const Text("Okay"),
            )
          ],
        ),
      );
      return false;
    } else {
      return true;
    }
  }

  bool _validateAccount() {
    if (_selectedAccount == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("No account selected"),
          content: const Text("Please retry"),
          actions: [
            ElevatedButton(
              onPressed: _goBack,
              child: const Text("Okay"),
            )
          ],
        ),
      );
      return false;
    }
    return true;
  }

  bool _validateAmount(int? amount) {
    if (amount == null || amount <= 0) {
      setState(() {
        _amountError = "Invalid amount";
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
        _titleError = "Invalid title";
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          TextField(
            controller: _titleController,
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            maxLength: 50,
            decoration: InputDecoration(
              label: const Text("Enter Title"),
              errorText: _titleError,
            ),
          ),
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
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(_pickedDate == null
                        ? "Select a date"
                        : formatter.format(_pickedDate!)),
                    IconButton(
                        onPressed: _openDatePicker,
                        icon: const Icon(Icons.calendar_month)),
                  ],
                ),
              )
            ],
          ),
          const SizedBox(
            height: 10,
          ),
          Row(
            children: [
              DropdownItem(
                  selectedCategory: _selectedCategory,
                  onChange: _onCategorySelect),
              DropdownButton(
                  hint: const Text("Account"),
                  items: accounts
                      .map(
                        (account) => DropdownMenuItem(
                          value: account,
                          child: Expanded(
                            child: Column(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      account.icon,
                                      Text(account.getName),
                                    ],
                                  ),
                                ),
                                Text(
                                  "֏ ${account.getBalance.toString()}",
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedAccount = value;
                      });
                    }
                  }),
            ],
          ),
          const Spacer(),
          TextButton(onPressed: _goBack, child: const Text("Cancel")),
          ElevatedButton(onPressed: _validateInput, child: const Text("Save"))
        ],
      ),
    );
  }
}
