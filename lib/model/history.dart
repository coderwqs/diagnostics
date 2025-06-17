class History {
  final int id;
  final String deviceId;
  final int dataTime;
  final double samplingRate;
  final int? rotationSpeed;
  final List<double> data;
  final int createdAt;

  History({
    required this.id,
    required this.deviceId,
    required this.dataTime,
    required this.samplingRate,
    this.rotationSpeed,
    required this.data,
    required this.createdAt,
  });

  factory History.fromMap(Map<String, dynamic> map) {
    return History(
      id: map['id'],
      deviceId: map['deviceId'],
      dataTime: map['dataTime'],
      samplingRate: map['samplingRate'],
      rotationSpeed: map['rotationSpeed'],
      data: List<double>.from((map['data'] as List).map((x) => x.toDouble())),
      createdAt: map['createdAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'deviceId': deviceId,
      'dataTime': dataTime,
      'samplingRate': samplingRate,
      'rotationSpeed': rotationSpeed,
      'data': data,
      'createdAt': createdAt,
    };
  }
}