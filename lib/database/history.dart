import 'package:diagnosis/model/history.dart';
import 'package:diagnosis/utils/database.dart';

class HistoryDatabase {
  final DatabaseUtils _dbUtils = DatabaseUtils();

  Future<void> addHistory(History history) async {
    String sql =
        '''
      INSERT INTO history (deviceId, dataTime, samplingRate, rotationSpeed, data, createdAt)
      VALUES (${history.deviceId}, ${history.dataTime}, ${history.samplingRate}, ${history.rotationSpeed}, ${history.data}, ${history.createdAt})
    ''';
    await _dbUtils.insert(sql);
  }

  Future<List<ExtendedHistory>> getAllHistories(int page, int limit) async {
    int offset = (page - 1) * limit;

    String sql =
        '''
      SELECT h.id, h.deviceId, h.dataTime, h.samplingRate, h.rotationSpeed, 
      h.createdAt, d.name AS deviceName FROM history h 
      LEFT JOIN devices d ON d.id = h.deviceId LIMIT $limit OFFSET $offset
    ''';
    final List<Map<String, dynamic>> maps = await _dbUtils.query(sql);

    return List.generate(maps.length, (i) {
      return ExtendedHistory.fromMap(maps[i]);
    });
  }

  Future<ExtendedHistory?> getHistoryByDeviceId(
    int historyId,
    String deviceId,
  ) async {
    String sql =
        '''
    SELECT h.id, h.deviceId, h.dataTime, h.samplingRate, h.rotationSpeed, h.data, 
    h.createdAt, d.name AS deviceName FROM history h 
    LEFT JOIN devices d ON d.id = h.deviceId 
    WHERE h.deviceId = '$deviceId' AND h.id = $historyId;
  ''';

    final Map<String, dynamic>? map = await _dbUtils.querySingle(sql);

    if (map != null) {
      return ExtendedHistory.fromMap(map);
    } else {
      return null;
    }
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
