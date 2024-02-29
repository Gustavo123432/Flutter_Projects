import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:Calldo/Admin/Add_Registo.dart';
import 'package:Calldo/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Calldo/Drawer/drawerMain.dart';

class Registo extends StatefulWidget {
  @override
  _RegistoState createState() => _RegistoState();
}

class _RegistoState extends State<Registo> {
  dynamic users;
  List<dynamic> tableUsers = [];
  bool isEditing = false;
  List<dynamic> perfil = [];
  List<String> _perfil = [];
  List<String> _local = [];
  List<dynamic> local = [];
  List<String> _ccp = [];
  List<dynamic> ccp = [];
  List<dynamic> tecnico = [];

  // Mapa para armazenar os controladores de texto para cada linha da tabela
  Map<int, TextEditingController> dataControllers = {};
  Map<int, TextEditingController> horaIControllers = {};
  Map<int, TextEditingController> horaFControllers = {};
  Map<int, TextEditingController> perfilControllers = {};
  Map<int, TextEditingController> localControllers = {};
  Map<int, TextEditingController> Centro_Custo_ProjetoControllers = {};
  Map<int, TextEditingController> descricaoControllers = {};

  @override
  void initState() {
    UserInfo();
    _getTableData();
    getLocal();
    getPerfil();
    getTecnico();
    getCCP();
    super.initState();
  }

  void _toggleEditMode() {
    setState(() {
      isEditing = true;
    });
  }

