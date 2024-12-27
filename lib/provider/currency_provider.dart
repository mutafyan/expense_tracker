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

  // Load the selected currency from the database when the app starts
  Future<void> loadCurrency() async {
    final dbHelper = DatabaseHelper.instance;
    final savedCurrency = await dbHelper.getSelectedCurrency();
    state = savedCurrency;
  }

  // Change the current currency and save it to the database
  Future<void> changeCurrency(Currency newCurrency) async {
    if (newCurrency == state) return;

    try {
      final service = CurrencyService();
      final rates = await service.fetchCurrencyRates();
      final oldCurrencyRate =
          rates[state.displayISO] ?? 1.0; // Default AMD = 1.0
      final newCurrencyRate = rates[newCurrency.displayISO] ?? 1.0;

      // Calculate relative exchange rate
      final relativeRate = oldCurrencyRate / newCurrencyRate;

      // Update all accounts' balances
      await _updateAccountBalances(relativeRate);

      // Save the new currency to the database
      await _saveCurrencyToDb(newCurrency);

      // Update the state to the new currency
      state = newCurrency;
    } catch (e) {
      throw Exception('Error changing currency: $e');
    }
  }

  // Helper method to update all account balances based on the exchange rate
  Future<void> _updateAccountBalances(double relativeRate) async {
    final dbHelper = DatabaseHelper.instance;
    final accounts = await dbHelper.getAllAccounts();

    for (var account in accounts) {
      account.balance = account.balance * relativeRate;
      await dbHelper.updateAccount(account);
    }
  }

  // Save the selected currency to the database
  Future<void> _saveCurrencyToDb(Currency currency) async {
    final dbHelper = DatabaseHelper.instance;
    await dbHelper.saveSelectedCurrency(currency);
  }
}

// Riverpod provider for CurrencyNotifier
final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>(
    (ref) => CurrencyNotifier());
