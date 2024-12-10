import 'package:expense_tracker/data/db_helper.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:flutter/material.dart';

class AddAccountModal extends StatefulWidget {
  final VoidCallback onAccountAdded;

  const AddAccountModal({required this.onAccountAdded, super.key});

  @override
  State<AddAccountModal> createState() => _AddAccountModalState();
}

class _AddAccountModalState extends State<AddAccountModal> {
  final _formKey = GlobalKey<FormState>();
  String _accountName = '';
  IconData _selectedIcon = Icons.account_balance_wallet;
  bool _isSubmitting = false;
  String? _error;
  final dbHelper = DatabaseHelper.instance;

  final List<IconData> _availableIcons = [
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.money,
    Icons.account_balance,
    Icons.savings,
    Icons.wallet,
    Icons.attach_money,
    Icons.paypal_outlined,
    Icons.currency_ruble,
    Icons.currency_bitcoin
  ];

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    final newAccount = Account(
      name: _accountName,
      balance: 0,
      isDefault: false,
      isVisible: true,
      iconData: _selectedIcon,
    );

    try {
      await dbHelper.insertAccount(newAccount);
      widget.onAccountAdded();
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isSubmitting = false;
      });
    }
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
              Center(
                  child: Text('Add New Account',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium!
                          .copyWith(fontSize: 18))),
              const SizedBox(height: 40),
              if (_error != null)
                Center(
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 16),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Account Name',
                        border: OutlineInputBorder(),
                      ),
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSecondaryContainer),
                      validator: (value) {
                        if (value == null ||
                            value.trim().isEmpty ||
                            value.trim().length < 2) {
                          return 'Please enter a valid account name (min 2 characters).';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        _accountName = value!.trim();
                      },
                    ),
                    const SizedBox(height: 16),
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
                      onPressed: _isSubmitting ? null : _submit,
                      child: _isSubmitting
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text('Add Account'),
                    ),
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