  // Função para buscar informações do usuário
  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://services.interagit.com/registarCallAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    }
  }

  // Função para buscar dados da tabela de usuários
  Future<void> _getTableData() async {
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=6'));

    if (response.statusCode == 200) {
      setState(() {
        tableUsers = json.decode(response.body);
      });
    }
  }

  void getPerfil() async {
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=10'));

    if (response.statusCode == 200) {
      setState(() {
        perfil = json.decode(response.body);
      });
      _perfil = perfil.map((item) => item.toString()).toList();
    }
  }

  void getCCP() async {
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=13'));

    if (response.statusCode == 200) {
      setState(() {
        ccp = json.decode(response.body);
      });
      _ccp = ccp.map((item) => item.toString()).toList();
    }
  }

  void getLocal() async {
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=11'));

    if (response.statusCode == 200) {
      setState(() {
        local = json.decode(response.body);
      });
      _local = local.map((item) => item.toString()).toList();
    }
  }

  void getTecnico() async {
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=12'));

    if (response.statusCode == 200) {
      setState(() {
        tecnico = json.decode(response.body);
      });
    }
  }

  // Função para criar e retornar um controlador de texto para a data do registro
  TextEditingController? getDataController(int index, String data) {
    dataControllers[index] ??= TextEditingController(text: data);
    return dataControllers[index];
  }

  // Função para criar e retornar um controlador de texto para a hora de início do registro
  TextEditingController? getHoraIController(int index, String horaI) {
    horaIControllers[index] ??= TextEditingController(text: horaI);
    return horaIControllers[index];
  }

  // Função para criar e retornar um controlador de texto para a hora de fim do registro
  TextEditingController? getHoraFController(int index, String horaF) {
    horaFControllers[index] ??= TextEditingController(text: horaF);
    return horaFControllers[index];
  }

  // Função para criar e retornar um controlador de texto para o perfil do registro
  TextEditingController? getPerfilController(int index, String perfil) {
    perfilControllers[index] ??= TextEditingController(text: perfil);
    return perfilControllers[index];
  }

  // Função para criar e retornar um controlador de texto para o local do registro
  TextEditingController? getLocalController(int index, String local) {
    localControllers[index] ??= TextEditingController(text: local);
    return localControllers[index];
  }

  // Função para criar e retornar um controlador de texto para o centro de custo/projeto do registro
  TextEditingController? getCentro_Custo_ProjetoController(
      int index, String Centro_Custo_Projeto) {
    Centro_Custo_ProjetoControllers[index] ??=
        TextEditingController(text: Centro_Custo_Projeto);
    return Centro_Custo_ProjetoControllers[index];
  }

  // Função para criar e retornar um controlador de texto para a descrição do registro
  TextEditingController? getDescricaoController(int index, String descricao) {
    descricaoControllers[index] ??= TextEditingController(text: descricao);
    return descricaoControllers[index];
  }

  // Função para formatar a hora no formato 'HH:MM:SS'
  String formatarHora(String hora) {
    List<String> partes = hora.split(':');

    DateTime horaDateTime = DateTime(
      0,
      1,
      1,
      int.parse(partes[0]),
      int.parse(partes[1]),
    );

    return '${horaDateTime.hour.toString().padLeft(2, '0')}:${horaDateTime.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _refreshData() async {
    await _getTableData();
  }

  void removeRegisto(registo) async {
    String idRegisto = registo;
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=4&idRegisto=$idRegisto'));

    if (response.statusCode == 200) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registo eliminado com Sucesso'),
          ),
        );
      });
      _getTableData();
    }
  }

  // Função para atualizar um registro
  Future<void> updateRegisto(
    BuildContext context,
    String idRegisto,
    String data,
    String horaI,
    String horaF,
    String perfil,
    String local,
    String Centro_Custo_Projeto,
    String descricao,
  ) async {
    try {
      var response = await http.get(Uri.parse(
          'https://services.interagit.com/registarCallAPI_GET.php?query_param=9&idRegisto=$idRegisto&data=$data&horaI=$horaI&horaF=$horaF&perfil=$perfil&local=$local&ccp=$Centro_Custo_Projeto&descricao=$descricao'));

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Valor atualizado com sucesso no banco de dados!'),
          ),
        );
        _getTableData();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar valor no banco de dados'),
          ),
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição GET: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar valor no banco de dados'),
        ),
      );
    }
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Pretende fazer Log Out?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // ignore: use_build_context_synchronously
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext ctx) => const LoginForm()));
                ModalRoute.withName('/');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        title: Row(
          children: [
            ClipOval(
              child: users != null && users.toString() != "null"
                  ? users[0]['Imagem'] != null &&
                          users[0]['Imagem'].toString() != "null"
                      ? Image.memory(
                          base64.decode(users[0]['Imagem']),
                          fit: BoxFit.cover,
                          height: 50,
                          width: 50,
                        )
                      : Icon(
                          Icons.person,
                          size: 47,
                        )
                  : Icon(
                      Icons.person,
                      size: 47,
                    ),
            ),
            SizedBox(
              width: 8,
            ),
            users != null && users.toString() != "null"
                ? Text(
                    'Bem Vindo(a): ' +
                        users[0]['Nome'] +
                        " " +
                        users[0]['Apelido'],
                    style: TextStyle(color: Colors.white), // Texto será branco
                  )
                : Text(""),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      drawer: DrawerMain(),
      body: Container(
        width: double.infinity, // Usar toda a largura disponível
        height: double.infinity, // Usar toda a altura disponível
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/assets/itg.png'), // Caminho para a sua imagem de fundo
            // fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Imagem de fundo
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255)
                      .withOpacity(0.90), // Cor preta com opacidade de 40%
                ),
              ),
            ),
            Center(
              child: Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 15,
                      dataRowHeight: 100,
                      columns: [
                        DataColumn(label: Text('ID')),
                        DataColumn(label: Text('Data')),
                        DataColumn(label: Text('Hora Inicio')),
                        DataColumn(label: Text('Hora Fim')),
                        DataColumn(label: Text('Horas')),
                        DataColumn(label: Text('Tecnico')),
                        DataColumn(label: Text('Perfil')),
                        DataColumn(label: Text('Local')),
                        DataColumn(label: Text('Centro_Custo_Projeto')),
                        DataColumn(label: Text('Descricao')),
                        DataColumn(label: Text('')),
                        DataColumn(label: Text('')),
                      ],
                      rows: tableUsers.asMap().entries.map((entry) {
                        final index = entry.key;
                        final user = entry.value;

                        return DataRow(cells: [
                          DataCell(
                            SizedBox(
                              width: 50,
                              height: 100,
                              child: Text(user['IdRegisto'].toString()),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 90,
                              height: 100,
                              child: isEditing
                                  ? TextField(
                                      controller: getDataController(
                                          index, user['Data']),
                                      onChanged: (newValue) {
                                        setState(() {
                                          user['Data'] = newValue;
                                        });
                                      },
                                    )
                                  : Text(user['Data'], softWrap: true),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 90,
                              height: 100,
                              child: isEditing
                                  ? TextField(
                                      controller: getHoraIController(
                                          index, user['Hora_Inicio']),
                                      onChanged: (newValue) {
                                        setState(() {
                                          user['Hora_Inicio'] = newValue;
                                        });
                                      },
                                    )
                                  : Text(user['Hora_Inicio'], softWrap: true),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 90,
                              height: 100,
                              child: isEditing
                                  ? TextField(
                                      controller: getHoraFController(
                                          index, user['Hora_Fim']),
                                      onChanged: (newValue) {
                                        setState(() {
                                          user['Hora_Fim'] = newValue;
                                        });
                                      },
                                    )
                                  : Text(user['Hora_Fim'], softWrap: true),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 90,
                              height: 100,
                              child: Text(
                                user['Horas'].toString(),
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 80,
                              height: 100,
                              child: Text(
                                tecnico[int.parse(user['Tecnico']) - 1],
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 240,
                              height: 100,
                              child: isEditing
                                  ? DropdownButtonFormField<String>(
                                      value: perfil[
                                          int.parse(user['Perfil'] ?? '0') - 1],
                                      onChanged: (newValue) {
                                        setState(() {
                                          int index =
                                              _perfil.indexOf(newValue!);
                                          if (index != -1) {
                                            user['Perfil'] =
                                                (index + 1).toString();
                                          }
                                        });
                                      },
                                      items: _perfil.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    )
                                  : Text(perfil[int.parse(user['Perfil']) - 1],
                                      softWrap: true),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 125,
                              height: 100,
                              child: isEditing
                                  ? DropdownButtonFormField<String>(
                                      value: local[
                                          int.parse(user['Local'] ?? '0') - 1],
                                      onChanged: (newValue) {
                                        setState(() {
                                          int index = _local.indexOf(newValue!);
                                          if (index != -1) {
                                            user['Local'] =
                                                (index + 1).toString();
                                          }
                                        });
                                      },
                                      items: _local.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    )
                                  : Text(local[int.parse(user['Local']) - 1],
                                      softWrap: true),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 325,
                              height: 100,
                              child: isEditing
                                  ? DropdownButtonFormField<String>(
                                      value: ccp[int.parse(
                                              user['Centro_Custo_Projeto'] ??
                                                  '0') -
                                          1],
                                      onChanged: (newValue) {
                                        setState(() {
                                          int index = _ccp.indexOf(newValue!);
                                          if (index != -1) {
                                            user['Centro_Custo_Projeto'] =
                                                (index + 1).toString();
                                          }
                                        });
                                      },
                                      items: _ccp.map((String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(value),
                                        );
                                      }).toList(),
                                    )
                                  : Text(
                                      ccp[int.parse(
                                              user['Centro_Custo_Projeto']) -
                                          1],
                                      softWrap: true),
                            ),
                          ),
                          DataCell(
                            SizedBox(
                              width: 100,
                              height: 100,
                              child: isEditing
                                  ? TextField(
                                      controller: getDescricaoController(
                                          index, user['Descricao']),
                                      onChanged: (newValue) {
                                        setState(() {
                                          user['Descricao'] = newValue;
                                        });
                                      },
                                    )
                                  : Text(user['Descricao'], softWrap: true),
                            ),
                          ),
                          DataCell(isEditing
                              ? ElevatedButton(
                                  onPressed: () {
                                    updateRegisto(
                                      context,
                                      user['IdRegisto'],
                                      user['Data'],
                                      formatarHora(user['Hora_Inicio']),
                                      formatarHora(user['Hora_Fim']),
                                      user['Perfil'],
                                      user['Local'],
                                      user['Centro_Custo_Projeto'],
                                      user['Descricao'],
                                    );
                                    _refreshData();
                                    isEditing = false;
                                  },
                                  child: Text('Salvar'),
                                )
                              : Text("")),
                          DataCell(isEditing
                              ? ElevatedButton(
                                  onPressed: () {
                                    removeRegisto(user['IdRegisto']);
                                    _refreshData();
                                    isEditing = false;
                                  },
                                  child: Text('Remover'),
                                )
                              : Text("")),
                        ]);
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.more_horiz,
        iconTheme: IconThemeData(
            color: Colors.white), // Use IconThemeData with white color
        backgroundColor: Colors.red,
        children: [
          SpeedDialChild(
            child: Icon(Icons.edit),
            onTap: () {
              _toggleEditMode();
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.add),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => RegisterCallForm()),
              );
            },
          ),
        ],
      ),
    );
  }
}
