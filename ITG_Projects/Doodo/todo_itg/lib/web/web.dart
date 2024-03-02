// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously
import 'dart:convert';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_itg/main.dart';
import 'package:todo_itg/web/Tarefas/finishedTarDetails.dart';
import 'package:todo_itg/web/Ticket%C2%B4s/ticket.dart';
import 'Tarefas/users.dart';
import 'package:todo_itg/web/user/changeUserInfo.dart';
import 'Tarefas/createTar.dart';
import 'Tarefas/finishedTar.dart';
import 'Tarefas/startedTar.dart';

class WebPage extends StatefulWidget {
  const WebPage({super.key, required this.title});
  final String title;
  @override
  // ignore: library_private_types_in_public_api
  _WebPageState createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  int _selectedIndex = 0;
  dynamic tar;
  List<String> order = <String>[
    'N Tarefa',
    'Titulo',
    'Prioridade',
    'Atribuido',
    'Minhas'
  ];
  dynamic orderv;

  dynamic user, nome = 'Nome', mail = 'Mail';
  int length = 0;
  String _page_title = "Tarefas";

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        _page_title = "Tarefas";
      } else if (index == 1) {
        _page_title = "Estado Das Tarefas";
      } else if (index == 2) {
        _page_title = "Tarefas Finalizadas";
      } else if (index == 3) {
        _page_title = "Funcionários";
      }
      _selectedIndex = index;
    });
  }

  getAllProducts(String order) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    String pedido = 'all';
    dynamic response = await http.get(Uri.parse(
        "http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=10&order=$order&id=$id"));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=13&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        user = json.decode(response.body);
      });
      nome = user[0]['Name'];
      mail = user[0]['Mail'];

      return user;
    }
  }

  void IniTar(dynamic id) async {
    await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=5&id=$id'));
    getAllProducts(orderv.toString());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _page_title,
              style: const TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 25,
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _showAlertDialog(context);
                  },
                  child: const Icon(
                    Icons.exit_to_app,
                    size: 26.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildList() : _buildPage(_selectedIndex),
      drawer: Drawer(
        child: Column(
          children: [
            buildHeader(
              context,
              nome: nome,
              mail: mail,
            ),
            Card(
              elevation: 10,
              child: Column(
                children: <Widget>[
                  ExpansionTile(
                    title: Text("Minhas"),
                    initiallyExpanded: true,
                    leading: Icon(Icons.person),
                    childrenPadding: EdgeInsets.only(left: 60),
                    children: [
                      ListTile(
                        leading: Icon(Icons.home),
                        title: Text(
                          'Tarefas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _selectedIndex == 0,
                        onTap: () {
                          _onItemTapped(0);
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(height: 12),
                      ListTile(
                        leading: Icon(Icons.incomplete_circle),
                        title: Text(
                          'Estado Das Tarefas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _selectedIndex == 1,
                        onTap: () {
                          _onItemTapped(1);
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(height: 12),
                      ListTile(
                        leading: Icon(Icons.done),
                        title: Text(
                          'Tarefas Finalizadas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _selectedIndex == 2,
                        onTap: () {
                          _onItemTapped(2);
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(height: 12),
                    ],
                  ),
                  ListTile(
                    leading: Icon(Icons.person),
                    title: Text(
                      'Funcionários',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: _selectedIndex == 3,
                    onTap: () {
                      _onItemTapped(3);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16), // Adiciona espaçamento vertical
                ],
              ),
            ),
            Spacer(),
            // Adicione margem ao botão no final do Drawer
            Container(
              margin: EdgeInsets.only(
                  bottom: 16), // Adicione a margem inferior desejada
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ticketsPage(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Cor de fundo do botão
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8.0), // Borda arredondada
                  ),
                ),
                child: Text(
                  'Help Center',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await getAllProducts(orderv.toString());
  }

  Widget buildHeader(
    BuildContext context, {
    required String nome,
    required String mail,
  }) =>
      Material(
        color: Colors.blue,
        child: InkWell(
          child: Container(
            child: Row(
              children: [
                SizedBox(height: 120, width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mail,
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.transparent,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => changeUserInfo(),
                          ));
                        },
                        child: const Icon(
                          Icons.settings,
                          size: 26.0,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
  Widget _buildList() {
    return WillPopScope(
        onWillPop: () async => false,
        child: Scaffold(
          body: RefreshIndicator(
            onRefresh: _refreshData,
            child: Column(
              children: <Widget>[
                Card(
                    child: Container(
                        height: 60,
                        child: Row(
                          children: [
                            Text('    Ordenar por  '),
                            DropdownButton<String>(
                              value: orderv,
                              hint: Text('Escolha a opção'),
                              icon: const Icon(Icons.expand_more),
                              elevation: 16,
                              style: const TextStyle(color: Colors.black),
                              underline: Container(
                                height: 2,
                                color: Colors.blue,
                              ),
                              items: order.map<DropdownMenuItem<String>>(
                                  (String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                              onChanged: (value) {
                                // This is called when the user selects an item.
                                setState(() {
                                  orderv = value.toString();
                                  getAllProducts(orderv.toString());
                                });
                              },
                            )
                          ],
                        ))),
                Expanded(
                  child: length == 0
                      ? Center(
                          child: Text(
                              "Neste Momento não existem tarefas por Iniciar"),
                        )
                      : ListView.builder(
                          itemCount: length,
                          itemBuilder: (context, index) => Card(
                            color: tar[index]['Priority'] == '2'
                                ? Colors.red
                                : tar[index]['Priority'] == '1'
                                    ? Colors.yellow
                                    : Colors.white,
                            child: Slidable(
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      IniTar(tar[index]['IdTarefa']);
                                      setState(() {
                                        getAllProducts(orderv.toString());
                                      });
                                    },
                                    backgroundColor: Colors.green,
                                    icon: Icons.start_sharp,
                                    label: 'Começar',
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize
                                      .min, // Ensure minimal horizontal space
                                  children: [
                                    tar[index]['Priority'] == '2'
                                        ? CircleAvatar(
                                            child: Icon(Icons.report_problem))
                                        : tar[index]['Priority'] == '1'
                                            ? CircleAvatar(
                                                child: Icon(
                                                    Icons.report_gmailerrorred))
                                            : CircleAvatar(
                                                child: Text(
                                                    tar[index]['IdTarefa'])),
                                  ],
                                ),
                                title: Text(
                                  tar[index]['Titulo'],
                                  style: TextStyle(
                                    fontWeight: tar[index]['Priority'] == '2'
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: tar[index]['Priority'] == '2'
                                        ? Colors.white
                                        : tar[index]['Priority'] == '1'
                                            ? Colors.black
                                            : Colors.black,
                                  ),
                                ),
                                subtitle: Text(
                                  tar[index]['Descrip'].length > 33
                                      ? '${tar[index]['Descrip'].substring(0, 30)}. . .'
                                      : tar[index]['Descrip'],
                                  style: TextStyle(
                                    color: tar[index]['Priority'] == '2'
                                        ? Colors.white
                                        : tar[index]['Priority'] == '1'
                                            ? Colors.black
                                            : Colors.grey,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize
                                      .min, // Ensure minimal horizontal space
                                  children: <Widget>[
                                    Padding(
                                      padding: const EdgeInsets.only(
                                          right:
                                              10.0), // Adjust the padding as needed
                                      child: Container(
                                        alignment: Alignment.center,
                                        child: Text(
                                          tar[index]['name'],
                                          style: TextStyle(
                                            fontWeight:
                                                tar[index]['Priority'] == '2'
                                                    ? FontWeight.bold
                                                    : FontWeight.normal,
                                            color: tar[index]['Priority'] == '2'
                                                ? Colors.white
                                                : tar[index]['Priority'] == '1'
                                                    ? Colors.black
                                                    : Colors.black,
                                          ),
                                        ),
                                      ),
                                    ),
                                    CircleAvatar(
                                        child: Text(tar[index]['CodUser'])),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => finishedTarDetails(
                                      id: tar[index]['IdTarefa'],
                                      title: tar[index]['Titulo'],
                                      subtitle: tar[index]['Descrip'],
                                      datainicio: tar[index]['DataIni'],
                                      datafim: tar[index]['DateEnd'],
                                      horainicio: tar[index]['TempIni'],
                                      horafim: tar[index]['TempEnd'],
                                      coduser: tar[index]['CodUser'],
                                      tipoTarefa: 0,
                                      numberOfButtons: 1,
                                      mainButtonCallback: () {
                                        showSnackBar(
                                            'Tarefa iniciada com sucesso.');
                                        IniTar(tar[index]['IdTarefa']);
                                        Navigator.pop(context);
                                        setState(() {
                                          getAllProducts(order as String);
                                        });
                                      },
                                      extraButtonCallback: () {},
                                    ),
                                  ));
                                },
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => createTar(),
              ));
            },
            child: const Icon(Icons.add), // You can change the icon as needed
          ),
        ));
  }

  void showSnackBar(String message) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        message,
        style: TextStyle(
          fontSize: 16, // Customize font size
        ),
      ),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
      backgroundColor: Colors.green, // Customize background color
      elevation: 6.0, // Add elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Customize border radius
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildPage(int index) {
    // Implemente suas próprias páginas personalizadas aqui
    switch (index) {
      case 1:
        return startedTar();
      case 2:
        return finishedTar();
      case 3:
        return usersPage();
      default:
        return Container(); // Retorne um contêiner vazio como fallback
    }
  }

  @override
  void initState() {
    getUser();
    getAllProducts('all');

    super.initState();
  }
}

void _showAlertDialog(BuildContext context) {
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
              prefs.remove('id');
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext ctx) => const LoginForm()));
            },
          ),
        ],
      );
    },
  );
}
