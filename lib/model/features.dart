class Feature {
  final int? id;         // 自增主键，插入时可为null
  final int historyId;   // 关联的history表ID
  final String deviceId; // 设备标识

  // 公共特征
  final double rms;      // 均方根值
  final double vpp;      // 峰峰值

  // 加速度特征
  final double max;
  final double min;
  final double mean;
  final double arv;
  final double peak;
  final double variance;
  final double stdDev;
  final double msa;
  final double crestFactor;
  final double kurtosis;
  final double formFactor;
  final double skewness;
  final double pulseFactor;
  final double clearanceFactor;

  Feature({
    this.id,
    required this.historyId,
    required this.deviceId,
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
  });

  factory Feature.fromMap(Map<String, dynamic> map) {
    return Feature(
      id: map['id'] as int?,
      historyId: map['historyId'] as int,
      deviceId: map['deviceId'] as String,
      rms: map['rms'] as double,
      vpp: map['vpp'] as double,
      max: map['max'] as double,
      min: map['min'] as double,
      mean: map['mean'] as double,
      arv: map['arv'] as double,
      peak: map['peak'] as double,
      variance: map['variance'] as double,
      stdDev: map['stdDev'] as double,
      msa: map['msa'] as double,
      crestFactor: map['crestFactor'] as double,
      kurtosis: map['kurtosis'] as double,
      formFactor: map['formFactor'] as double,
      skewness: map['skewness'] as double,
      pulseFactor: map['pulseFactor'] as double,
      clearanceFactor: map['clearanceFactor'] as double,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'historyId': historyId,
      'deviceId': deviceId,
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
    };
  }
}