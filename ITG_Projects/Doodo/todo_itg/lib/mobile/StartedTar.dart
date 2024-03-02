import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_itg/mobile/secondScreen.dart';
import 'TarPage.dart';

class StartedTar extends StatefulWidget {
  const StartedTar({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _StartedTarPageState createState() => _StartedTarPageState();
}

class _StartedTarPageState extends State<StartedTar> {
  final TextEditingController ObController = TextEditingController();

  dynamic tar;
  int length = 0;
  late String tex;

  getAllProducts(String order) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=3&id=$id&order=$order'));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  List<String> order = <String>[
    'N Tarefa',
    'Titulo',
    'Prioridade',
  ];
  dynamic orderv;

  @override
  void dispose() {
    ObController.clear();
    super.dispose();
  }

  // ignore: non_constant_identifier_names
  void CancelTar(dynamic id) async {
    await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=6&id=$id'));
    getAllProducts(order.toString());
    setState(() {});
  }

  // ignore: non_constant_identifier_names
  void EndTar(dynamic id, String det) async {
    await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=7&det=$det&id=$id'));
    getAllProducts(order.toString());
    setState(() {});
  }

  Future<void> _refreshData() async {
    await getAllProducts(order.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                              getAllProducts(orderv.toString());
                              print(value);
                            });
                          },
                        )
                      ],
                    ))),
            Expanded(
              child: length == 0
                  ? const Center(
                      child:
                          Text("Neste Momento não existem tarefas por Iniciar"),
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
                                  _showAlertDialog(context, index);

                                  setState(() {
                                    getAllProducts(order.toString());
                                  });
                                  //Navigator.of(context).push(MaterialPageRoute(builder: (context) => FinishedTar()));
                                },
                                backgroundColor: Colors.green,
                                icon: Icons.done,
                                label: 'Terminar',
                              ),
                              SlidableAction(
                                onPressed: (context) {
                                  CancelTar(tar[index]['IdTarefa']);
                                  setState(() {
                                    getAllProducts(order.toString());
                                  });
                                  //Navigator.of(context).push(MaterialPageRoute(builder: (context) => SecondScreen()));
                                },
                                backgroundColor: Colors.red,
                                icon: Icons.cancel,
                                label: 'Cancelar',
                              ),
                            ],
                          ),
                          child: ListTile(
                            leading: Row(
                              mainAxisSize: MainAxisSize
                                  .min, // Ensure minimal horizontal space
                              children: [
                                tar[index]['Priority'] == '2'
                                    ? const CircleAvatar(
                                        child: Icon(Icons.report_problem))
                                    : tar[index]['Priority'] == '1'
                                        ? const CircleAvatar(
                                            child: Icon(
                                                Icons.report_gmailerrorred))
                                        : CircleAvatar(
                                            child:
                                                Text(tar[index]['IdTarefa'])),
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
                                  numberOfButtons: 2,
                                  mainButtonCallback: () {
                                    _showAlertDialog(context, index);
                                  },
                                  extraButtonCallback: () {
                                    CancelTar(tar[index]['IdTarefa']);
                                    setState(() {
                                      getAllProducts(order.toString());
                                    });
                                  },
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
    );
  }

  @override
  void initState() {
    getAllProducts(order.toString());

    super.initState();
  }

  void _showAlertDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Observações(Opcional)'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
                hintText: 'Introduza as suas observações.'),
            controller: ObController,
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                //adicionar função para quando a pessoa carrega n cancelar ela no finalizar a tarefa(não fazer nada)
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                //print(ObController.text);
                

                if (ObController.text == "") {
                  tex = "Não existem observações";
                } else {
                  tex = ObController.text;
                }
                EndTar(tar[index]['IdTarefa'], tex);
                setState(() {
                  getAllProducts(order.toString());
                });
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => SecondScreen()));
                   
              },
            ),
          ],
        );
      },
    );
  }
}
