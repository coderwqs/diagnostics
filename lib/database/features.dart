import 'package:diagnosis/model/features.dart';
import 'package:diagnosis/utils/database.dart';

/// 特征数据数据库操作类
class FeaturesDatabase {
  static const String _tableName = 'features';
  final DatabaseUtils _dbUtils = DatabaseUtils();

  /// 插入特征数据
  Future<int> insertFeature(Feature feature) async {
    const sql =
        '''
      INSERT INTO $_tableName (
        deviceId, dataTime, rms, vpp, max, min, mean, arv, peak,
        variance, stdDev, msa, crestFactor, kurtosis, formFactor,
        skewness, pulseFactor, clearanceFactor, createdAt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';

    return await _dbUtils.insert(sql, [
      feature.deviceId,
      feature.dataTime,
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
      feature.createdAt ?? DateTime.now().millisecondsSinceEpoch,
    ]);
  }

  /// 批量插入特征数据
  Future<void> batchInsertFeatures(List<Feature> features) async {
    const sql =
        '''
      INSERT INTO $_tableName (
        deviceId, dataTime, rms, vpp, max, min, mean, arv, peak,
        variance, stdDev, msa, crestFactor, kurtosis, formFactor,
        skewness, pulseFactor, clearanceFactor, createdAt
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''';

    await _dbUtils.batchInsert(
      sql,
      features
          .map(
            (feature) => [
              feature.deviceId,
              feature.dataTime,
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
              feature.createdAt ?? DateTime.now().millisecondsSinceEpoch,
            ],
          )
          .toList(),
    );
  }

  /// 根据historyId获取特征数据
  Future<List<Feature>> getFeaturesByHistoryId(int historyId) async {
    final sql =
        'SELECT * FROM $_tableName WHERE historyId = ? ORDER BY dataTime DESC';
    final maps = await _dbUtils.query(sql, [historyId]);
    return maps.map(Feature.fromMap).toList();
  }

  /// 根据设备ID获取特征数据
  Future<List<Feature>> getFeaturesByDevice(
    String deviceId, {
    int? limit,
  }) async {
    final params = <dynamic>[deviceId];
    var sql =
        'SELECT * FROM $_tableName WHERE deviceId = ? ORDER BY dataTime DESC';

    if (limit != null) {
      sql += ' LIMIT ?';
      params.add(limit);
    }

    final maps = await _dbUtils.query(sql, params);
    return maps.map(Feature.fromMap).toList();
  }

  /// 更新特征数据
  Future<int> updateFeature(Feature feature) async {
    const sql =
        '''
      UPDATE $_tableName SET
        rms = ?, vpp = ?, max = ?, min = ?, mean = ?,
        arv = ?, peak = ?, variance = ?, stdDev = ?,
        msa = ?, crestFactor = ?, kurtosis = ?, formFactor = ?,
        skewness = ?, pulseFactor = ?, clearanceFactor = ?
      WHERE id = ?
    ''';

    return await _dbUtils.update(sql, [
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
    ]);
  }

  /// 删除特征数据
  Future<int> deleteFeature(int id) async {
    final sql = 'DELETE FROM $_tableName WHERE id = ?';
    return await _dbUtils.delete(sql, [id]);
  }

  /// 根据historyId删除特征数据
  Future<int> deleteFeaturesByHistoryId(int historyId) async {
    final sql = 'DELETE FROM $_tableName WHERE historyId = ?';
    return await _dbUtils.delete(sql, [historyId]);
  }

  /// 获取带历史记录的特征数据（分页）
  Future<List<Feature>> getFeatures({
    required int page,
    required int limit,
    String? deviceId,
    int? startTime,
    int? endTime,
  }) async {
    final offset = (page - 1) * limit;
    final whereClauses = <String>[];
    final params = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('deviceId = ?');
      params.add(deviceId);
    }

    if (startTime != null) {
      whereClauses.add('dataTime >= ?');
      params.add(startTime);
    }

    if (endTime != null) {
      whereClauses.add('dataTime <= ?');
      params.add(endTime);
    }

    final where = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final sql =
        '''
      SELECT *
      FROM $_tableName
      $where
      ORDER BY dataTime DESC
      LIMIT ? OFFSET ?
    ''';

    params.addAll([limit, offset]);

    final maps = await _dbUtils.query(sql, params);
    return maps.map((map) => Feature.fromMap(map)).toList();
  }

  /// 获取带历史记录的特征数据（分页）
  Future<List<FeatureWithHistory>> getFeaturesWithHistory({
    required int page,
    required int limit,
    String? deviceId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    final offset = (page - 1) * limit;
    final whereClauses = <String>[];
    final params = <dynamic>[];

    if (deviceId != null) {
      whereClauses.add('f.deviceId = ?');
      params.add(deviceId);
    }

    if (startTime != null) {
      whereClauses.add('f.dataTime >= ?');
      params.add(startTime.millisecondsSinceEpoch);
    }

    if (endTime != null) {
      whereClauses.add('f.dataTime <= ?');
      params.add(endTime.millisecondsSinceEpoch);
    }

    final where = whereClauses.isNotEmpty
        ? 'WHERE ${whereClauses.join(' AND ')}'
        : '';

    final sql =
        '''
      SELECT f.*, h.samplingRate, h.rotationSpeed
      FROM $_tableName f
      JOIN history h ON f.historyId = h.id
      $where
      ORDER BY f.dataTime DESC
      LIMIT ? OFFSET ?
    ''';

    params.addAll([limit, offset]);

    final maps = await _dbUtils.query(sql, params);
    return maps.map((map) {
      return FeatureWithHistory(
        feature: Feature.fromMap(map),
        samplingRate: map['samplingRate'] as int,
        rotationSpeed: (map['rotationSpeed'] as num).toDouble(),
      );
    }).toList();
  }

  /// 获取特征数据数量
  Future<int> getFeatureCount({String? deviceId}) async {
    final where = deviceId != null ? 'WHERE deviceId = ?' : '';
    final sql = 'SELECT COUNT(*) as count FROM $_tableName $where';
    final params = deviceId != null ? [deviceId] : [];

    final result = await _dbUtils.query(sql, params);
    return result.first['count'] as int;
  }
}
