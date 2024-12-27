import 'package:expense_tracker/models/currency/currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/db_helper.dart';
import '../services/currency_service.dart';

final Map<String, Currency> currencies = {
  'AMD': Currency('֏', 'Armenian Dram', 'AMD'),
  'USD': Currency('\$', 'US Dollar', 'USD'),
  'EUR': Currency('€', 'Euro', 'EUR'),
  'RUB': Currency('₽', 'Russian Ruble', 'RUB'),
};

final baseCurrency = currencies['AMD'];

class CurrencyNotifier extends StateNotifier<Currency> {
  CurrencyNotifier() : super(baseCurrency!);

  Future<void> changeCurrency(Currency newCurrency) async {
    if (newCurrency == state) return;

    try {
      final service = CurrencyService();
      final rates = await service.fetchCurrencyRates();
      print("Rates: $rates");
      final oldCurrencyRate = rates[state.displayISO] ??
          1.0; // Default AMD = 1.0 not included in rates
      final newCurrencyRate = rates[newCurrency.displayISO] ?? 1.0;

      // Calculate relative exchange rate
      final relativeRate = oldCurrencyRate / newCurrencyRate;
      print("Relative Rate: $relativeRate");
      // Update all accounts
      await _updateAccountBalances(relativeRate);

      // Update the state to the new currency
      state = newCurrency;
    } catch (e) {
      throw Exception('Error changing currency: $e');
    }
  }

  Future<void> _updateAccountBalances(double relativeRate) async {
    final dbHelper = DatabaseHelper.instance;
    final accounts = await dbHelper.getAllAccounts();

    for (var account in accounts) {
      // Update balance using relative rate
      print("Relative Rate: $relativeRate");

      account.balance = account.balance * relativeRate;
      await dbHelper.updateAccount(account);
      print("Account ${account.displayName}: ${account.balance}");
    }
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>(
    (ref) => CurrencyNotifier());
