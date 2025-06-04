import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Admin/addUser.dart';
import 'package:appbar_epvc/Admin/drawerAdmin.dart';
import 'package:appbar_epvc/login.dart';
import 'package:appbar_epvc/models/listUsers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';

class UserTable extends StatefulWidget {
  @override
  _UserTableState createState() => _UserTableState();
}

class _UserTableState extends State<UserTable> {
  bool isEditing = false;
  dynamic users;
  List<Map<String, dynamic>> tableUsers = [];
  List<Map<String, dynamic>> filteredUsers = [];
  List<Map<String, dynamic>> displayedSuppliers = [];

  List<int> rowsPerPageOptions = [25, 50, 100]; // For the "All" option
  List<String> selectedSupplierIds = [];
  String? countSuppliers;
  int rowsPerPage = 25;
  int currentPage = 0; // Current page index
  int totalPages = 0;

  List<String> _turmas = []; // List to store fetched turmas

  // Mapa para armazenar os controladores de texto para cada linha da tabela
  Map<int, TextEditingController> nomeControllers = {};
  Map<int, TextEditingController> apelidoControllers = {};
  Map<int, TextEditingController> turmaController = {};
  Map<int, TextEditingController> usercontrollers = {};
  TextEditingController searchController = TextEditingController();

  void _toggleEditMode() {
    setState(() {
      isEditing = true;
    });
  }

  @override
  void initState() {
    UserInfo();
    tableUsers = [];
    filteredUsers = [];
    fetchCountSuppliers();
    _getTableData();
    _loadTurmas();

    super.initState();
  }

  // Função para buscar informações do usuário
  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
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

