class UsersModel {
  UsersModel({
    String email = "",
    String nome = "",
    String apelido = "",
    String permissao = "",
    String turma = "",
    String idUser = "",
    String estado = "",
  }) {
    _email = email;
    _nome = nome;
    _apelido = apelido;
    _permissao = permissao;
    _turma = turma;
    _idUser = idUser;
    _estado = estado;
  }

  UsersModel.fromJson(dynamic json) {
    _email = json['Email'];
    _nome = json['Nome'];
    _apelido = json['Apelido'];
    _permissao = json['Permissao'];
    _turma = json['Turma'];
    _idUser = json['IdUser'];
    _estado = json['Estado'];
  }
  String _email = "";
  String _nome = "";
  String _apelido = "";
  String _permissao = "";
  String _turma = "";
  String _idUser = "";
  String _estado = "";

  String get email => _email;
  String get nome => _nome;
  String get apelido => _apelido;
  String get permissao => _permissao;
  String get turma => _turma;
  String get idUser => _idUser;
  String get estado => _estado;

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    map['Email'] = _email;
    map['Nome'] = _nome;
    map['Apelido'] = _apelido;
    map['Permissao'] = _permissao;
    map['Turma'] = _turma;
    map['IdUser'] = _idUser;
    map['Estado'] = _estado;
    return map;
  }
}
