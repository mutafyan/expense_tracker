import 'package:expense_tracker/provider/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AmountInput extends ConsumerWidget {
  const AmountInput({super.key, required this.onAmountEntered});
  final Function(double) onAmountEntered;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCurrency = ref.watch(currencyProvider);
    return TextFormField(
      decoration: InputDecoration(
          labelText: 'Amount',
          prefix: Text("${selectedCurrency.displaySymbol} ")),
      keyboardType: TextInputType.number,
      style:
          TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter an amount';
        }
        if (double.tryParse(value.trim()) == null ||
            double.parse(value.trim()) <= 0) {
          return 'Please enter a valid positive number';
        }
        return null;
      },
      onSaved: (value) {
        double amount = double.parse(value!.trim());
        onAmountEntered(amount);
      },
    );
  }
}
