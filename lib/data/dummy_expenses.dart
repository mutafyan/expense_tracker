import 'package:expense_tracker/models/expense.dart';

var expenses = [
  Expense(
      amount: 1000,
      title: "Taxi",
      category: Category.transport,
      date: DateTime.now()),
  Expense(
      amount: 1500,
      title: "Lunch",
      category: Category.food,
      date: DateTime.now()),
  Expense(
      amount: 5000,
      title: "Cinema",
      category: Category.leisure,
      date: DateTime.now()),
];
