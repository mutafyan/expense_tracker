import 'package:expense_tracker/models/currency/currency.dart';
import 'package:expense_tracker/provider/currency_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CurrencySelectModal extends ConsumerStatefulWidget {
  const CurrencySelectModal({super.key});

  @override
  ConsumerState<CurrencySelectModal> createState() =>
      _CurrencySelectModalState();
}

class _CurrencySelectModalState extends ConsumerState<CurrencySelectModal> {
  Currency? selectedCurrency;

  @override
  void initState() {
    super.initState();
    final currentCurrency = ref.read(currencyProvider);
    selectedCurrency = currentCurrency;
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
                child: Text(
                  'Change Currency',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium!
                      .copyWith(fontSize: 18),
                ),
              ),
              const SizedBox(height: 40),
              DropdownButtonFormField<String>(
                value: selectedCurrency?.displaySymbol,
                hint: const Text('Choose a currency'),
                items: currencies.entries
                    .map((entry) => DropdownMenuItem<String>(
                          value: entry.value.displaySymbol,
                          child: Text(
                              "${entry.value.displayName} (${entry.value.displaySymbol})"),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCurrency = currencies.entries
                        .firstWhere(
                            (entry) => entry.value.displaySymbol == value)
                        .value;
                  });
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
              const SizedBox(height: 50),
              ElevatedButton(
                onPressed: () async {
                  if (selectedCurrency != null) {
                    try {
                      await ref
                          .read(currencyProvider.notifier)
                          .changeCurrency(selectedCurrency!);

                      ScaffoldMessenger.of(context).clearSnackBars();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Currency set to ${selectedCurrency!.displayName}"),
                        ),
                      );

                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  }
                },
                child: const Center(child: Text('Save')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
