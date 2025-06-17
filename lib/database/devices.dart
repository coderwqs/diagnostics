import 'package:diagnosis/utils/database.dart';
import 'package:diagnosis/model/device.dart';

class DeviceDatabase {
  final DatabaseUtils _dbUtils = DatabaseUtils();

  Future<void> initializeDatabase() async {
    String schema = '''
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
    ''';
    await _dbUtils.createTable(schema);
  }

  Future<void> addDevice(Device device) async {
    String sql = '''
      INSERT INTO devices (id, name, image, type, identity, secret, status, lastActive, createdAt)
      VALUES ('${device.id}', '${device.name}', '${device.image}', '${device.type}', '${device.identity}', '${device.secret}', '${device.status.value}', ${device.lastActive}, ${device.createdAt})
    ''';
    await _dbUtils.insert(sql);
  }

  Future<List<Device>> getAllDevices() async {
    String sql = 'SELECT * FROM devices';
    final List<Map<String, dynamic>> maps = await _dbUtils.retrieveAll(sql);
    return List.generate(maps.length, (i) {
      return Device.fromJson(maps[i]);
    });
  }

  Future<void> updateDevice(Device device) async {
    String sql = '''
      UPDATE devices 
      SET name = '${device.name}', image = '${device.image}', type = '${device.type}', identity = '${device.identity}', secret = '${device.secret}'
      WHERE id = '${device.id}'
    ''';
    await _dbUtils.update(sql);
  }

  Future<void> updateDeviceStatus(String deviceId, String status) async {
    String sql = '''
      UPDATE devices 
      SET status = '$status', lastActive = ${DateTime.now().millisecondsSinceEpoch}
      WHERE id = '$deviceId'
    ''';
    await _dbUtils.update(sql);
  }

  Future<void> deleteDevice(String id) async {
    String sql = 'DELETE FROM devices WHERE id = "$id"';
    await _dbUtils.delete(sql);
  }
}