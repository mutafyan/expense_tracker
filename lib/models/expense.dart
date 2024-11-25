import 'package:expense_tracker/models/account/account.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final formatter = DateFormat.yMd();

enum Category { food, transport, health, leisure }

const categoryIcons = {
  Category.food: Icons.lunch_dining,
  Category.transport: Icons.emoji_transportation,
  Category.health: Icons.medication,
  Category.leisure: Icons.movie,
};

class Expense {
  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.account,
  }) : id = id ?? uuid.v4();

  final String id, title;
  final int amount;
  final DateTime date;
  final Category category;
  final Account account;

  String get formattedDate {
    return formatter.format(date);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category.index,
      'account_id': account.id,
    };
  }

  factory Expense.fromMap(Map<String, dynamic> map, Account account) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: Category.values[map['category']],
      account: account,
    );
  }
}
