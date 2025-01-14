import 'package:expense_tracker/provider/currency_provider.dart';
import 'package:expense_tracker/widgets/transactions_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

var kColorScheme =
    ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 114, 238, 145));

var kDarkColorScheme = ColorScheme.fromSeed(
  brightness: Brightness.dark,
  seedColor: const Color.fromARGB(255, 110, 240, 143),
);
void main() async {
  // Load the saved currency before running the app
  WidgetsFlutterBinding.ensureInitialized();
  final currencyNotifier = CurrencyNotifier();
  await currencyNotifier.loadCurrency();

  runApp(
    ProviderScope(
      overrides: [
        currencyProvider.overrideWith((ref) => currencyNotifier),
      ],
      child: MaterialApp(
        darkTheme: ThemeData.dark().copyWith(
          colorScheme: kDarkColorScheme,
          cardTheme: const CardTheme().copyWith(
            color: kDarkColorScheme.surfaceContainer,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: kDarkColorScheme.primaryContainer,
              foregroundColor: kDarkColorScheme.onPrimaryContainer,
            ),
          ),
          textTheme: ThemeData().textTheme.copyWith(
              titleLarge: const TextStyle(
                fontWeight: FontWeight.w700,
              ),
              titleMedium: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: kDarkColorScheme.onSecondaryContainer,
              ),
              bodyMedium: TextStyle(
                color: kDarkColorScheme.onSecondaryContainer,
              )),
        ),
        debugShowCheckedModeBanner: false,
        theme: ThemeData().copyWith(
          colorScheme: kColorScheme,
          appBarTheme: const AppBarTheme().copyWith(
            backgroundColor: kColorScheme.primaryFixed,
            foregroundColor: kColorScheme.onPrimaryContainer,
          ),
          cardTheme: const CardTheme().copyWith(
            color: kColorScheme.surfaceContainer,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                backgroundColor: kColorScheme.primaryContainer),
          ),
          textTheme: ThemeData().textTheme.copyWith(
                titleLarge: const TextStyle(
                  fontWeight: FontWeight.w700,
                ),
                titleMedium: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: kColorScheme.onSecondaryContainer,
                ),
              ),
        ),
        home: const TransactionsScreen(),
      ),
    ),
  );
}
