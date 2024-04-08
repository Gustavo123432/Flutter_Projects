import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appBar/Admin/addUser.dart';
import 'package:appBar/Admin/drawerAdmin.dart';
import 'package:appBar/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class UserTable extends StatefulWidget {
  @override
  _UserTableState createState() => _UserTableState();
}

class _UserTableState extends State<UserTable> {
  bool isEditing = false;
  dynamic users;
  List<dynamic> tableUsers = [];
  List<dynamic> filteredUsers = [];

  // Mapa para armazenar os controladores de texto para cada linha da tabela
  Map<int, TextEditingController> nomeControllers = {};
  Map<int, TextEditingController> apelidoControllers = {};
  Map<int, TextEditingController> turmaController = {};
  Map<int, TextEditingController> usercontrollers = {};

  void _toggleEditMode() {
    setState(() {
      isEditing = true;
    });
  }

  @override
  void initState() {
    UserInfo();
    _getTableData();

    super.initState();
  }

  // Função para buscar informações do usuário
  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('http://appbar.epvc.pt//appBarAPI_Post.php'),
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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    var response = await http.get(Uri.parse(
        'http://appbar.epvc.pt//appBarAPI_GET.php?query_param=2'));

    if (response.statusCode == 200) {
      setState(() {
        tableUsers = json.decode(response.body);
        filteredUsers = tableUsers; // Inicialmente, os usuários filtrados são iguais a todos os usuários
      });
    }
  }

  // Função para criar e retornar um controlador de texto para o nome do usuário
  TextEditingController? getNomeController(int index, String nome) {
    nomeControllers[index] ??= TextEditingController(text: nome);
    return nomeControllers[index];
  }

  TextEditingController? getUserController(int index, String user) {
    usercontrollers[index] ??= TextEditingController(text: user);
    return usercontrollers[index];
  }

  // Função para criar e retornar um controlador de texto para o apelido do usuário
  TextEditingController? getApelidoController(int index, String apelido) {
    apelidoControllers[index] ??= TextEditingController(text: apelido);
    return apelidoControllers[index];
  }

  TextEditingController? getTurmaController(int index, String turma) {
    turmaController[index] ??= TextEditingController(text: turma);
    return turmaController[index];
  }

  // Função para atualizar um usuário
  Future<void> updateUser(String userId, String user, String nome,
      String apelido, String turma, String permissao) async {
    try {
      var response = await http.get(Uri.parse(
          'http://appbar.epvc.pt//appBarAPI_GET.php?query_param=3&userId=$userId&user=$user&nome=$nome&apelido=$apelido&turma=$turma&permissao=$permissao'));
      if (response.statusCode == 200) {
        // Se a atualização foi bem-sucedida, exiba uma mensagem ou faça qualquer outra ação necessária
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Valor atualizado com sucesso no banco de dados!'),
          ),
        );
        UserInfo();
        _getTableData();
      } else {
        // Se houve um erro na atualização, exiba uma mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar valor no banco de dados'),
          ),
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição GET: $e');
      // Exibir mensagem de erro se a requisição falhar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar valor no banco de dados'),
        ),
      );
    }
  }

  void removeUser(user) async {
    String idUser = user;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String idUserShare = prefs.getString("idUser").toString();
    if (idUserShare.trim() == idUser.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não é possível eliminar o seu Utilizador'),
        ),
      );
    } else {
      var response = await http.get(Uri.parse(
          'http://appbar.epvc.pt//appBarAPI_GET.php?query_param=11&idUser=$idUser'));

      if (response.statusCode == 200) {
        setState(() {
          print(response);
          //print(json.decode(response.body));
          _getTableData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Utilizador eliminado com Sucesso'),
            ),
          );
        });
      }
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
  void _showFilterDialog() {
  String? selectedTurma;

  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Filtrar por Turma'),
        content: StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return DropdownButtonFormField<String>(
              value: selectedTurma,
              onChanged: (newValue) {
                setState(() {
                  selectedTurma = newValue;
                });
              },
              items: tableUsers
                  .map((user) => user['Turma'].toString())
                  .toSet()
                  .toList()
                  .map((turma) {
                return DropdownMenuItem<String>(
                  value: turma,
                  child: Text(turma),
                );
              }).toList(),
            );
          },
        ),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          TextButton(
            child: Text('Filtrar'),
          onPressed: () {
  setState(() {
    // Atualize o estado para refletir a filtragem
    filteredUsers = [];
    tableUsers.forEach((user) {
      if (user['Turma'] == selectedTurma) {
        filteredUsers.add(user);
      }
    });
  });
  Navigator.of(context).pop();
},
          ),
          TextButton(
            child: Text('Mostrar Todos'),
            onPressed: () {
              setState(() {
                // Se "Mostrar Todos" for pressionado, exibimos todos os usuários novamente
                filteredUsers = tableUsers;
              });
              Navigator.of(context).pop();
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
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
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
      drawer: DrawerAdmin(),
      body: Container(
        width: double.infinity, // Usar toda a largura disponível
        height: double.infinity, // Usar toda a altura disponível
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/assets/epvc.png'), // Caminho para a sua imagem de fundo
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
                      .withOpacity(0.80), // Cor preta com opacidade de 40%
                ),
              ),
            ),
            // Sua tabela aqui
            Center(
              child: DataTable(
                columns: [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Email')),
                  DataColumn(label: Text('Nome')),
                  DataColumn(label: Text('Apelido')),
                  DataColumn(label: Text('Turma')),
                  DataColumn(label: Text('Permissão')),
                  DataColumn(label: Text('')),
                  DataColumn(label: Text('')),
                ],
                rows: filteredUsers.asMap().entries.map((entry) {
                  final index = entry.key;
                  final user = entry.value;

                  return DataRow(
                    cells: [
                      DataCell(Text(user['IdUser'])),
                      DataCell(Text(user['Email'])),
                      DataCell(isEditing
                          ? TextField(
                              controller:
                                  getNomeController(index, user['Nome']),
                              onChanged: (newValue) {
                                setState(() {
                                  user['Nome'] = newValue;
                                });
                              },
                            )
                          : Text(user['Nome'])),
                      DataCell(isEditing
                          ? TextField(
                              controller:
                                  getApelidoController(index, user['Apelido']),
                              onChanged: (newValue) {
                                setState(() {
                                  user['Apelido'] = newValue;
                                });
                              },
                            )
                          : Text(user['Apelido'])),
                      DataCell(isEditing
                          ? TextField(
                              controller:
                                  getTurmaController(index, user['Turma']),
                              onChanged: (newValue) {
                                setState(() {
                                  user['Turma'] = newValue;
                                });
                              },
                            )
                          : Text(user['Turma'])),
                      DataCell(
                        isEditing
                            ? DropdownButtonFormField<String>(
                                value: user['Permissao'],
                                onChanged: (newValue) {
                                  setState(() {
                                    user['Permissao'] = newValue;
                                  });
                                },
                                items: [
                                    'Administrador',
                                    'Professor',
                                    'Funcionária',
                                    'Bar',
                                    'Aluno'
                                  ]
                                  .map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  })
                                  .toList(),
                              )
                            : Text(user['Permissao']),
                      ),
                      DataCell(
                        isEditing
                            ? ElevatedButton(
                                onPressed: () {
                                  updateUser(
                                    user['IdUser'],
                                    user['Email'],
                                    user['Nome'],
                                    user['Apelido'],
                                    user['Turma'],
                                    user['Permissao'],
                                  );
                                  isEditing = false;
                                },
                                child: Text('Guardar'),
                              )
                            : Text(""),
                      ),
                      DataCell(
                        isEditing
                            ? ElevatedButton(
                                onPressed: () {
                                  removeUser(
                                    user['IdUser'],
                                  );
                                  isEditing = false;
                                },
                                child: Text('Eliminar'),
                              )
                            : Text(""),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.more_horiz,
        iconTheme:
            IconThemeData(color: Colors.white), // Set icon color to white
        backgroundColor: Color.fromARGB(
                        255, 130, 201, 189),
        children: [
          SpeedDialChild(
            child: Icon(Icons.filter_list),
            onTap: () {
              _showFilterDialog();
              
            }
          ),
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
                MaterialPageRoute(builder: (context) => AddUserPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}
