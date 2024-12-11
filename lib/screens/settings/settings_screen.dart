import 'package:expense_tracker/screens/settings/details/account_settings_screen.dart';
import 'package:expense_tracker/screens/settings/details/category_settings_screen.dart';
import 'package:expense_tracker/screens/settings/details/currency_select_modal.dart';
import 'package:expense_tracker/screens/settings/settings_item.dart';
import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
      ),
      body: ListView(
        children: [
          SettingsItem(
            settingName: "Accounts",
            subtitle: "Add and remove accounts",
            icon: Icons.account_balance_outlined,
            onPress: _openAccountSettings,
          ),
          SettingsItem(
            settingName: "Categories",
            subtitle: "Manage Categories",
            icon: Icons.category_outlined,
            onPress: _openCategorySettings,
          ),
          SettingsItem(
            settingName: "Currency",
            subtitle: "Change selected currency",
            icon: Icons.currency_exchange,
            onPress: _openCurrencyModal,
          ),
          // Add more SettingsItem widgets as needed
        ],
      ),
    );
  }

  void _openAccountSettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const AccountSettingsScreen()),
    );
  }

  void _openCategorySettings(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (ctx) => const CategorySettingsScreen()),
    );
  }

  void _openCurrencyModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CurrencySelectModal(),
    );
  }
}
