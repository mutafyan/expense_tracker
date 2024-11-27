import 'package:expense_tracker/data/db_helper.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/models/account/account.dart';

class AddIncomeModal extends StatefulWidget {
  const AddIncomeModal({
    super.key,
    required this.account,
    required this.onIncomeAdded,
  });

  final Account account;
  final VoidCallback onIncomeAdded;

  @override
  State<StatefulWidget> createState() => _AddIncomeModalState();
}

class _AddIncomeModalState extends State<AddIncomeModal> {
  final _amountController = TextEditingController();
  String? _amountError;
  final dbHelper = DatabaseHelper.instance;

  void _saveIncome() async {
    int? amount = int.tryParse(_amountController.text);
    if (amount != null && amount > 0) {
      widget.account.addIncome(amount);
      await dbHelper.updateAccount(widget.account);
      widget.onIncomeAdded();
      if (mounted) Navigator.pop(context);
    } else {
      setState(() {
        _amountError = "Please enter a valid positive amount.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, keyboardHeight + 10),
      child: Row(
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
          const SizedBox(width: 6),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          const SizedBox(width: 6),
          ElevatedButton(
            onPressed: _saveIncome,
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }
}
