import 'dart:convert';

import 'package:diagnosis/l10n/app_localizations.dart';
import 'package:flutter/cupertino.dart';

enum DeviceStatus { online, offline, warning }

extension DeviceStatusExtension on DeviceStatus {
  String get value {
    return this.toString().split('.').last;
  }
}

enum MachineType {
  motor, // 电机
  pump, // 泵
  airCompressor, // 空压机
  inverter, // 变频器
  fan, // 风机
}

extension MachineTypeExtension on MachineType {
  String get value {
    return this.toString().split('.').last;
  }

  String displayName(BuildContext context) {
    AppLocalizations l10n = AppLocalizations.of(context)!;
    switch (this) {
      case MachineType.motor:
        return l10n.devices_motor;
      case MachineType.pump:
        return l10n.devices_pump;
      case MachineType.airCompressor:
        return l10n.devices_air_compressor;
      case MachineType.inverter:
        return l10n.devices_inverter;
      case MachineType.fan:
        return l10n.devices_fan;
      default:
        return '';
    }
  }
}

class Credentials {
  final String identity;
  final String secret;

  Credentials({required this.identity, required this.secret});

  factory Credentials.fromJson(Map<String, dynamic> json) {
    return Credentials(identity: json['identity'], secret: json['secret']);
  }

  Map<String, dynamic> toJson() {
    return {'identity': identity, 'secret': secret};
  }
}

class Device {
  String id;
  String name;
  List<int> image;
  MachineType type;
  String identity;
  String secret;
  DeviceStatus status;
  int lastActive;
  int createdAt;

  Device({
    this.id = '',
    this.name = '',
    this.image = const [],
    this.type = MachineType.motor,
    this.identity = '',
    this.secret = '',
    this.status = DeviceStatus.offline,
    this.lastActive = 0,
    this.createdAt = 0,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'] ?? '',
      image: json['image'] is String
          ? List<int>.from(
              jsonDecode(json['image']).map((item) => item is int ? item : 0),
            )
          : [],
      type: MachineType.values.firstWhere(
        (e) => e.value == json['type'],
        orElse: () => MachineType.motor,
      ),
      identity: json['identity'] ?? '',
      secret: json['secret'] ?? '',
      status: DeviceStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => DeviceStatus.offline,
      ),
      lastActive: json['lastActive'] ?? 0,
      createdAt: json['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'type': type.value,
      'identity': identity,
      'secret': secret,
      'status': status.value,
      'lastActive': lastActive,
      'createdAt': createdAt,
    };
  }

  Device copyWith({
    String? id,
    String? name,
    List<int>? image,
    MachineType? type,
    String? identity,
    String? secret,
    DeviceStatus? status,
    int? lastActive,
    int? createdAt,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      type: type ?? this.type,
      identity: identity ?? this.identity,
      secret: secret ?? this.secret,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
