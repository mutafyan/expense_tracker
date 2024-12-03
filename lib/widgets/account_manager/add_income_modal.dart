import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:flutter/material.dart';

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

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    widget.account.addIncome(_incomeAmount);
    await dbHelper.updateAccount(widget.account);
    widget.onIncomeAdded();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Wrap(
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
                  // Income Amount
                  TextFormField(
                    decoration: const InputDecoration(
                        labelText: 'Income Amount', prefix: Text("֏ ")),
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
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
