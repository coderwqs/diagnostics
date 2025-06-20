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
      data: map['data'] != null
          ? List<double>.from(jsonDecode(map['data']).map((x) => x.toDouble()))
          : [],
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
      'data': jsonEncode(data),
      'createdAt': createdAt,
    };
  }
}

class ExtendedHistory extends History {
  String? deviceName;

  ExtendedHistory({
    required super.id,
    required super.deviceId,
    required super.dataTime,
    required super.samplingRate,
    super.rotationSpeed,
    required super.data,
    required super.createdAt,
    this.deviceName,
  });

  factory ExtendedHistory.fromMap(Map<String, dynamic> map) {
    return ExtendedHistory(
      id: map['id'],
      deviceId: map['deviceId'],
      dataTime: map['dataTime'],
      samplingRate: map['samplingRate'],
      rotationSpeed: map['rotationSpeed'],
      data: map['data'] != null
          ? List<double>.from(jsonDecode(map['data']).map((x) => x.toDouble()))
          : [],
      createdAt: map['createdAt'],
      deviceName: map['deviceName'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map['deviceName'] = deviceName;
    return map;
  }
}
