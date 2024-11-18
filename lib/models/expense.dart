import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final formatter = DateFormat.yMd();

enum Category { food, transport, medicine, leisure }

const categoryIcons = {
  Category.food: Icons.lunch_dining,
  Category.transport: Icons.emoji_transportation,
  Category.medicine: Icons.medication,
  Category.leisure: Icons.movie
};

class Expense {
  Expense(
      {required this.title,
      required this.amount,
      required this.date,
      required this.category})
      : id = uuid.v4();
  final String id, title;
  final int amount;
  final DateTime date;
  final Category category;

  String get formattedDate {
    return formatter.format(date);
  }
}
