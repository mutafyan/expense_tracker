import 'package:flutter/material.dart';

class AmountInput extends StatelessWidget {
  const AmountInput({super.key, required this.onAmountEntered});
  final Function(int) onAmountEntered;
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      decoration:
          const InputDecoration(labelText: 'Amount', prefix: Text("֏ ")),
      keyboardType: TextInputType.number,
      style:
          TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
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
        int amount = int.parse(value!.trim());
        onAmountEntered(amount);
      },
    );
  }
}