   Future<void> _loadTurmas() async {
    try {
      List<String> turmas = await _fetchTurmasFromAPI();
      setState(() {
        _turmas = turmas;
      });
    } catch (e) {
      print('Error loading turmas: $e');
      // Here you can display an error message to the user or take other appropriate action.
    }
  }
  Future<List<String>> _fetchTurmasFromAPI() async {
    try {
      final response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=20'));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<String> turmas =
            responseData.map((data) => data['Turma'] as String).toList();
        return turmas;
      } else {
        throw Exception('Failed to load turmas from API');
      }
    } catch (e) {
      throw Exception('Error fetching turmas: $e');
    }
  }

  Future<void> fetchCountSuppliers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    var response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=2'));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        countSuppliers = data['clients_count'].toString();
      });
    }
  }

  // Função para buscar dados da tabela de usuários
  Future<void> _getTableData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    var response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=2.1&limit=${rowsPerPage.toString()}&page=${currentPage.toString()}'));

    if (response.statusCode == 200) {
      setState(() {
        tableUsers =
            List<Map<String, dynamic>>.from(json.decode(response.body));
        filteredUsers = tableUsers;
        displayedSuppliers = tableUsers;
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
      String apelido, String turma, String permissao, String estado) async {
    print(estado);
    try {
      var response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=3&userId=$userId&user=$user&nome=$nome&apelido=$apelido&turma=$turma&permissao=$permissao&estado=$estado'));
      if (response.statusCode == 200) {
        // Se a atualização foi bem-sucedida, exiba uma mensagem ou faça qualquer outra ação necessária
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Utilizador atualizado com sucesso na base de dados!'),
          ),
        );
        UserInfo();
        searchController.text = "";
        _getTableData();
      } else {
        // Se houve um erro na atualização, exiba uma mensagem de erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar utilizador na base de dados'),
          ),
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição GET: $e');
      // Exibir mensagem de erro se a requisição falhar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar utilizador na base de dados'),
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
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=11&idUser=$idUser'));

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

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xls', 'xlsx'],
    );

    if (result != null) {
      PlatformFile file = result.files.first;
      await _uploadFile(file);
    }
  }

  Future<void> _uploadFile(PlatformFile file) async {
    final url = 'http://appbar.epvc.pt/APIappBarAPI_Post.php'; // Correct URL

    // Create a multipart request
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Add other fields if needed
    request.fields['query_param'] = '10'; // Example parameter
    // Determine MIME type based on file extension
    String mimeType = 'application/octet-stream'; // Default MIME type
    if (file.name.endsWith('.xlsx')) {
      mimeType =
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else if (file.name.endsWith('.xls')) {
      mimeType = 'application/vnd.ms-excel';
    }

    // Attach the file
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
        contentType: MediaType.parse(mimeType), // Set the determined MIME type
      ),
    );

    // Send the request
    try {
      var response = await request.send();

      // Check the status code and handle the response
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        final responseData = jsonDecode(responseBody);

        if (responseData['message'] == 'Dados carregados com sucesso') {
          print('Arquivo enviado com sucesso');
        } else {
          print('Falha ao enviar arquivo: ${responseData['message']}');
        }
      } else {
        print('Falha ao enviar arquivo. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('Ocorreu um erro ao enviar o arquivo: $e');
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
    selectedTurma = _turmas[0];

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
                items: _turmas
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
              onPressed: () async {
                if (selectedTurma == "") {
                  setState(() {
                    tableUsers = [];
                    filteredUsers = [];
                    rowsPerPage = 25;
                    currentPage = 0; // Reset to the first page
                    fetchCountSuppliers();
                    _getTableData();
                  });
                } else {
                  try {
                    var response = await http.get(Uri.parse(
                        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=2.3&op=$selectedTurma'));

                    if (response.statusCode == 200) {
                      final decodedData = json.decode(response.body);

                      if (decodedData is List) {
                        // Explicitly cast and sanitize data
                        List<Map<String, dynamic>> sanitizedData = decodedData
                            .map((item) {
                              // Ensure each field is treated as a String, even if it is an int
                              return {
                                "Email": item["Email"]?.toString() ?? "",
                                "Nome": item["Nome"]?.toString() ?? "",
                                "Apelido": item["Apelido"]?.toString() ?? "",
                                "Permissao":
                                    item["Permissao"]?.toString() ?? "",
                                "Turma": item["Turma"]?.toString() ?? "",
                                "IdUser": item["IdUser"] != null
                                    ? item["IdUser"].toString()
                                    : "0",
                                "Estado": item["Estado"] != null
                                    ? item["Estado"].toString()
                                    : "0",
                              };
                            })
                            .where((item) => item.isNotEmpty)
                            .toList();

                        setState(() {
                          tableUsers = sanitizedData;
                          filteredUsers = sanitizedData;
                          currentPage = 0;
                        });
                      } else {
                        setState(() {
                          tableUsers = [];
                          filteredUsers = [];
                        });
                      }
                    } else {
                      throw Exception('Failed to load users');
                    }

                    setState(() {
                      // Paginate the displayed users
                      displayedSuppliers = rowsPerPage == -1
                          ? tableUsers
                          : tableUsers
                              .skip(currentPage * rowsPerPage)
                              .take(rowsPerPage)
                              .toList();
                    });
                  } catch (e) {
                    setState(() {});
                    print('Error: $e');
                  }
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Mostrar Todos'),
              onPressed: () {
                setState(() {
                    tableUsers = [];
                    filteredUsers = [];
                    rowsPerPage = 25;
                    currentPage = 0; // Reset to the first page
                    fetchCountSuppliers();
                    _getTableData();
                  });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _filterUsers() async {
    String query = searchController.text.toString().toLowerCase();
    if (query == "") {
      setState(() {
        tableUsers = [];
        filteredUsers = [];
        rowsPerPage = 25;
        currentPage = 0; // Reset to the first page
        fetchCountSuppliers();
        _getTableData();
      });
    } else {
      try {
        var response = await http.get(Uri.parse(
            'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=2.2&op=$query'));

        if (response.statusCode == 200) {
          final decodedData = json.decode(response.body);

          if (decodedData is List) {
            // Explicitly cast and sanitize data
            List<Map<String, dynamic>> sanitizedData = decodedData
                .map((item) {
                  // Ensure each field is treated as a String, even if it is an int
                  return {
                    "Email": item["Email"]?.toString() ?? "",
                    "Nome": item["Nome"]?.toString() ?? "",
                    "Apelido": item["Apelido"]?.toString() ?? "",
                    "Permissao": item["Permissao"]?.toString() ?? "",
                    "Turma": item["Turma"]?.toString() ?? "",
                    "IdUser": item["IdUser"] != null
                        ? item["IdUser"].toString()
                        : "0",
                    "Estado": item["Estado"] != null
                        ? item["Estado"].toString()
                        : "0",
                  };
                })
                .where((item) => item.isNotEmpty)
                .toList();

            setState(() {
              tableUsers = sanitizedData;
              filteredUsers = sanitizedData;
              currentPage = 0;
            });
          } else {
            setState(() {
              tableUsers = [];
              filteredUsers = [];
            });
          }
        } else {
          throw Exception('Failed to load users');
        }

        setState(() {
          // Paginate the displayed users
          displayedSuppliers = rowsPerPage == -1
              ? tableUsers
              : tableUsers
                  .skip(currentPage * rowsPerPage)
                  .take(rowsPerPage)
                  .toList();
        });
      } catch (e) {
        setState(() {});
        print('Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int countSupplier = int.tryParse(countSuppliers ?? '0') ?? 0;
    int totalPages = (countSupplier / rowsPerPage).ceil();
    if (currentPage >= totalPages && totalPages > 0) currentPage = totalPages - 1;
    if (currentPage < 0) currentPage = 0;
    final usersToShow = filteredUsers;
    return MaterialApp(
      home: Scaffold(
        drawer: DrawerAdmin(),
        body: SingleChildScrollView(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/epvc.png'),
                // fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                // Imagem de fundo
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 255, 255, 255)
                          .withOpacity(0.80), // Cor branca com opacidade de 80%
                    ),
                  ),
                ),
                // Barra de pesquisa
                Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: searchController,
                          decoration: InputDecoration(
                            labelText: 'Search',
                            suffixIcon: IconButton(
                              icon: Icon(Icons.search),
                              onPressed: _filterUsers,
                            ),
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _filterUsers();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Tabela de utilizadores
                Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 50),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('ID')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Nome')),
                          DataColumn(label: Text('Turma')),
                          DataColumn(label: Text('Permissão')),
                          DataColumn(label: Text('Editar')),
                          DataColumn(label: Text('Remover')),
                        ],
                        rows: usersToShow.asMap().entries.map((entry) {
                          final index = entry.key + currentPage * rowsPerPage;
                          final user = entry.value;
                          return DataRow(
                            onSelectChanged: (selected) {
                              if (selected != null && selected) {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    return AlertDialog(
                                      title: const Text('Editar'),
                                      content: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          TextFormField(
                                            controller: getNomeController(
                                                index, user['Nome']),
                                            decoration: const InputDecoration(
                                                labelText: 'Nome'),
                                            onChanged: (newValue) {
                                              setState(() {
                                                user['Nome'] = newValue;
                                              });
                                            },
                                          ),
                                          TextFormField(
                                            controller: getTurmaController(
                                                index, user['Turma']),
                                            decoration: const InputDecoration(
                                                labelText: 'Turma'),
                                            onChanged: (newValue) {
                                              setState(() {
                                                user['Turma'] = newValue;
                                              });
                                            },
                                          ),
                                          DropdownButtonFormField<String>(
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
                                            ].map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            decoration: const InputDecoration(
                                                labelText: 'Permissão'),
                                          ),
                                          DropdownButtonFormField<String>(
                                            value: user['Estado'] == '1'
                                                ? 'Ativo'
                                                : 'Desativo',
                                            onChanged: (newValue) {
                                              setState(() {
                                                user['Estado'] =
                                                    newValue == 'Ativo'
                                                        ? '1'
                                                        : '0';
                                              });
                                            },
                                            items: [
                                              'Ativo',
                                              'Desativo',
                                            ].map((String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            decoration: const InputDecoration(
                                              labelText: 'Estado',
                                            ),
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        ElevatedButton(
                                          onPressed: () {
                                            updateUser(
                                                user['IdUser'],
                                                user['Email'],
                                                user['Nome'],
                                                user['Apelido'],
                                                user['Turma'],
                                                user['Permissao'],
                                                user['Estado']);
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Guardar'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          child: const Text('Cancelar'),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              }
                            },
                            cells: [
                              DataCell(Text(user['IdUser'])),
                              DataCell(Text(user['Email'].toString().length > 14
                                  ? '${user['Email'].toString().substring(0, 11)}...'
                                  : user['Email'])),
                              DataCell(Text(user['Nome'].toString().length > 18
                                  ? '${user['Nome'].toString().substring(0, 11)}...'
                                  : user['Nome'])),
                              DataCell(Text(user['Turma'])),
                              DataCell(Text(user['Permissao'])),
                              DataCell(ElevatedButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('Editar Usuário'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextFormField(
                                              controller: getNomeController(
                                                  index, user['Nome']),
                                              decoration: const InputDecoration(
                                                  labelText: 'Nome'),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  user['Nome'] = newValue;
                                                });
                                              },
                                            ),
                                            TextFormField(
                                              controller: getTurmaController(
                                                  index, user['Turma']),
                                              decoration: const InputDecoration(
                                                  labelText: 'Turma'),
                                              onChanged: (newValue) {
                                                setState(() {
                                                  user['Turma'] = newValue;
                                                });
                                              },
                                            ),
                                            DropdownButtonFormField<String>(
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
                                              ].map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              decoration: const InputDecoration(
                                                  labelText: 'Permissão'),
                                            ),
                                            DropdownButtonFormField<String>(
                                              value: user['Estado'] == '1'
                                                  ? 'Ativo'
                                                  : 'Desativo',
                                              onChanged: (newValue) {
                                                setState(() {
                                                  user['Estado'] =
                                                      newValue == 'Ativo'
                                                          ? '1'
                                                          : '0';
                                                });
                                              },
                                              items: [
                                                'Ativo',
                                                'Desativo',
                                              ].map((String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              decoration: const InputDecoration(
                                                labelText: 'Estado',
                                              ),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          ElevatedButton(
                                            onPressed: () {
                                              updateUser(
                                                user['IdUser'],
                                                user['Email'],
                                                user['Nome'],
                                                user['Apelido'],
                                                user['Turma'],
                                                user['Permissao'],
                                                user['Estado'],
                                              );
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Guardar'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Cancelar'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                 style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.orange),
                                ),
                                child: const Text('Editar', style: TextStyle(color:  Colors.white),),
                              )),
                              DataCell(ElevatedButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      MaterialStateProperty.all(Colors.orange),
                                ),
                                onPressed: () {
                                  removeUser(user['IdUser']);
                                },
                                child: const Text('Eliminar', style: TextStyle(color:  Colors.white),),
                              )),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: BottomAppBar(
          color: Colors.white, // Set the background color to white
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Text("Utilizadores por Página: "),
                      DropdownButton<int>(
                        value: rowsPerPage,
                        items: [25, 50, 100].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(value == -1 ? 'Todos' : value.toString()),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            rowsPerPage = newValue!;
                            currentPage = 0; // Reset to the first page
                            _getTableData();
                          });
                        },
                      ),
                      SizedBox(width: 16.0),
                      Text("Página: ${currentPage + 1} de $totalPages"),
                      IconButton(
                        icon: Icon(Icons.first_page),
                        onPressed: currentPage > 0
                            ? () {
                                setState(() {
                                  currentPage = 0;
                                  _getTableData();
                                });
                              }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios),
                        onPressed: currentPage > 0
                            ? () {
                                setState(() {
                                  currentPage--;
                                  _getTableData();
                                });
                              }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.arrow_forward_ios),
                        onPressed: currentPage < totalPages - 1
                            ? () {
                                setState(() {
                                  currentPage++;
                                  _getTableData();
                                });
                              }
                            : null,
                      ),
                      IconButton(
                        icon: Icon(Icons.last_page),
                        onPressed: currentPage < totalPages - 1
                            ? () {
                                setState(() {
                                  currentPage = totalPages - 1;
                                  _getTableData();
                                });
                              }
                            : null,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: SpeedDial(
          icon: Icons.more_horiz,
          iconTheme: IconThemeData(color: Colors.white),
          backgroundColor: Color.fromARGB(255, 130, 201, 189),
          children: [
            SpeedDialChild(
                child: Icon(Icons.filter_list),
                onTap: () {
                  _showFilterDialog();
                }),
            SpeedDialChild(
              child: Icon(Icons.file_upload),
              onTap: () {
                _pickFile();
              },
            ),
            SpeedDialChild(
              child: Icon(Icons.add),
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      content: AddUserDialog(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
