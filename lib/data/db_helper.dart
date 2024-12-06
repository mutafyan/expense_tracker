// lib/data/db_helper.dart
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:expense_tracker/models/expense/expense.dart';
import 'package:expense_tracker/data/default_categories.dart';
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
    _database = await _initDB('expenses.db');
    return _database!;
  }

  Future<Database> _initDB(String dbName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, dbName);

    return await openDatabase(
      path,
      version: 2, // Incremented version for migration
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Create tables
  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // Create accounts table
    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        name $textType,
        balance $intType DEFAULT 0,
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

    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        title $textType,
        amount $intType,
        date $textType,
        category_id TEXT,
        account_id TEXT NOT NULL,
        FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');

    // Insert default categories
    for (var category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }

    // Insert default accounts
    for (var account in defaultAccounts) {
      await db.insert('accounts', account.toMap());
    }
  }

  // Handle database upgrades
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Step 1: Create new categories table
      await db.execute('''
        CREATE TABLE categories (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          iconCodePoint INTEGER NOT NULL,
          isDefault INTEGER NOT NULL DEFAULT 0,
          isVisible INTEGER NOT NULL DEFAULT 1
        )
      ''');

      // Step 2: Insert default categories
      for (var category in defaultCategories) {
        await db.insert('categories', category.toMap());
      }

      // Step 3: Migrate existing expenses to reference category IDs
      final expenses = await db.query('expenses');

      // Mapping from enum index to default category IDs
      final Map<int, String> categoryIndexToId = {
        0: defaultCategories[0].id, // Food
        1: defaultCategories[1].id, // Transport
        2: defaultCategories[2].id, // Health
        3: defaultCategories[3].id, // Leisure
      };

      for (var expenseMap in expenses) {
        final categoryIndex = expenseMap['category'] as int;
        final categoryId = categoryIndexToId[categoryIndex];
        if (categoryId != null) {
          await db.update(
            'expenses',
            {'category_id': categoryId},
            where: 'id = ?',
            whereArgs: [expenseMap['id']],
          );
        } else {
          // Assign to a default category if mapping is not found
          await db.update(
            'expenses',
            {'category_id': defaultCategories[0].id},
            where: 'id = ?',
            whereArgs: [expenseMap['id']],
          );
        }
      }

      // Step 4: Recreate the expenses table without the old 'category' column
      await db.execute('''
        CREATE TABLE expenses_new (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          amount INTEGER NOT NULL,
          date TEXT NOT NULL,
          category_id TEXT,
          account_id TEXT NOT NULL,
          FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL,
          FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
        )
      ''');

      // Step 5: Copy data from old expenses table to new expenses table
      await db.execute('''
        INSERT INTO expenses_new (id, title, amount, date, category_id, account_id)
        SELECT id, title, amount, date, category_id, account_id FROM expenses
      ''');

      // Step 6: Drop the old expenses table
      await db.execute('DROP TABLE expenses');

      // Step 7: Rename the new expenses table to the original name
      await db.execute('ALTER TABLE expenses_new RENAME TO expenses');
    }
  }

  // Category CRUD Operations

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
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(String id) async {
    final db = await instance.database;
    // Optionally handle associated expenses, e.g., set category_id to null or assign to default category
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // Expense CRUD Operations

  Future<List<Expense>> getAllExpenses() async {
    final db = await instance.database;
    final expensesMap = await db.query('expenses');

    // Fetch all visible categories
    final categories = await getAllCategories(includeHidden: false);
    final categoryMap = {for (var cat in categories) cat.id: cat};

    // Fetch all visible accounts
    final accounts = await getAllAccounts(includeHidden: false);
    final accountMap = {for (var acc in accounts) acc.id: acc};

    return expensesMap.map((map) {
      final accountId = map['account_id'] as String;
      final categoryId = map['category_id'] as String?;
      final account = accountMap[accountId] ??
          Account(
              id: accountId,
              name: 'Unknown',
              balance: 0); // Handle missing account
      final category = categoryId != null
          ? categoryMap[categoryId] ??
              Category(
                id: categoryId,
                name: 'Unknown',
                iconCodePoint: Icons.help_outline.codePoint,
                isDefault: false,
                isVisible: true,
              )
          : Category(
              id: 'unknown',
              name: 'Unknown',
              iconCodePoint: Icons.help_outline.codePoint,
              isDefault: false,
              isVisible: true,
            );

      return Expense.fromMap(map, account, category);
    }).toList();
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<int> deleteExpense(String id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  // Account CRUD Operations

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
    return await db.insert('accounts', account.toMap());
  }

  Future<int> updateAccount(Account account) async {
    final db = await instance.database;
    return await db.update(
      'accounts',
      account.toMap(),
      where: 'id = ?',
      whereArgs: [account.id],
    );
  }

  Future<int> deleteAccount(String id) async {
    final db = await instance.database;
    // Delete associated expenses first
    await db.delete('expenses', where: 'account_id = ?', whereArgs: [id]);
    return await db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  // Ensure default categories are added (in case of initial setup)
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
