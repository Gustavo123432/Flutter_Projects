class PuduRobot {
  final int id;
  final String ip;
  final String idDevice;
  final String name;
  final String secretDevice;
  final String region;
  final String type;
  final String idGroup;
  final String groupName;
  final String shopName;
  final String robotIdd;
  final String nameRobot;

  PuduRobot._({
    required this.id,
    required this.ip,
    required this.idDevice,
    required this.name,
    required this.secretDevice,
    required this.region,
    required this.type,
    required this.idGroup,
    required this.groupName,
    required this.shopName,
    required this.robotIdd,
    required this.nameRobot,
  });

  factory PuduRobot({
    int? id,
    required String ip,
    required String idDevice,
    required String name,
    required String secretDevice,
    required String region,
    required String type,
    required String idGroup,
    required String groupName,
    required String shopName,
    required String robotIdd,
    required String nameRobot,
  }) {
    return PuduRobot._(
      id: id ?? -1,
      ip: ip,
      idDevice: idDevice,
      name: name,
      secretDevice: secretDevice,
      region: region,
      type: type,
      idGroup: idGroup,
      groupName: groupName,
      shopName: shopName,
      robotIdd: robotIdd,
      nameRobot: nameRobot,
    );
  }

  factory PuduRobot.fromMap(Map<String, dynamic> map) {
    return PuduRobot._(
      id: (map['id'] is String) ? int.parse(map['id']) : map['id'] as int,
      ip: map['ip'] as String,
      idDevice: map['idDevice'] as String,
      name: map['name'] as String,
      secretDevice: map['secretDevice'] as String,
      region: map['region'] as String,
      type: map['type'] as String,
      idGroup: map['idGroup'] as String,
      groupName: map['groupName'] as String,
      shopName: map['shopName'] as String,
      robotIdd: map['robotIdd'] as String,
      nameRobot: map['nameRobot'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    final map = {
      'ip': ip,
      'idDevice': idDevice,
      'name': name,
      'secretDevice': secretDevice,
      'region': region,
      'type': type,
      'idGroup': idGroup,
      'groupName': groupName,
      'shopName': shopName,
      'robotIdd': robotIdd,
      'nameRobot': nameRobot,
    };
    
    if (id != -1) {
      map['id'] = id.toString();
      }
    
    return map;
  }

  PuduRobot copyWith({
    int? id,
    String? ip,
    String? idDevice,
    String? name,
    String? secretDevice,
    String? region,
    String? type,
    String? idGroup,
    String? groupName,
    String? shopName,
    String? robotIdd,
    String? nameRobot,
  }) {
    return PuduRobot._(
      id: id ?? this.id,
      ip: ip ?? this.ip,
      idDevice: idDevice ?? this.idDevice,
      name: name ?? this.name,
      secretDevice: secretDevice ?? this.secretDevice,
      region: region ?? this.region,
      type: type ?? this.type,
      idGroup: idGroup ?? this.idGroup,
      groupName: groupName ?? this.groupName,
      shopName: shopName ?? this.shopName,
      robotIdd: robotIdd ?? this.robotIdd,
      nameRobot: nameRobot ?? this.nameRobot,
    );
  }
} 