import 'package:diagnosis/database/features.dart';
import 'package:diagnosis/model/features.dart';

class FeaturesService {
  final FeaturesDatabase _featuresDatabase = FeaturesDatabase();

  /// 添加特征数据（自动处理时间戳）
  Future<int> addFeature(Feature feature) async {
    try {
      if (feature.createdAt == 0) {
        feature.createdAt = DateTime.now().millisecondsSinceEpoch;
      }

      return await _featuresDatabase.insertFeature(feature);
    } catch (e) {
      throw Exception('Failed to add feature: ${e.toString()}');
    }
  }

  /// 批量添加特征数据
  Future<void> addFeatures(List<Feature> features) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final featuresToSave = features
          .map(
            (f) => Feature(
              deviceId: f.deviceId,
              dataTime: f.dataTime ?? timestamp,
              rms: f.rms,
              vpp: f.vpp,
              max: f.max,
              min: f.min,
              mean: f.mean,
              arv: f.arv,
              peak: f.peak,
              variance: f.variance,
              stdDev: f.stdDev,
              msa: f.msa,
              crestFactor: f.crestFactor,
              kurtosis: f.kurtosis,
              formFactor: f.formFactor,
              skewness: f.skewness,
              pulseFactor: f.pulseFactor,
              clearanceFactor: f.clearanceFactor,
              createdAt: f.createdAt ?? timestamp,
            ),
          )
          .toList();

      await _featuresDatabase.batchInsertFeatures(featuresToSave);
    } catch (e) {
      throw Exception('Failed to batch add features: ${e.toString()}');
    }
  }

  /// 获取所有历史记录（分页）
  Future<List<FeatureWithHistory>> getAllFeaturesWithHistory({
    required int page,
    required int limit,
    String? deviceId,
    DateTime? startTime,
    DateTime? endTime,
  }) async {
    try {
      return await _featuresDatabase.getFeaturesWithHistory(
        page: page,
        limit: limit,
        deviceId: deviceId,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      throw Exception('Failed to get histories: ${e.toString()}');
    }
  }

  Future<List<Feature>> getAllFeatures({
    required int page,
    required int limit,
    String? deviceId,
    int? startTime,
    int? endTime,
  }) async {
    try {
      return await _featuresDatabase.getFeatures(
        page: page,
        limit: limit,
        deviceId: deviceId,
        startTime: startTime,
        endTime: endTime,
      );
    } catch (e) {
      throw Exception('Failed to get histories: ${e.toString()}');
    }
  }

  /// 更新历史记录
  Future<void> updateFeature(Feature feature) async {
    try {
      await _featuresDatabase.updateFeature(feature);
    } catch (e) {
      throw Exception('Failed to update feature: ${e.toString()}');
    }
  }

  /// 删除历史记录
  Future<void> deleteFeature(int id) async {
    try {
      await _featuresDatabase.deleteFeature(id);
    } catch (e) {
      throw Exception('Failed to delete feature: ${e.toString()}');
    }
  }
}

// 扩展List<double>计算平均值
extension _ListDoubleExtension on List<double> {
  double average() => isEmpty ? 0 : reduce((a, b) => a + b) / length;
}
