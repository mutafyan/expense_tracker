import 'package:expense_tracker/data/default_categories.dart';
import 'package:expense_tracker/models/category/category.dart';
import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/expense/expense.dart';
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
      version: 3, // Incremented version for new migration
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
      onOpen: (db) async {
        await db.execute("PRAGMA foreign_keys = ON"); // Enable foreign keys
      },
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
    await _insertDefaultCategories(db);

    // Insert default accounts
    for (var account in defaultAccounts) {
      await db.insert('accounts', account.toMap());
    }

    // Insert a default 'Uncategorized' category to handle deleted categories
    final uncategorized = Category(
      name: "Uncategorized",
      iconCodePoint: Icons.help_outline.codePoint,
      isDefault: true,
      isVisible: true,
    );
    await db.insert('categories', uncategorized.toMap());
  }

  Future _insertDefaultCategories(Database db) async {
    final defaultCategories = [
      Category(
          name: "Food",
          iconCodePoint: Icons.fastfood.codePoint,
          isDefault: true),
      Category(
          name: "Transport",
          iconCodePoint: Icons.directions_car.codePoint,
          isDefault: true),
      Category(
          name: "Health",
          iconCodePoint: Icons.healing.codePoint,
          isDefault: true),
      Category(
          name: "Entertainment",
          iconCodePoint: Icons.movie.codePoint,
          isDefault: true),
      // Add more default categories as needed
    ];

    for (var category in defaultCategories) {
      await db.insert('categories', category.toMap());
    }
  }

  // Handle database upgrades
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.transaction((txn) async {
        // Example migration steps for version 2
        // Add any necessary migration steps here
      });
    }

    if (oldVersion < 3) {
      // No specific migration steps for version 3 yet
      // But incrementing the version to manage future migrations
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

    // Check if the category limit is reached
    final activeCategoriesCount = Sqflite.firstIntValue(await db
            .rawQuery('SELECT COUNT(*) FROM categories WHERE isVisible = 1')) ??
        0;

    if (activeCategoriesCount >= 10 && category.isVisible) {
      throw Exception('Maximum of 10 active categories reached.');
    }

    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await instance.database;

    // If setting isVisible to true, ensure the limit is not exceeded
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

    // Prevent deletion of default categories
    final category = await db.query('categories',
        where: 'id = ?', whereArgs: [id], limit: 1);
    if (category.isEmpty) {
      throw Exception('Category not found.');
    }

    if (category.first['isDefault'] == 1) {
      throw Exception('Cannot delete a default category.');
    }

    // Reassign associated expenses to 'Uncategorized'
    final uncategorized = await db.query('categories',
        where: 'name = ?', whereArgs: ['Uncategorized'], limit: 1);

    String uncategorizedId;
    if (uncategorized.isEmpty) {
      // Create 'Uncategorized' category if it doesn't exist
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

    // Reassign expenses
    await db.update(
      'expenses',
      {'category_id': uncategorizedId},
      where: 'category_id = ?',
      whereArgs: [id],
    );

    // Delete the category
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

    // Ensure 'Uncategorized' category exists
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

  // Implement the missing addDefaultAccounts method
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
