import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseUtils {
  static final DatabaseUtils _instance = DatabaseUtils._internal();
  static Database? _database;

  // Private constructor
  DatabaseUtils._internal();

  factory DatabaseUtils() => _instance;

  /// Initialize the database
  Future<void> init(List<String> tables, int version) async {
    if (_database != null) return;

    final path = join(await getDatabasesPath(), 'app.db');
    try {
      _database = await openDatabase(
        path,
        version: version,
        onCreate: (db, version) async {
          await _createTables(db, tables);
        },
        onConfigure: _onConfigure,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      print('Database initialization error: $e');
    }
  }

  /// Get the initialized database instance
  Database get database {
    if (_database == null) {
      throw Exception('Database not initialized. Call init() first.');
    }
    return _database!;
  }

  // Database configuration callback
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  // Database upgrade callback
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE devices ADD COLUMN description TEXT');
    }
  }

  // Create all tables dynamically
  Future<void> _createTables(Database db, List<String> tables) async {
    for (final tableDef in tables) {
      await db.execute(tableDef);
    }
  }

  // --- Database operation methods ---

  Future<void> execute(String sql, [List<dynamic>? args]) async {
    await database.execute(sql, args);
  }

  Future<int> insert(String sql, [List<dynamic>? args]) async {
    return await database.rawInsert(sql, args ?? []);
  }

  Future<void> batchInsert(String sql, List<List<dynamic>> argsList) async {
    final batch = database.batch();
    for (final args in argsList) {
      batch.rawInsert(sql, args);
    }
    await batch.commit(noResult: true);
  }

  Future<Map<String, dynamic>?> querySingle(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final result = await database.rawQuery(sql, args ?? []);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic>? args,
  ]) async {
    return await database.rawQuery(sql, args ?? []);
  }

  Future<int> update(String sql, [List<dynamic>? args]) async {
    return await database.rawUpdate(sql, args ?? []);
  }

  Future<int> delete(String sql, [List<dynamic>? args]) async {
    return await database.rawDelete(sql, args ?? []);
  }

  Future<void> close() async {
    await database.close();
    _database = null;
  }
}
