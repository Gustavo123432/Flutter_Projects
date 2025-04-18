class PuduRobot {
  final int? id;
  final String ip;
  final String idDevice;
  final String name;
  final String secretDevice;
  final String region;
  final String type;

  PuduRobot({
    this.id,
    required this.ip,
    required this.idDevice,
    required this.name,
    required this.secretDevice,
    required this.region,
    required this.type,
  });

  factory PuduRobot.fromMap(Map<String, dynamic> map) {
    return PuduRobot(
      id: map['id'] as int?,
      ip: map['ip'] as String,
      idDevice: map['idDevice'] as String,
      name: map['name'] as String,
      secretDevice: map['secretDevice'] as String,
      region: map['region'] as String,
      type: map['type'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'ip': ip,
      'idDevice': idDevice,
      'name': name,
      'secretDevice': secretDevice,
      'region': region,
      'type': type,
    };
  }

  PuduRobot copyWith({
    int? id,
    String? ip,
    String? idDevice,
    String? name,
    String? secretDevice,
    String? region,
    String? type,
  }) {
    return PuduRobot(
      id: id ?? this.id,
      ip: ip ?? this.ip,
      idDevice: idDevice ?? this.idDevice,
      name: name ?? this.name,
      secretDevice: secretDevice ?? this.secretDevice,
      region: region ?? this.region,
      type: type ?? this.type,
    );
  }
} 