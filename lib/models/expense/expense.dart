import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final formatter = DateFormat.yMd();

class Expense {
  Expense({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.account,
  }) : id = id ?? uuid.v4();

  final String id;
  final String title;
  final int amount;
  final DateTime date;
  final Category category;
  final Account account;

  String get formattedDate {
    return formatter.format(date);
  }

  // Serialize to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': category.id, // Reference by Category ID
      'account_id': account.id,
    };
  }

  // Deserialize from Map
  factory Expense.fromMap(
      Map<String, dynamic> map, Account account, Category category) {
    return Expense(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: category,
      account: account,
    );
  }
}
