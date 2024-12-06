import 'package:expense_tracker/models/expense/expense.dart';
import 'package:expense_tracker/models/category/category.dart';

class ExpenseBucket {
  final Category category;
  final int totalAmount;

  ExpenseBucket.forCategory(List<Expense> expenses, this.category)
      : totalAmount = expenses
            .where((expense) => expense.category.id == category.id)
            .fold(0, (sum, expense) => sum + expense.amount);
}
