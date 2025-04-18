class PuduRobot {
  // Basic information
  final int? id;
  final String name;
  final String type;

  // Device information
  final String ip;
  final String idDevice;
  final String secretDevice;
  final String region;

  // Group information
  final String idGroup;
  final String groupName;
  final String shopName;

  // Robot specific information
  final String robotIdd;
  final String nameRobot;

  // Constructor
  const PuduRobot({
    this.id,
    required this.name,
    required this.type,
    required this.ip,
    required this.idDevice,
    required this.secretDevice,
    required this.region,
    this.idGroup = '',
    this.groupName = '',
    this.shopName = '',
    this.robotIdd = '',
    this.nameRobot = '',
  });

  // Create from Map
  factory PuduRobot.fromMap(Map<String, dynamic> map) {
    return PuduRobot(
      id: map['id'] != null 
          ? (map['id'] is String 
              ? int.parse(map['id']) 
              : map['id'] as int)
          : null,
      name: map['name'] as String,
      type: map['type'] as String,
      ip: map['ip'] as String,
      idDevice: map['idDevice'] as String,
      secretDevice: map['secretDevice'] as String,
      region: map['region'] as String,
      idGroup: (map['idGroup'] as String?) ?? '',
      groupName: (map['groupName'] as String?) ?? '',
      shopName: (map['shopName'] as String?) ?? '',
      robotIdd: (map['robotIdd'] as String?) ?? '',
      nameRobot: (map['nameRobot'] as String?) ?? '',
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id.toString(),
      'name': name,
      'type': type,
      'ip': ip,
      'idDevice': idDevice,
      'secretDevice': secretDevice,
      'region': region,
      'idGroup': idGroup,
      'groupName': groupName,
      'shopName': shopName,
      'robotIdd': robotIdd,
      'nameRobot': nameRobot,
    };
  }

  // Copy with
  PuduRobot copyWith({
    int? id,
    String? name,
    String? type,
    String? ip,
    String? idDevice,
    String? secretDevice,
    String? region,
    String? idGroup,
    String? groupName,
    String? shopName,
    String? robotIdd,
    String? nameRobot,
  }) {
    return PuduRobot(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      ip: ip ?? this.ip,
      idDevice: idDevice ?? this.idDevice,
      secretDevice: secretDevice ?? this.secretDevice,
      region: region ?? this.region,
      idGroup: idGroup ?? this.idGroup,
      groupName: groupName ?? this.groupName,
      shopName: shopName ?? this.shopName,
      robotIdd: robotIdd ?? this.robotIdd,
      nameRobot: nameRobot ?? this.nameRobot,
    );
  }

  // String representation
  @override
  String toString() {
    return 'PuduRobot(name: $name, type: $type, ip: $ip)';
  }

  // Equality
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PuduRobot &&
        other.id == id &&
        other.name == name &&
        other.type == type &&
        other.ip == ip &&
        other.idDevice == idDevice &&
        other.secretDevice == secretDevice &&
        other.region == region &&
        other.idGroup == idGroup &&
        other.groupName == groupName &&
        other.shopName == shopName &&
        other.robotIdd == robotIdd &&
        other.nameRobot == nameRobot;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      type,
      ip,
      idDevice,
      secretDevice,
      region,
      idGroup,
      groupName,
      shopName,
      robotIdd,
      nameRobot,
    );
  }
} 