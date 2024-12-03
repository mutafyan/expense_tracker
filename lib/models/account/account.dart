// models/account/account.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Account {
  Account({
    String? id,
    required this.name,
    this.balance = 0,
    this.isDefault = false,
    this.isVisible = true,
    IconData? iconData,
  })  : id = id ?? uuid.v4(),
        iconData = iconData ?? _getIconForAccount(name);

  String id;
  final String name;
  int balance;
  bool isDefault;
  bool isVisible;
  IconData iconData;

  static IconData _getIconForAccount(String name) {
    switch (name.toLowerCase()) {
      case 'cash':
        return Icons.account_balance_wallet_rounded;
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.account_balance_rounded;
    }
  }

  String get displayName => name[0].toUpperCase() + name.substring(1);
  int get displayBalance => balance;

  void addIncome(int income) {
    balance += income;
  }

  void deductExpense(int expense) {
    balance -= expense;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'isDefault': isDefault ? 1 : 0,
      'isVisible': isVisible ? 1 : 0,
      'iconCodePoint': iconData.codePoint,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      isDefault: map['isDefault'] == 1,
      isVisible: map['isVisible'] == 1,
      iconData: map['iconCodePoint'] != null
          ? IconData(map['iconCodePoint'], fontFamily: 'MaterialIcons')
          : Icons.account_balance_rounded,
    );
  }
}
