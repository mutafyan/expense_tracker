enum FinancialTransactionType { expense, income }

extension FinancialTransactionTypeExtension on FinancialTransactionType {
  String get name {
    switch (this) {
      case FinancialTransactionType.expense:
        return 'expense';
      case FinancialTransactionType.income:
        return 'income';
    }
  }

  static FinancialTransactionType fromString(String value) {
    return value == 'income'
        ? FinancialTransactionType.income
        : FinancialTransactionType.expense;
  }
}
