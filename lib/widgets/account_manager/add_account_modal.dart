// widgets/account_manager/add_account_modal.dart
import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:flutter/material.dart';

class AddAccountModal extends StatefulWidget {
  final VoidCallback onAccountAdded;

  const AddAccountModal({super.key, required this.onAccountAdded});

  @override
  State<AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends State<AddAccountModal> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  IconData _selectedIcon = Icons.account_balance_rounded;
  final dbHelper = DatabaseHelper.instance;

  // Define a list of icons for selection
  final List<IconData> _availableIcons = [
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.money,
    Icons.savings,
    Icons.paid,
    Icons.attach_money,
    Icons.account_balance,
    Icons.account_balance_wallet_outlined,
    Icons.money_off,
    Icons.payment,
    // Add more icons as needed
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final newAccount = Account(
      name: _name,
      balance: 0,
      isDefault: false,
      isVisible: true,
      iconData: _selectedIcon,
    );

    await dbHelper.insertAccount(newAccount);
    widget.onAccountAdded();
    Navigator.pop(context);
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
                  'Add New Account',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Account Name
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Account Name'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter an account name';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _name = value!.trim();
                      },
                    ),
                    const SizedBox(height: 16),
                    // Icon Selection
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Select Icon',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _availableIcons.map((iconData) {
                        return ChoiceChip(
                          label: Icon(iconData),
                          selected: _selectedIcon == iconData,
                          onSelected: (selected) {
                            setState(() {
                              _selectedIcon = iconData;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Add Account'),
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
