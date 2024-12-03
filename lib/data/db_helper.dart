import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/expense.dart';
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
      version: 2, // Updated version for migration
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
      CREATE TABLE accounts (
        id $idType,
        name $textType,
        balance $intType,
        isDefault $intType DEFAULT 0,
        isVisible $intType DEFAULT 1,
        iconCodePoint $intType DEFAULT ${Icons.account_balance_wallet.codePoint}
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        title $textType,
        amount $intType,
        date $textType,
        category $intType,
        account_id $idType,
        FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
      )
    ''');
  }

  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        ALTER TABLE accounts ADD COLUMN isDefault INTEGER NOT NULL DEFAULT 0
      ''');
      await db.execute('''
        ALTER TABLE accounts ADD COLUMN isVisible INTEGER NOT NULL DEFAULT 1
      ''');
      await db.execute('''
        ALTER TABLE accounts ADD COLUMN iconCodePoint INTEGER NOT NULL DEFAULT ${Icons.account_balance_wallet.codePoint}
      ''');

      // Insert default accounts if they don't exist
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

  Future<void> addDefaultAccounts() async {
    final db = await instance.database;
    for (var account in defaultAccounts) {
      final List<Map<String, dynamic>> existingAccounts = await db
          .query('accounts', where: 'name = ?', whereArgs: [account.name]);
      if (existingAccounts.isEmpty) {
        await db.insert('accounts', account.toMap());
      }
    }
  }

  Future<int> insertExpense(Expense expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense.toMap());
  }

  Future<List<Expense>> getAllExpenses(List<Account> accountsList) async {
    final db = await instance.database;
    final result = await db.query('expenses');
    return result.map((map) {
      final accountId = map['account_id'];
      final account = accountsList.firstWhere(
        (acc) => acc.id == accountId.toString(),
        orElse: () =>
            Account(id: accountId.toString(), name: 'Unknown', balance: 0),
      );
      return Expense.fromMap(map, account);
    }).toList();
  }

  Future<int> deleteExpense(String id) async {
    final db = await instance.database;
    return await db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

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
}
