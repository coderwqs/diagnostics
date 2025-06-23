import 'package:diagnosis/utils/database.dart';
import 'package:diagnosis/model/device.dart';

class DeviceDatabase {
  final DatabaseUtils _dbUtils = DatabaseUtils();

  Future<void> addDevice(Device device) async {
    String sql = '''
      INSERT INTO devices (id, name, image, type, identity, secret, status, lastActive, createdAt)
      VALUES ('${device.id}', '${device.name}', '${device.image}', '${device.type}', '${device.identity}', '${device.secret}', '${device.status.value}', ${device.lastActive}, ${device.createdAt})
    ''';
    await _dbUtils.insert(sql);
  }

  Future<List<Device>> getAllDevices(int page, int limit) async {
    int offset = (page - 1) * limit;

    String sql = 'SELECT * FROM devices LIMIT $limit OFFSET $offset';
    final List<Map<String, dynamic>> maps = await _dbUtils.query(sql);
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