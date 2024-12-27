import 'package:expense_tracker/models/category/category.dart';
import 'package:expense_tracker/models/transaction/financial_transaction.dart';
import 'package:expense_tracker/models/transaction/financial_transaction_type.dart';

class ExpenseBucket {
  final Category category;
  final double totalAmount;

  // Constructing an ExpenseBucket from a list of transactions.
  ExpenseBucket.forCategory(
      List<FinancialTransaction> transactions, this.category)
      : totalAmount = transactions
            .where((t) =>
                t.category.id == category.id &&
                t.type == FinancialTransactionType.expense)
            .fold(0, (sum, t) => sum + t.amount);
}
