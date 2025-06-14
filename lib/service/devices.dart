import 'package:diagnosis/model/device.dart';
import 'package:diagnosis/database/devices.dart';

class DeviceService {
  final DeviceDatabase _deviceDatabase = DeviceDatabase();

  Future<void> addDevice(Device device) async {
    await _deviceDatabase.addDevice(device);
  }

  Future<List<Device>> getAllDevices() async {
    return await _deviceDatabase.getAllDevices();
  }

  Future<void> updateDevice(Device device) async {
    await _deviceDatabase.updateDevice(device);
  }

  Future<void> deleteDevice(String id) async {
    await _deviceDatabase.deleteDevice(id);
  }
}