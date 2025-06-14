import 'package:diagnosis/model/device.dart';
import 'package:diagnosis/database/devices.dart';
import 'package:uuid/uuid.dart';

class DeviceService {
  final DeviceDatabase _deviceDatabase = DeviceDatabase();

  Future<void> addDevice(Device device) async {
    if (device.id.isEmpty) {
      device.id = Uuid().v4();
    }

    if (device.createdAt == 0) {
      device.createdAt = DateTime.now().millisecondsSinceEpoch;
    }

    await _deviceDatabase.addDevice(device);
  }

  Future<List<Device>> getAllDevices() async {
    return await _deviceDatabase.getAllDevices();
  }

  Future<void> updateDevice(Device device) async {
    await _deviceDatabase.updateDevice(device);
  }

  Future<void> updateDeviceStatus(String id, String status) async {
    await _deviceDatabase.updateDeviceStatus(id, status);
  }

  Future<void> deleteDevice(String id) async {
    await _deviceDatabase.deleteDevice(id);
  }
}
