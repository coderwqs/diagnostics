import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseUtils {
  static final DatabaseUtils _instance = DatabaseUtils._internal();
  static Database? _database;

  DatabaseUtils._internal();

  factory DatabaseUtils() => _instance;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final path = join(await getDatabasesPath(), 'app.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // 启用外键支持
        await db.execute('PRAGMA foreign_keys = ON');
        // 创建用户表
        await db.execute(
          '''
          CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            password TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
          '''
        );
        // 创建设备表
        await db.execute(
            '''
            CREATE TABLE IF NOT EXISTS devices (
              id TEXT PRIMARY KEY,
              name TEXT NOT NULL,
              type TEXT NOT NULL,
              identity TEXT NOT NULL UNIQUE,
              secret TEXT NOT NULL,
              status TEXT CHECK (status IN ('online', 'offline', 'warning')) DEFAULT 'offline',
              lastActive INTEGER NOT NULL,
              createdAt INTEGER NOT NULL,
              image BLOB NOT NULL
            )
            '''
        );
        // 创建历史记录表（需先于features表创建）
        await db.execute(
            '''
            CREATE TABLE IF NOT EXISTS history (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              deviceId TEXT NOT NULL,
              dataTime INTEGER NOT NULL,
              samplingRate REAL NOT NULL,
              rotationSpeed INTEGER,
              data BLOB NOT NULL,
              createdAt INTEGER NOT NULL,
              FOREIGN KEY (deviceId) REFERENCES devices(id)
            )
            '''
        );
        // 创建数据特征表
        await db.execute(
            '''
            CREATE TABLE IF NOT EXISTS features (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              historyId INTEGER NOT NULL,
              deviceId TEXT NOT NULL,
              rms REAL,
              vpp REAL,
              max REAL,
              min REAL,
              mean REAL,
              arv REAL,
              peak REAL,
              variance REAL,
              stdDev REAL,
              msa REAL,
              crestFactor REAL,
              kurtosis REAL,
              formFactor REAL,
              skewness REAL,
              pulseFactor REAL,
              clearanceFactor REAL,
              FOREIGN KEY (historyId) REFERENCES history(id) ON DELETE CASCADE
            );
            CREATE INDEX IF NOT EXISTS idx_features_device ON features(deviceId);
            CREATE INDEX IF NOT EXISTS idx_features_history ON features(historyId);
            '''
        );
      },
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> execute(String sql, [List<dynamic>? args]) async {
    final db = await database;
    await db.execute(sql, args);
  }

  Future<int> insert(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return await db.rawInsert(sql, args ?? []);
  }

  Future<Map<String, dynamic>?> querySingle(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await database;
    final result = await db.rawQuery(sql, args ?? []);
    return result.isNotEmpty ? result.first : null;
  }

  Future<List<Map<String, dynamic>>> query(
    String sql, [
    List<dynamic>? args,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, args ?? []);
  }

  Future<int> update(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return await db.rawUpdate(sql, args ?? []);
  }

  Future<int> delete(String sql, [List<dynamic>? args]) async {
    final db = await database;
    return await db.rawDelete(sql, args ?? []);
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) async {
    final db = await database;
    return await db.transaction(action);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }
}
