import 'package:expense_tracker/models/currency/currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final Map<String, Currency> currencies = {
  'AMD': Currency('֏', 'Armenian Dram'),
  'USD': Currency('\$', 'US Dollar'),
  'EUR': Currency('€', 'Euro'),
  'RUB': Currency('₽', 'Russian Ruble'),
};

class CurrencyNotifier extends StateNotifier<Currency> {
  CurrencyNotifier() : super(currencies['AMD']!);

  void changeCurrency(Currency newCurrency) {
    state = newCurrency;
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>(
    (ref) => CurrencyNotifier());
