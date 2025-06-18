import 'dart:convert';

class History {
  int id;
  String deviceId;
  int dataTime;
  double samplingRate;
  int? rotationSpeed;
  List<double> data;
  int createdAt;

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
      data: List<double>.from(jsonDecode(map['data']).map((x) => x.toDouble())),
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
      // 将List<double>转换为JSON字符串
      'data': jsonEncode(data),
      'createdAt': createdAt,
    };
  }
}
