import 'package:flutter/material.dart';

class Account {
  Account({required this.name, this.balance = 0}) {
    if (name.toLowerCase() == "cash") {
      icon = const Icon(Icons.account_balance_wallet_rounded);
    } else if (name.toLowerCase() == "card") {
      icon = const Icon(Icons.wallet);
    } else {
      icon = const Icon(Icons.account_balance_rounded);
    }
  }
  final String name;
  late Icon icon;
  int balance;

  String get getName => name[0].toUpperCase() + name.substring(1);
  int get getBalance => balance;
  void addIncome(int income) {
    balance += income;
  }
}
