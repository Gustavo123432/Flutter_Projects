import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Calldo/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:Calldo/Drawer/drawerMain.dart';

class Item {
  Item({this.isExpanded = false});
  bool isExpanded;
}

List<Item> generateItem(int n) {
  return List<Item>.generate(n, ((index) {
    return Item();
  }));
}

class Dados extends StatefulWidget {
  @override
  _DadosState createState() => _DadosState();
}

class _DadosState extends State<Dados> {
  List users = [];
  List<dynamic> perfil = [];
  List<String> _perfil = [];
  List<String> _local = [];
  List<dynamic> local = [];
  List<String> _ccp = [];
  List<dynamic> ccp = [];

  List<Item> _data = generateItem(3);

  int length = 0;
  TextEditingController _nameController =
      TextEditingController(); // Controller for the entered name

  @override
  void initState() {
    super.initState();
    fetchUserInfo();
    getPerfil();
    getCCP();
    getLocal();
  }

  Future<void> fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/registarCallAPI_Post.php'),
        body: {
          'query_param': '1',
          'user': user ?? '',
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
      } else {
        print('Failed to fetch user info: ${response.statusCode}');
      }
    } catch (e) {
      print('Failed to fetch user info: $e');
    }
  }

  Future<void> getPerfil() async {
    try {
      var response = await http.get(Uri.parse(
          'https://services.interagit.com/registarCallAPI_GET.php?query_param=15'));

      if (response.statusCode == 200) {
        var decodedData = json.decode(response.body);
        setState(() {
          perfil = decodedData;
          length = perfil.length;
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception thrown: $e');
    }
  }

  Future<void> getCCP() async {
    try {
      var response = await http.get(Uri.parse(
          'https://services.interagit.com/registarCallAPI_GET.php?query_param=16'));

      if (response.statusCode == 200) {
        var decodedData = json.decode(response.body);
        setState(() {
          ccp = decodedData;
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception thrown: $e');
    }
  }

  Future<void> getLocal() async {
    try {
      var response = await http.get(Uri.parse(
          'https://services.interagit.com/registarCallAPI_GET.php?query_param=14'));

      if (response.statusCode == 200) {
        var decodedData = json.decode(response.body);
        setState(() {
          local = decodedData;
        });
      } else {
        print('Failed to load data: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception thrown: $e');
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
      body: ListView.builder(
        itemCount: 1,
        itemBuilder: (context, index) {
          return Column(
            children: [
              ExpansionPanelList(
                expansionCallback: (int item, bool isExpanded) {
                  setState(() {
                    _data[item].isExpanded = !_data[item].isExpanded;
                    //print(_data[item].isExpanded);
                  });
                },
                children: [
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text('Perfil'),
                      );
                    },
                    body: Column(
                      children: [
                        for (var i = 0; i < perfil.length; i++)
                          ListTile(
                            title: Text(
                                'Perfil ID: ${perfil[i]['IdPerfil']} | Perfil: ${perfil[i]['Perfil']}'),
                          ),
                        SizedBox(
                            height:
                                20), // Add space between the list and buttons
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _addRowPerfil(context);
                                },
                                child: Text('Adicionar'),
                              ),
                            ])
                      ],
                    ),
                    isExpanded: _data[0].isExpanded,
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text('Local'),
                      );
                    },
                    body: Column(
                      children: [
                        for (var i = 0; i < local.length; i++)
                          ListTile(
                            title: Text(
                                'Local ID: ${local[i]['IdLocal']} | Local: ${local[i]['Local']}'),
                          ),
                        SizedBox(
                            height:
                                20), // Add space between the list and buttons
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _addRowLocal(context);
                                },
                                child: Text('Adicionar'),
                              ),
                            ])
                      ],
                    ),
                    isExpanded: _data[1].isExpanded,
                  ),
                  ExpansionPanel(
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return ListTile(
                        title: Text('Centro Custo / Projeto'),
                      );
                    },
                    body: Column(
                      children: [
                        for (var i = 0; i < ccp.length; i++)
                          ListTile(
                            title: Text(
                                'CCP ID: ${ccp[i]['IdCCP']} | Centro Custo / Projeto: ${ccp[i]['CCP']}'),
                          ),
                        SizedBox(
                            height:
                                20), // Add space between the list and buttons
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  _addRowCCP(context);
                                },
                                child: Text('Adicionar'),
                              ),
                            ])
                      ],
                    ),
                    isExpanded: _data[2].isExpanded,
                  ),
                  // Add expansion panels for CCP and other items here...
                ],
              ),
              // Your other widgets here...
            ],
          );
        },
      ),
    );
  }

  ///Centro Custo Projeto

  void _addRowCCP(BuildContext context) {
    // Exibe uma caixa de diálogo para que o usuário possa introduzir o novo Centro Custo/Projeto
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newCCP =
            ''; // Variável para armazenar o novo Centro Custo/Projeto
        return AlertDialog(
          title: Text('Novo Centro Custo / Projeto'),
          content: TextField(
            onChanged: (value) {
              newCCP =
                  value; // Atualiza a variável newCCP com o valor do TextField
            },
            decoration: InputDecoration(
                hintText: 'Introduza o novo Centro Custo/Projeto'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Fecha a caixa de diálogo sem fazer nada
              },
            ),
            TextButton(
                child: Text('Adicionar'),
                onPressed: () async {
                  if (newCCP != '') {
                    int idCCP = ccp.length;
                    String id = (idCCP + 1).toString();
                    bool teste = false;
                    for (var i = 0; i < ccp.length; i++) {
                      if (newCCP.trim() == ccp[i]['CCP']) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'O Centro Custo / Projeto já existe na Lista, Tente Novamente'),
                        ));
                        teste = true;

                        break;
                      }
                    }
                    if (!teste) {
                      try {
                        var response = await http.get(Uri.parse(
                            'https://services.interagit.com/registarCallAPI_GET.php?query_param=19&ccp=$newCCP&idCCP=$id'));

                        if (response.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Valor inserido com sucesso no banco de dados!'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Erro ao inserir valor no banco de dados'),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Erro ao fazer a requisição GET: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Erro ao inserir valor no banco de dados'),
                          ),
                        );
                      }

                      Navigator.of(context).pop();
                      setState(() {
                        getCCP();
                      }); // Fecha a caixa de diálogo
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('O campo é obrigatório'),
                      ),
                    );
                  }
                }),
          ],
        );
      },
    );
  }

  ///Local

  void _addRowLocal(BuildContext context) {
    // Exibe uma caixa de diálogo para que o usuário possa introduzir o novo Centro Custo/Projeto
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newLocal =
            ''; // Variável para armazenar o novo Centro Custo/Projeto
        int idLocal;

        return AlertDialog(
          title: Text('Novo Local'),
          content: TextField(
            onChanged: (value) {
              newLocal =
                  value; // Atualiza a variável newCCP com o valor do TextField
            },
            decoration: InputDecoration(hintText: 'Introduza o novo Local'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Fecha a caixa de diálogo sem fazer nada
              },
            ),
            TextButton(
                child: Text('Adicionar'),
                onPressed: () async {
                  idLocal = local.length;
                  String id = (idLocal + 1).toString();
                  if (newLocal != '') {
                    bool teste = false;
                    for (var i = 0; i < local.length; i++) {
                      if (newLocal.trim() == local[i]['Local']) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'O Local já existe na Lista, Tente Novamente'),
                        ));
                        teste = true;

                        break;
                      }
                    }
                    if (!teste) {
                      try {
                        var response = await http.get(Uri.parse(
                            'https://services.interagit.com/registarCallAPI_GET.php?query_param=17&local=$newLocal&idLocal=$id'));

                        if (response.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Valor inserido com sucesso no banco de dados!'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Erro ao inserir valor no banco de dados'),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Erro ao fazer a requisição GET: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Erro ao inserir valor no banco de dados'),
                          ),
                        );
                      }

                      Navigator.of(context).pop();
                      setState(() {
                        getLocal();
                      }); // Fecha a caixa de diálogo
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('O campo é obrigatório'),
                      ),
                    );
                  }
                }),
          ],
        );
      },
    );
  }

  ///Perfil

  void _addRowPerfil(BuildContext context) {
    // Exibe uma caixa de diálogo para que o usuário possa introduzir o novo Centro Custo/Projeto
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String newPerfil =
            ''; // Variável para armazenar o novo Centro Custo/Projeto
        return AlertDialog(
          title: Text('Novo Perfil'),
          content: TextField(
            onChanged: (value) {
              newPerfil =
                  value; // Atualiza a variável newCCP com o valor do TextField
            },
            decoration: InputDecoration(hintText: 'Introduza o novo Perfil'),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context)
                    .pop(); // Fecha a caixa de diálogo sem fazer nada
              },
            ),
            TextButton(
                child: Text('Adicionar'),
                onPressed: () async {
                  if (newPerfil != '') {
                    bool teste = false;
                    int idPerfil = perfil.length;
                    String id = (idPerfil + 1).toString();
                    for (var i = 0; i < perfil.length; i++) {
                      if (newPerfil.trim() == perfil[i]['Perfil']) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(
                              'O Perfil já existe na Lista, Tente Novamente'),
                        ));
                        teste = true;

                        break;
                      }
                    }
                    if (!teste) {
                      try {
                        var response = await http.get(Uri.parse(
                            'https://services.interagit.com/registarCallAPI_GET.php?query_param=18&perfil=$newPerfil&idPerfil=$id'));

                        if (response.statusCode == 200) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Valor inserido com sucesso no banco de dados!'),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Erro ao inserir valor no banco de dados'),
                            ),
                          );
                        }
                      } catch (e) {
                        print('Erro ao fazer a requisição GET: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content:
                                Text('Erro ao inserir valor no banco de dados'),
                          ),
                        );
                      }

                      Navigator.of(context).pop();
                      setState(() {
                        getPerfil();
                      }); // Fecha a caixa de diálogo
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('O campo é obrigatório'),
                      ),
                    );
                  }
                }),
          ],
        );
      },
    );
  }
}
