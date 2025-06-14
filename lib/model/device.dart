enum DeviceStatus { online, offline, warning }

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
  final String id;
  final String name;
  final String image;
  final String type;
  final String identity;
  final String secret;
  final DeviceStatus status;
  final int lastActive;
  final int createdAt;

  Device({
    required this.id,
    required this.name,
    required this.image,
    required this.type,
    required this.identity,
    required this.secret,
    required this.status,
    required this.lastActive,
    required this.createdAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'],
      name: json['name'],
      image: json['image'],
      type: json['type'],
      identity: json['identity'],
      secret: json['secret'],
      status: DeviceStatus.values.firstWhere(
            (e) => e.toString() == 'DeviceStatus.${json['status']}',
      ),
      lastActive: json['lastActive'],
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image': image,
      'type': type,
      'identity': identity,
      'secret': secret,
      'status': status.toString().split('.').last,
      'lastActive': lastActive,
      'createdAt': createdAt,
    };
  }

  Device copyWith({
    String? id,
    String? name,
    String? image,
    String? type,
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