import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();

class Account {
  Account({
    String? id,
    required this.name,
    this.balance = 0,
  })  : id = id ?? uuid.v4(),
        icon = _getIconForAccount(name);

  String id;
  final String name;
  int balance;
  final Icon icon;

  static Icon _getIconForAccount(String name) {
    switch (name.toLowerCase()) {
      case 'cash':
        return const Icon(Icons.account_balance_wallet_rounded);
      case 'card':
        return const Icon(Icons.credit_card);
      default:
        return const Icon(Icons.account_balance_rounded);
    }
  }

  String get getName => name[0].toUpperCase() + name.substring(1);
  int get getBalance => balance;

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
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
    );
  }
}
