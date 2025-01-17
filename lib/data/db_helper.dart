import 'package:expense_tracker/data/default_categories.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/currency/currency.dart';
import 'package:expense_tracker/models/transaction/financial_transaction.dart';
import 'package:expense_tracker/models/transaction/financial_transaction_type.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/material.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  final List<Account> defaultAccounts = [
    Account(name: "Cash", isDefault: true),
    Account(name: "Card", isDefault: true),
  ];

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('transactions.db');
    return _database!;
  }

  Future<Database> _initDB(String dbName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 6,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute("PRAGMA foreign_keys = ON");
      },
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';
    const doubleType = 'REAL NOT NULL';
    // Create accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        name $textType,
        balance $doubleType DEFAULT 0,
        isDefault $intType DEFAULT 0,
        isVisible $intType DEFAULT 1,
        iconCodePoint $intType DEFAULT ${Icons.account_balance_wallet.codePoint}
      )
    ''');

    // Create categories table
    await db.execute('''
      CREATE TABLE categories (
        id $idType,
        name $textType,
        iconCodePoint $intType,
        isDefault $intType DEFAULT 0,
        isVisible $intType DEFAULT 1
      )
    ''');

    // Create transactions table
    await db.execute('''
  CREATE TABLE transactions (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    amount REAL NOT NULL,
    date TEXT NOT NULL,
    category_id TEXT,
    account_id TEXT,
    type TEXT NOT NULL,
    currency_symbol TEXT NOT NULL,
    currency_name TEXT NOT NULL,
    currency_iso TEXT NOT NULL, -- Add this column
    FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
    FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
  )
