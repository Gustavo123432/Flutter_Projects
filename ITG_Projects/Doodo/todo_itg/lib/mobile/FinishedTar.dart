// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_itg/mobile/TarPage.dart';

class FinishedTar extends StatefulWidget {
  const FinishedTar({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _FinishedTarState createState() => _FinishedTarState();
}

class _FinishedTarState extends State<FinishedTar> {
  dynamic tar;
  int length = 0;
  getAllProducts(String order) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=4&order=$order&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  Future<void> _refreshData() async {
    await getAllProducts(orderv.toString());
  }

  List<String> order = <String>[
    'N Tarefa',
    'Titulo',
    'Prioridade',
  ];
  dynamic orderv;

  getAllProduct(String order) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        "http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=12&order=$order&id=$id"));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
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
                          items: order
                              .map<DropdownMenuItem<String>>((String value) {
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
                            });
                          },
                        )
                      ],
                    ))),
            Expanded(
              child: length == 0
                  ? Center(
                      child:
                          Text("Neste Momento não existem tarefas Terminadas"),
                    )
                  : ListView.builder(
                      itemCount: length,
                      itemBuilder: (context, index) => Card(
                        color: tar[index]['Priority'] == '2'
                            ? Colors.red
                            : tar[index]['Priority'] == '1'
                                ? Colors.yellow
                                : Colors.white,
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
                                          child:
                                              Icon(Icons.report_gmailerrorred))
                                      : CircleAvatar(
                                          child: Text(tar[index]['IdTarefa'])),
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
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => TarPage(
                                id: tar[index]['IdTarefa'],
                                title: tar[index]['Titulo'],
                                subtitle: tar[index]['Descrip'],
                                datainicio: tar[index]['DataIni'],
                                datafim: tar[index]['DateEnd'],
                                horainicio: tar[index]['TempIni'],
                                horafim: tar[index]['TempEnd'],
                                numberOfButtons: 0,
                                mainButtonCallback: () {},
                                extraButtonCallback: () {
                                  // Ação para o botão extra na página "Começadas"
                                  // Implemente a ação específica para este botão na página "Começadas"
                                },
                              ),
                            ));
                          },
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    getAllProducts('all');
    super.initState();
  }
}
