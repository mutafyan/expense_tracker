import 'package:expense_tracker/models/account/account.dart';
import 'package:expense_tracker/models/expense.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  final List<Account> defaultAccounts = [
    Account(name: "Cash", balance: 0),
    Account(name: "Card", balance: 0),
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
      version: 1,
      onCreate: _createDB,
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
        balance $intType
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id $idType,
        title $textType,
        amount $intType,
        date $textType,
        category $intType,
        account_id $textType,
        FOREIGN KEY (account_id) REFERENCES accounts (id)
      )
    ''');
  }

  Future<void> addDefaultAccounts() async {
    final db = await instance.database;
    for (var account in defaultAccounts) {
      final List<Map<String, dynamic>> existingAccounts = await db
          .query('accounts', where: 'name = ?', whereArgs: [account.name]);
      if (existingAccounts.isEmpty) {
        await db.insert('accounts', account.toMap());
      } else {
        account.id = existingAccounts.first['id'];
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

  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts');
    return result.map((map) => Account.fromMap(map)).toList();
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
}
