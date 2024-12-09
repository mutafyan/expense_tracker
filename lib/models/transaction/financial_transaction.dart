import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:expense_tracker/models/transaction/financial_transaction_type.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

const uuid = Uuid();
final formatter = DateFormat.yMd();

class FinancialTransaction {
  FinancialTransaction({
    String? id,
    required this.title,
    required this.amount,
    required this.date,
    required this.category,
    required this.account,
    required this.type,
  }) : id = id ?? uuid.v4();

  final String id;
  final String title;
  final int amount;
  final DateTime date;
  final Category category;
  final Account account;
  final FinancialTransactionType type;

  String get formattedDate {
    return formatter.format(date);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category_id': category.id,
      'account_id': account.id,
      'type': type.name,
    };
  }

  factory FinancialTransaction.fromMap(
      Map<String, dynamic> map, Account account, Category category) {
    return FinancialTransaction(
      id: map['id'],
      title: map['title'],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      category: category,
      account: account,
      type: FinancialTransactionTypeExtension.fromString(map['type']),
    );
  }
}
