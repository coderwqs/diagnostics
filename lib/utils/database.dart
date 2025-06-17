import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:async';

class DatabaseUtils {
  static final DatabaseUtils _instance = DatabaseUtils._internal();
  static Database? _database;

  DatabaseUtils._internal();

  factory DatabaseUtils() {
    return _instance;
  }

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = await getDatabasesPath();
    return await openDatabase(
      join(path, 'app.db'),
      version: 1,
    );
  }

  Future<void> createTable(String schema) async {
    final db = await database;
    await db.execute(schema);
  }

  Future<void> insert(String sql) async {
    final db = await database;
    await db.execute(sql);
  }

  Future<List<Map<String, dynamic>>> retrieveAll(String sql) async {
    final db = await database;
    return await db.rawQuery(sql);
  }

  Future<void> update(String sql) async {
    final db = await database;
    await db.execute(sql);
  }

  Future<void> delete(String sql) async {
    final db = await database;
    await db.execute(sql);
  }
}