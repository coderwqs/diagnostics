import 'package:diagnosis/model/features.dart';
import 'package:diagnosis/utils/database.dart';

class FeaturesDatabase {
  final DatabaseUtils _dbUtils = DatabaseUtils();

  Future<int> insertFeature(Feature feature) async {
    final sql = '''
      INSERT INTO features (
        historyId, deviceId, rms, vpp, max, min, mean, arv, peak,
        variance, stdDev, msa, crestFactor, kurtosis, formFactor,
        skewness, pulseFactor, clearanceFactor
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';

    final params = [
      feature.historyId,
      feature.deviceId,
      feature.rms,
      feature.vpp,
      feature.max,
      feature.min,
      feature.mean,
      feature.arv,
      feature.peak,
      feature.variance,
      feature.stdDev,
      feature.msa,
      feature.crestFactor,
      feature.kurtosis,
      feature.formFactor,
      feature.skewness,
      feature.pulseFactor,
      feature.clearanceFactor,
    ];

    return await _dbUtils.insert(sql, params);
  }

  Future<List<Feature>> getFeaturesByHistoryId(int historyId) async {
    final sql = 'SELECT * FROM features WHERE historyId = ?';
    final maps = await _dbUtils.query(sql, [historyId]);
    return maps.map(Feature.fromMap).toList();
  }

  Future<List<Feature>> getFeaturesByDevice(String deviceId) async {
    final sql = 'SELECT * FROM features WHERE deviceId = ?';
    final maps = await _dbUtils.query(sql, [deviceId]);
    return maps.map(Feature.fromMap).toList();
  }

  Future<int> updateFeature(Feature feature) async {
    final sql = '''
      UPDATE features SET
        rms = ?, vpp = ?, max = ?, min = ?, mean = ?,
        arv = ?, peak = ?, variance = ?, stdDev = ?,
        msa = ?, crestFactor = ?, kurtosis = ?, formFactor = ?,
        skewness = ?, pulseFactor = ?, clearanceFactor = ?
      WHERE id = ?
    ''';

    final params = [
      feature.rms,
      feature.vpp,
      feature.max,
      feature.min,
      feature.mean,
      feature.arv,
      feature.peak,
      feature.variance,
      feature.stdDev,
      feature.msa,
      feature.crestFactor,
      feature.kurtosis,
      feature.formFactor,
      feature.skewness,
      feature.pulseFactor,
      feature.clearanceFactor,
      feature.id,
    ];

    return await _dbUtils.update(sql, params);
  }

  Future<int> deleteFeature(int id) async {
    final sql = 'DELETE FROM features WHERE id = ?';
    return await _dbUtils.delete(sql, [id]);
  }

  Future<List<FeatureWithHistory>> getFeaturesWithHistory(
    int page,
    int limit,
  ) async {
    final offset = (page - 1) * limit;
    final sql = '''
      SELECT f.*, h.dataTime, h.samplingRate, h.rotationSpeed
      FROM features f
      JOIN history h ON f.historyId = h.id
      LIMIT ? OFFSET ?
    ''';

    final maps = await _dbUtils.query(sql, [limit, offset]);
    return maps.map((map) {
      return FeatureWithHistory(
        feature: Feature.fromMap(map),
        dataTime: DateTime.parse(map['dataTime']),
        samplingRate: map['samplingRate'] as int,
        rotationSpeed: map['rotationSpeed'] as double,
      );
    }).toList();
  }
}

class FeatureWithHistory {
  final Feature feature;
  final DateTime dataTime;
  final int samplingRate;
  final double rotationSpeed;

  FeatureWithHistory({
    required this.feature,
    required this.dataTime,
    required this.samplingRate,
    required this.rotationSpeed,
  });
}
