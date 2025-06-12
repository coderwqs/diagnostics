import 'dart:async';
import 'dart:math';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static const String _dbName = 'diagnostics.db';
  int _currentVersion = 1;

  Database? _database;
  final List<Migration> _migrations = [];

  DatabaseHelper._internal();

  Future<Database> get database async {
    return _database ??= await _initDatabase();
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, _dbName);

    return await openDatabase(
      path,
      version: _currentVersion,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA journal_mode=WAL');
    await db.execute('PRAGMA foreign_keys=ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _executeMigrations(db, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await _executeMigrations(db, newVersion, oldVersion);
  }

  Future<void> _executeMigrations(
    Database db,
    int targetVersion, [
    int? oldVersion,
  ]) async {
    final migrationsToExecute = _migrations.where((m) {
      return (oldVersion == null && m.version <= targetVersion) ||
          (oldVersion != null &&
              m.version > oldVersion &&
              m.version <= targetVersion);
    });
    for (final migration in migrationsToExecute) {
      await db.execute(migration.sql);
    }
  }

  /// Add migration scripts
  void addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    _currentVersion = _migrations.map((m) => m.version).fold(0, max) + 1;
  }

  // region Core CRUD operations
  Future<void> createTable(String tableName, TableSchema schema) async {
    final sql = SQLBuilder.buildCreateTable(tableName, schema);
    await _executeSafe((db) => db.execute(sql));
  }

  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<dynamic>? arguments,
  ]) async {
    return await _executeSafe((db) => db.rawQuery(sql, arguments));
  }

  Future<int> rawExecute(String sql, [List<dynamic>? arguments]) async {
    return await _executeSafe((db) => db.rawUpdate(sql, arguments));
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    return await _executeSafe((db) => db.transaction(action));
  }

  // endregion

  // region Advanced features
  final sql = SQLBuilder();

  Future<List<T>> queryAndMap<T>(
    String sql,
    T Function(Map<String, dynamic>) mapper, [
    List<dynamic>? arguments,
  ]) async {
    final results = await rawQuery(sql, arguments);
    return results.map(mapper).toList();
  }

  Future<void> runMigrations(List<Migration> migrations) async {
    await _executeSafe((db) async {
      final batch = db.batch();
      for (final migration in migrations) {
        batch.execute(migration.sql);
      }
      await batch.commit(noResult: true);
    });
  }

  // endregion

  Future<T> _executeSafe<T>(Future<T> Function(Database db) action) async {
    final db = await database;
    try {
      return await action(db);
    } on DatabaseException catch (e) {
      throw DatabaseException('SQL execution failed: ${e.message}');
    } catch (e) {
      throw DatabaseException('Unexpected error: $e');
    }
  }

  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}

/// Migration script
class Migration {
  final int version;
  final String sql;
  final String? description;

  const Migration(this.version, this.sql, [this.description]);
}

/// SQL Builder utility class
class SQLBuilder {
  static String buildCreateTable(String tableName, TableSchema schema) {
    final columns = schema.columns.entries
        .map((e) => '${e.key} ${e.value}')
        .join(', ');
    final constraints = <String>[
      if (schema.primaryKey != null) 'PRIMARY KEY (${schema.primaryKey})',
      ...schema.foreignKeys.map(
        (fk) =>
            'FOREIGN KEY (${fk.column}) REFERENCES ${fk.refTable}(${fk.refColumn})',
      ),
      ...schema.uniqueColumns.map((col) => 'UNIQUE ($col)'),
      ...schema.checks.map((check) => 'CHECK ($check)'),
    ].join(', ');

    return 'CREATE TABLE IF NOT EXISTS $tableName ($columns${constraints.isNotEmpty ? ', $constraints' : ''})';
  }

  String buildInsert(String table, Map<String, dynamic> values) {
    final columns = values.keys.join(', ');
    final placeholders = List.filled(values.length, '?').join(', ');
    return 'INSERT INTO $table ($columns) VALUES ($placeholders)';
  }

  String buildPagination(String baseSql, int page, int pageSize) {
    return '$baseSql LIMIT $pageSize OFFSET ${(page - 1) * pageSize}';
  }
}

/// Table schema definition
class TableSchema {
  final Map<String, String> columns;
  final String? primaryKey;
  final List<ForeignKey> foreignKeys;
  final List<String> uniqueColumns;
  final List<String> checks;

  TableSchema({
    required this.columns,
    this.primaryKey,
    this.foreignKeys = const [],
    this.uniqueColumns = const [],
    this.checks = const [],
  });
}

/// Foreign key constraint
class ForeignKey {
  final String column;
  final String refTable;
  final String refColumn;

  ForeignKey({
    required this.column,
    required this.refTable,
    required this.refColumn,
  });
}

class DatabaseException implements Exception {
  final String message;

  DatabaseException(this.message);

  @override
  String toString() => 'DatabaseException: $message';
}
