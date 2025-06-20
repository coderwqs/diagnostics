import 'package:diagnosis/database/history.dart';
import 'package:diagnosis/model/history.dart';

class HistoryService {
  final HistoryDatabase _historyDatabase = HistoryDatabase();

  Future<void> addHistory(History history) async {
    if (history.createdAt == 0) {
      history.createdAt = DateTime.now().millisecondsSinceEpoch;
    }

    if (history.createdAt == 0) {
      history.createdAt = DateTime.now().millisecondsSinceEpoch;
    }

    await _historyDatabase.addHistory(history);
  }

  Future<List<ExtendedHistory>> getAllHistories(int page, limit) async {
    return await _historyDatabase.getAllHistories(page, limit);
  }

  Future<ExtendedHistory?> getHistory(int id, String deviceId) async {
    return await _historyDatabase.getHistoryByDeviceId(id, deviceId);
  }

  Future<void> updateHistory(History history) async {
    await _historyDatabase.updateHistory(history);
  }

  Future<void> deleteHistory(int id) async {
    await _historyDatabase.deleteHistory(id);
  }
}
