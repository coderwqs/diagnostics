import 'package:diagnosis/model/history.dart';
import 'package:diagnosis/utils/database.dart';

class HistoryDatabase {
  final DatabaseUtils _dbUtils = DatabaseUtils();

  Future<void> initializeDatabase() async {
    String schema = '''
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
    ''';
    await _dbUtils.createTable(schema);
  }

  Future<void> addHistory(History history) async {
    String sql =
        '''
      INSERT INTO history (deviceId, dataTime, samplingRate, rotationSpeed, data, createdAt)
      VALUES (${history.deviceId}, ${history.dataTime}, ${history.samplingRate}, ${history.rotationSpeed}, ${history.data}, ${history.createdAt})
    ''';
    await _dbUtils.insert(sql);
  }

  Future<List<History>> getAllHistory() async {
    String sql = 'SELECT * FROM history';
    final List<Map<String, dynamic>> maps = await _dbUtils.retrieveAll(sql);
    return List.generate(maps.length, (i) {
      return History.fromMap(maps[i]);
    });
  }

  Future<List<History>> getHistoryByDeviceId(String deviceId) async {
    String sql = 'SELECT * FROM history WHERE deviceId = $deviceId';
    final List<Map<String, dynamic>> maps = await _dbUtils.retrieveAll(sql);
    return List.generate(maps.length, (i) {
      return History.fromMap(maps[i]);
    });
  }

  Future<void> updateHistory(History history) async {
    String sql =
        '''
      UPDATE history 
      SET dataTime = ${history.dataTime}, samplingRate = ${history.samplingRate}, rotationSpeed = ${history.rotationSpeed}, data = ${history.data}, createdAt = ${history.createdAt}
      WHERE id = ${history.id}
    ''';
    await _dbUtils.update(sql);
  }

  Future<void> deleteHistory(int id) async {
    String sql = 'DELETE FROM history WHERE id = $id';
    await _dbUtils.delete(sql);
  }
}
