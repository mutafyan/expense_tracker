import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/expense.dart';

var expenses = [
  Expense(
    amount: 1000,
    title: "Taxi",
    category: Category.transport,
    date: DateTime.now(),
    account: Account(name: "cash"),
  ),
  Expense(
    amount: 1500,
    title: "Lunch",
    category: Category.food,
    date: DateTime.now(),
    account: Account(name: "cash"),
  ),
  Expense(
    amount: 5000,
    title: "Cinema",
    category: Category.leisure,
    date: DateTime.now(),
    account: Account(name: "card"),
  ),
];
