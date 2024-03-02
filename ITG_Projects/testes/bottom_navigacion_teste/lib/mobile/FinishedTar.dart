// ignore_for_file: file_names

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../bottom_navigation_bar.dart';
import 'TarPage.dart';

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
        'https://services.interagit.com/API/api_Calendar.php?query_param=14&id=$id'));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
                 appBar: AppBar(
        title: Text("Terminadas"),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                //  _showAlertDialog(context);
                },
                child: const Icon(
                  Icons.exit_to_app,
                  size: 26.0,
                ),
              )),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: Column(
          children: [
           /* Card(
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
                            });
                          },
                        )
                      ],
                    ))),*/
            Expanded(
              child: length == 0
                  ? Center(
                      child:
                          Text("Neste Momento não existem tarefas Terminadas"),
                    )
                  : ListView.builder(
                      itemCount: length,
                      itemBuilder: (context, index) => Card(
                        elevation: 2,
                            color: Colors.white,
                            child: ListTile(
                              leading: Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Ensure minimal horizontal space
                                children: [
                                  CircleAvatar(
                                      child: Text(tar[index]['idtarefa'])),
                                ],
                              ),
                              title: Text(
                                tar[index]['titulo'],
                                style: TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    tar[index]['descrip'].length > 33
                                        ? '${tar[index]['descrip'].substring(0, 30)}. . .'
                                        : tar[index]['descrip'],
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                  Text(
                                    tar[index]['namecliente'],
                                    style: TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 5,
                                  ),
                                ],
                              ),
                              trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      tar[index]['dateend'],
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      tar[index]['tempend']
                                          .toString()
                                          .substring(0, 5),
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ]),
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => TarPage(
                                    id: tar[index]['idtarefa'],
                                    title: tar[index]['titulo'],
                                    subtitle: tar[index]['descrip'],
                                    nomeC: tar[index]['namecliente'],
                                    dataM: tar[index]['datam'],
                                    horaM: tar[index]['tempm'],
                                    dataF: tar[index]['dateend'],
                                    horaF: tar[index]['tempend'],
                                    dataI: tar[index]['dataini'],
                                    horaI: tar[index]['tempini'],
                                    localR: tar[index]['loci'],
                                    localE: tar[index]['locf'],
                                    pageOrigin: 'finishedTar',
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
                          )),
            ),
          ],
        ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(initialIndex: 2),
    );
  }

  @override
  void initState() {
    getAllProducts('all');
    super.initState();
  }
}
