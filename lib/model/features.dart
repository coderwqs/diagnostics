import 'dart:math';

/// 表示从波形数据中提取的特征集合
/// 所有时间字段使用时间戳（毫秒级）存储
class Feature {
  // 数据库相关字段
  final int? id; // 自增主键，插入时可为null
  String? deviceId; // 设备标识
  int? dataTime; // 数据时间（时间戳毫秒）
  int? createdAt; // 创建时间（时间戳毫秒）

  // 公共特征
  final double rms; // 均方根值
  final double vpp; // 峰峰值

  // 统计特征
  final double max;
  final double min;
  final double mean;
  final double arv; // 绝对平均值
  final double peak; // 最大绝对值
  final double variance;
  final double stdDev;
  final double msa; // 平均平方幅值

  // 形状特征因子
  final double crestFactor; // 波峰因数
  final double kurtosis; // 峰度
  final double formFactor; // 波形因数
  final double skewness; // 偏度
  final double pulseFactor; // 脉冲因数
  final double clearanceFactor; // 裕度因数

  /// 构造函数
  Feature({
    this.id,
    this.deviceId,
    this.dataTime,
    required this.rms,
    required this.vpp,
    required this.max,
    required this.min,
    required this.mean,
    required this.arv,
    required this.peak,
    required this.variance,
    required this.stdDev,
    required this.msa,
    required this.crestFactor,
    required this.kurtosis,
    required this.formFactor,
    required this.skewness,
    required this.pulseFactor,
    required this.clearanceFactor,
    int? createdAt,
  }) : createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch;

  /// 从数据库Map创建Feature
  factory Feature.fromMap(Map<String, dynamic> map) {
    return Feature(
      id: map['id'] as int?,
      deviceId: map['deviceId'] as String?,
      dataTime: map['dataTime'] as int?,
      rms: (map['rms'] as num).toDouble(),
      vpp: (map['vpp'] as num).toDouble(),
      max: (map['max'] as num).toDouble(),
      min: (map['min'] as num).toDouble(),
      mean: (map['mean'] as num).toDouble(),
      arv: (map['arv'] as num).toDouble(),
      peak: (map['peak'] as num).toDouble(),
      variance: (map['variance'] as num).toDouble(),
      stdDev: (map['stdDev'] as num).toDouble(),
      msa: (map['msa'] as num).toDouble(),
      crestFactor: (map['crestFactor'] as num).toDouble(),
      kurtosis: (map['kurtosis'] as num).toDouble(),
      formFactor: (map['formFactor'] as num).toDouble(),
      skewness: (map['skewness'] as num).toDouble(),
      pulseFactor: (map['pulseFactor'] as num).toDouble(),
      clearanceFactor: (map['clearanceFactor'] as num).toDouble(),
      createdAt: map['createdAt'] as int?,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'deviceId': deviceId,
      'dataTime': dataTime,
      'rms': rms,
      'vpp': vpp,
      'max': max,
      'min': min,
      'mean': mean,
      'arv': arv,
      'peak': peak,
      'variance': variance,
      'stdDev': stdDev,
      'msa': msa,
      'crestFactor': crestFactor,
      'kurtosis': kurtosis,
      'formFactor': formFactor,
      'skewness': skewness,
      'pulseFactor': pulseFactor,
      'clearanceFactor': clearanceFactor,
      'createdAt': createdAt,
    };
  }

  /// 从波形数据计算特征
  static Feature calculateFeatures({
    required List<double> waveform,
  }) {
    if (waveform.isEmpty) {
      throw ArgumentError('Waveform data cannot be empty');
    }

    // 计算基本统计量
    final max = waveform.reduce((a, b) => a > b ? a : b);
    final min = waveform.reduce((a, b) => a < b ? a : b);
    final vpp = max - min;
    final mean = waveform.average();
    final peak = max.abs().clamp(min.abs(), double.infinity);

    // 预计算常用值
    final length = waveform.length.toDouble();
    final squaredDifferences = waveform.map((value) {
      final diff = value - mean;
      return (diff: diff, squared: diff * diff);
    }).toList();

    // 计算各种和
    final sumOfSquares = squaredDifferences.fold(
        0.0, (sum, item) => sum + item.squared);
    final sumOfAbs = waveform.fold(0.0, (sum, value) => sum + value.abs());
    final sumOfCubedDifferences = squaredDifferences.fold(
        0.0, (sum, item) => sum + item.squared * item.diff);
    final sumOfFourthPowerDifferences = squaredDifferences.fold(
        0.0, (sum, item) => sum + item.squared * item.squared);

    // 计算派生特征
    final variance = sumOfSquares / length;
    final stdDev = sqrt(variance);
    final rms = sqrt(sumOfSquares / length);
    final arv = sumOfAbs / length;
    final msa = sumOfSquares / length;
    final crestFactor = peak / rms;
    final formFactor = rms / arv;
    final pulseFactor = peak / arv;
    final clearanceFactor = peak / msa;

    // 计算高阶统计量
    final skewnessDenominator = pow(stdDev, 3);
    final skewness = skewnessDenominator != 0
        ? (sumOfCubedDifferences / length) / skewnessDenominator
        : 0.0;

    final kurtosisDenominator = pow(variance, 2);
    final kurtosis = kurtosisDenominator != 0
        ? (sumOfFourthPowerDifferences / length) / kurtosisDenominator - 3
        : 0.0;

    return Feature(
      rms: rms,
      vpp: vpp,
      max: max,
      min: min,
      mean: mean,
      arv: arv,
      peak: peak,
      variance: variance,
      stdDev: stdDev,
      msa: msa,
      crestFactor: crestFactor,
      kurtosis: kurtosis,
      formFactor: formFactor,
      skewness: skewness,
      pulseFactor: pulseFactor,
      clearanceFactor: clearanceFactor,
    );
  }

  @override
  String toString() {
    return 'Feature(rms: $rms, vpp: $vpp, max: $max, min: $min, mean: $mean, '
        'peak: $peak, stdDev: $stdDev, kurtosis: $kurtosis)';
  }

  /// 获取DateTime格式的dataTime（可选）
  DateTime? get dataDateTime =>
      dataTime != null ? DateTime.fromMillisecondsSinceEpoch(dataTime!) : null;

  /// 获取DateTime格式的createdAt（可选）
  DateTime? get createdDateTime =>
      createdAt != null ? DateTime.fromMillisecondsSinceEpoch(createdAt!) : null;
}

/// 扩展List<double>以添加平均值计算方法
extension Average on List<double> {
  double average() {
    if (isEmpty) return 0;
    return reduce((a, b) => a + b) / length;
  }
}

/// 带历史记录信息的特征数据
class FeatureWithHistory {
  final Feature feature;
  final int samplingRate;
  final double rotationSpeed;

  FeatureWithHistory({
    required this.feature,
    required this.samplingRate,
    required this.rotationSpeed,
  });

  /// 获取DateTime格式的数据时间
  DateTime? get dataTime => feature.dataDateTime;

  @override
  String toString() {
    return 'FeatureWithHistory(feature: $feature, '
        'samplingRate: $samplingRate, rotationSpeed: $rotationSpeed)';
  }
}