''');

    // create currency table
    await db.execute('''
    CREATE TABLE selected_currency (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      currency_iso TEXT NOT NULL,
      currency_symbol TEXT NOT NULL,
      currency_name TEXT NOT NULL
    )
  ''');

    // Insert a default currency (e.g., AMD)
    await db.insert('selected_currency', {
      'currency_iso': 'AMD',
      'currency_symbol': '֏',
      'currency_name': 'Armenian Dram'
    });

    await _insertDefaultCategories(db);

    for (var account in defaultAccounts) {
      await db.insert('accounts', account.toMap());
    }

    // Insert a default 'Uncategorized' category
    final uncategorized = Category(
      name: "Uncategorized",
      iconCodePoint: Icons.help_outline.codePoint,
      isDefault: true,
      isVisible: false,
    );
    await db.insert('categories', uncategorized.toMap());
  }

  Future _insertDefaultCategories(Database db) async {
    for (var category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 6) {
      // Add selected_currency table
      await db.execute('''
      CREATE TABLE IF NOT EXISTS selected_currency (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        currency_iso TEXT NOT NULL,
        currency_symbol TEXT NOT NULL,
        currency_name TEXT NOT NULL
      )
    ''');

      // Insert a default currency (e.g., AMD) if the table is empty
      final result = await db.query('selected_currency');
      if (result.isEmpty) {
        await db.insert('selected_currency', {
          'currency_iso': 'AMD',
          'currency_symbol': '֏',
          'currency_name': 'Armenian Dram'
        });
      }
    }
  }

  // Currency CRUD
  Future<void> saveSelectedCurrency(Currency currency) async {
    final db = await instance.database;

    // Clear any existing selection and add the new currency
    await db.delete('selected_currency');
    await db.insert('selected_currency', {
      'currency_iso': currency.iso,
      'currency_symbol': currency.symbol,
      'currency_name': currency.name
    });
  }

  Future<Currency> getSelectedCurrency() async {
    final db = await instance.database;

    final result = await db.query('selected_currency', limit: 1);
    if (result.isNotEmpty) {
      final currency = result.first;
      return Currency(
        currency['currency_symbol'] as String,
        currency['currency_name'] as String,
        currency['currency_iso'] as String,
      );
    }

    // Return a default currency if none is found
    return Currency('֏', 'Armenian Dram', 'AMD');
  }

  // Category CRUD
  Future<List<Category>> getAllCategories({bool includeHidden = true}) async {
    final db = await instance.database;
    final result = await db.query(
      'categories',
      where: includeHidden ? null : 'isVisible = ?',
      whereArgs: includeHidden ? null : [1],
    );
    return result.map((map) => Category.fromMap(map)).toList();
  }

  Future<int> insertCategory(Category category) async {
    final db = await instance.database;

    final activeCategoriesCount = Sqflite.firstIntValue(
          await db
              .rawQuery('SELECT COUNT(*) FROM categories WHERE isVisible = 1'),
        ) ??
        0;

    if (activeCategoriesCount >= 10 && category.isVisible) {
      throw Exception('Maximum of 10 active categories reached.');
    }

    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;

    if (category.isVisible) {
      final activeCategoriesCount = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM categories WHERE isVisible = 1 AND id != ?',
              [category.id])) ??
          0;

      if (activeCategoriesCount >= 10) {
        throw Exception('Maximum of 10 active categories reached.');
      }
    }

    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await instance.database;

    final category = await db.query('categories',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (category.isEmpty) {
      throw Exception('Category not found.');
    }

    if (category.first['isDefault'] == 1) {
      throw Exception('Cannot delete a default category.');
    }

    // Reassign associated transactions to 'Uncategorized'
    final uncategorized = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: ['Uncategorized'],
      limit: 1,
    );

    String uncategorizedId;
    if (uncategorized.isEmpty) {
      final newUncategorized = Category(
        name: "Uncategorized",
        iconCodePoint: Icons.help_outline.codePoint,
        isDefault: true,
        isVisible: true,
      );
      uncategorizedId = newUncategorized.id;
      await db.insert('categories', newUncategorized.toMap());
    } else {
      uncategorizedId = uncategorized.first['id'] as String;
    }

    // Reassign transactions
    await db.update(
      'transactions',
      {'category_id': uncategorizedId},
      where: 'category_id = ?',
      whereArgs: [id],
    );

    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Account CRUD
  Future<List<Account>> getAllAccounts({bool includeHidden = true}) async {
    final db = await instance.database;
    final result = await db.query(
      'accounts',
      where: includeHidden ? null : 'isVisible = ?',
      whereArgs: includeHidden ? null : [1],
    );
    return result.map((map) => Account.fromMap(map)).toList();
  }

  Future<int> insertAccount(Account account) async {
    final db = await instance.database;

    final activeAccountsCount = Sqflite.firstIntValue(
          await db
              .rawQuery('SELECT COUNT(*) FROM accounts WHERE isVisible = 1'),
        ) ??
        0;

    if (activeAccountsCount >= 10 && account.isVisible) {
      throw Exception('Maximum of 10 active accounts reached.');
    }

    return await db.insert('accounts', account.toMap());
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;

    account.balance = double.parse(account.balance.toStringAsFixed(2));

    if (account.isVisible) {
      final activeAccountsCount = Sqflite.firstIntValue(await db.rawQuery(
              'SELECT COUNT(*) FROM accounts WHERE isVisible = 1 AND id != ?',
              [account.id])) ??
          0;

      if (activeAccountsCount >= 10) {
        throw Exception('Maximum of 10 active accounts reached.');
      }
    }

    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(String id) async {
    final db = await instance.database;

    final account =
        await db.query('accounts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (account.isEmpty) {
      throw Exception('Account not found.');
    }

    if (account.first['isDefault'] == 1) {
      throw Exception('Cannot delete a default account.');
    }

    // Deleting an account cascades to delete its transactions
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // Transactions CRUD
  Future<List<FinancialTransaction>> getAllTransactions() async {
    final db = await instance.database;
    final txMap = await db.query('transactions');

    final categories = await getAllCategories(includeHidden: false);
    final categoryMap = {for (var cat in categories) cat.id: cat};

    final accounts = await getAllAccounts(includeHidden: false);
    final accountMap = {for (var acc in accounts) acc.id: acc};
    return txMap.map((map) {
      final accountId = map['account_id'] as String;
      final categoryId = map['category_id'] as String?;

      final account = accountMap[accountId] ??
          Account(id: accountId, name: 'Unknown', balance: 0);
      final category = categoryId != null
          ? categoryMap[categoryId] ??
              Category(
                id: categoryId,
                name: 'Uncategorized',
                iconCodePoint: Icons.help_outline.codePoint,
                isDefault: true,
                isVisible: true,
              )
          : Category(
              id: 'unknown',
              name: 'Uncategorized',
              iconCodePoint: Icons.help_outline.codePoint,
              isDefault: true,
              isVisible: true,
            );

      return FinancialTransaction.fromMap(map, account, category);
    }).toList();
  }

  Future<List<FinancialTransaction>> getAllIncomes() async {
    final db = await instance.database;
    final txMap = await db.query(
      'transactions',
      where: 'type = ?', // Filter for income
      whereArgs: [FinancialTransactionType.income.name],
    );

    final categories = await getAllCategories(includeHidden: false);
    final categoryMap = {for (var cat in categories) cat.id: cat};

    final accounts = await getAllAccounts(includeHidden: false);
    final accountMap = {for (var acc in accounts) acc.id: acc};

    return txMap.map((map) {
      final accountId = map['account_id'] as String;
      final categoryId = map['category_id'] as String?;

      final account = accountMap[accountId] ??
          Account(id: accountId, name: 'Unknown', balance: 0);
      final category = categoryId != null
          ? categoryMap[categoryId] ??
              Category(
                id: categoryId,
                name: 'Uncategorized',
                iconCodePoint: Icons.help_outline.codePoint,
                isDefault: true,
                isVisible: true,
              )
          : Category(
              id: 'unknown',
              name: 'Uncategorized',
              iconCodePoint: Icons.help_outline.codePoint,
              isDefault: true,
              isVisible: true,
            );

      return FinancialTransaction.fromMap(map, account, category);
    }).toList();
  }

  Future<List<FinancialTransaction>> getAllExpenses() async {
    final db = await instance.database;
    final txMap = await db.query(
      'transactions',
      where: 'type = ?', // Filter for expense
      whereArgs: [FinancialTransactionType.expense.name],
    );

    final categories = await getAllCategories(includeHidden: false);
    final categoryMap = {for (var cat in categories) cat.id: cat};

    final accounts = await getAllAccounts(includeHidden: false);
    final accountMap = {for (var acc in accounts) acc.id: acc};

    return txMap.map((map) {
      final accountId = map['account_id'] as String;
      final categoryId = map['category_id'] as String?;

      final account = accountMap[accountId] ??
          Account(id: accountId, name: 'Unknown', balance: 0);
      final category = categoryId != null
          ? categoryMap[categoryId] ??
              Category(
                id: categoryId,
                name: 'Uncategorized',
                iconCodePoint: Icons.help_outline.codePoint,
                isDefault: true,
                isVisible: true,
              )
          : Category(
              id: 'unknown',
              name: 'Uncategorized',
              iconCodePoint: Icons.help_outline.codePoint,
              isDefault: true,
              isVisible: true,
            );

      return FinancialTransaction.fromMap(map, account, category);
    }).toList();
  }

  Future<int> insertTransaction(FinancialTransaction transaction) async {
    final db = await instance.database;
    if (transaction.type == FinancialTransactionType.expense &&
        transaction.account.balance - transaction.amount < 0) {
      return 402; // not enough balance
    }
    return await db.insert('transactions', transaction.toMap());
  }

  Future<int> deleteTransaction(String id) async {
    final db = await instance.database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> addDefaultCategories() async {
    final db = await instance.database;
    for (var category in defaultCategories) {
      final existing = await db.query(
        'categories',
        where: 'name = ?',
        whereArgs: [category.name],
      );
      if (existing.isEmpty) {
        await db.insert('categories', category.toMap());
      }
    }

    final uncategorized = await db.query(
      'categories',
      where: 'name = ?',
      whereArgs: ['Uncategorized'],
      limit: 1,
    );
    if (uncategorized.isEmpty) {
      final newUncategorized = Category(
        name: "Uncategorized",
        iconCodePoint: Icons.help_outline.codePoint,
        isDefault: true,
        isVisible: true,
      );
      await db.insert('categories', newUncategorized.toMap());
    }
  }

  Future<void> addDefaultAccounts() async {
    final db = await instance.database;
    for (var account in defaultAccounts) {
      final existing = await db.query(
        'accounts',
        where: 'name = ?',
        whereArgs: [account.name],
      );
      if (existing.isEmpty) {
        await db.insert('accounts', account.toMap());
      }
    }
  }
}
