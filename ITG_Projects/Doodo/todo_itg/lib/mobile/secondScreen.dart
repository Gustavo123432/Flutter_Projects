// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:todo_itg/main.dart';
import 'package:todo_itg/web/Tarefas/startedTar.dart';
import 'TarPage.dart';
import 'FinishedTar.dart';
import 'StartedTar.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  dynamic tar;
  int length = 0;
  getAllProduct(String order) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=11'));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
        print(tar);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  int _selectedIndex = 0;

  List<String> order = <String>['N Tarefa', 'Titulo', 'Prioridade'];
  dynamic orderv;

  int _currentIndex = 0;
  String _pageTitle = "Tarefas";

  @override
  void initState() {
    getAllProduct(order.toString());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  _showAlertDialog(context);
                },
                child: const Icon(
                  Icons.exit_to_app,
                  size: 26.0,
                ),
              )),
        ],
      ),

      body: _currentIndex == 0
          ? _buildList() // Exibe a lista quando _currentIndex for 0
          : _buildPage(
              _currentIndex), // Exibe a página correspondente quando _currentIndex não for 0
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            // Update the page title based on the selected index
            switch (index) {
              case 0:
                _pageTitle = "Tarefas";
                break;
              case 1:
                _pageTitle = "Em Progresso";
                break;
              case 2:
                _pageTitle = "Finalizadas";
                break;
            }
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Tarefas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.incomplete_circle),
            label: 'Em Progresso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.done),
            label: 'Finalizadas',
          ),
        ],
      ),
    );
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
                // ignore: use_build_context_synchronously
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

  // ignore: non_constant_identifier_names
  void IniTar(dynamic id) async {
    await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=5&id=$id'));
    getAllProduct(order.toString());
    setState(() {});
  }

  Future<void> _refreshData() async {
    await getAllProduct(orderv.toString());
  }

  // Método para construir a lista
  // ignore: dead_code
  Widget _buildList() {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(children: <Widget>[
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
                        items:
                            order.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          // This is called when the user selects an item.
                          setState(() {
                            orderv = value.toString();
                            getAllProduct(orderv.toString());
                            print(value);
                          });
                        },
                      )
                    ],
                  ))),
          Expanded(
              child: length == 0
                  ? Center(
                      child: Text("Neste Momento não existem tarefas Inicias"),
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
                                      IniTar(tar[index]['idtarefa']);
                                      setState(() {
                                        getAllProduct(order.toString());
                                      });
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  StartedTar()));
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
                                    CircleAvatar(child: Text('1')),
                                  ],
                                ),
                                title: Text(
                                  tar[index]['titulo'],
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
                                  tar[index]['descrip'].length > 33
                                      ? '${tar[index]['descrip'].substring(0, 30)}. . .'
                                      : tar[index]['descrip'],
                                  style: TextStyle(
                                    color: tar[index]['Priority'] == '2'
                                        ? Colors.white
                                        : tar[index]['Priority'] == '1'
                                            ? Colors.black
                                            : Colors.grey,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => TarPage(
                                      id: tar[index]['idtarefa'],
                                      title: tar[index]['titulo'],
                                      subtitle: tar[index]['descrip'],
                                      datainicio: tar[index]['DataIni'],
                                      datafim: tar[index]['DateEnd'],
                                      horainicio: tar[index]['TempIni'],
                                      horafim: tar[index]['TempEnd'],
                                      numberOfButtons: 1,
                                      mainButtonCallback: () {
                                        IniTar(tar[index]['idtarefa']);
                                        setState(() {
                                          getAllProduct(order.toString());
                                        });
                                        Navigator.of(context).push(
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    StartedTar()));
                                      },
                                      extraButtonCallback: () {},
                                    ),
                                  ));
                                },
                              ),
                            ),
                          )))
        ]),
      ),
    );
  }

  // Método para construir páginas personalizadas
  Widget _buildPage(int index) {
    // Implemente suas próprias páginas personalizadas aqui
    switch (index) {
      case 1:
        return const StartedTar();
      case 2:
        return const FinishedTar();
      default:
        return Container(); // Retorne um contêiner vazio como fallback
    }
  }
}
