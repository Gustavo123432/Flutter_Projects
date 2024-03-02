import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_itg/web/Tarefas/editTar.dart';
import 'package:todo_itg/web/Tarefas/finishedTarDetails.dart';
import 'package:todo_itg/web/web.dart';

class finishedTar extends StatefulWidget {
  @override
  _finishedTarState createState() => _finishedTarState();
}

class _finishedTarState extends State<finishedTar> {
  final TextEditingController ReopenController = TextEditingController();
  dynamic tar;
  int length = 0;
  late String tex;
  List<String> order = <String>[
    'N Tarefa',
    'Titulo',
    'Prioridade',
    'Atribuido',
    'Minhas'
  ];
  dynamic orderv;
  final TextEditingController ObController = TextEditingController();
  late String texReopen;

  getAllProducts(String order) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    String pedido = 'all';
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

  Future<void> _refreshData() async {
    await getAllProducts(orderv.toString());
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
                            });
                          },
                        )
                      ],
                    ))),
            Expanded(
              child: length == 0
                  ? Center(
                      child:
                          Text("Neste Momento não existem tarefas Finalizadas"),
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
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                              CircleAvatar(child: Text(tar[index]['CodUser'])),
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
                                prioo: tar[index]['Priority'],
                                tipoTarefa: 1,
                                numberOfButtons: 1,
                                mainButtonCallback: () {
                                  _showAlertDialog(context, index);
                                },
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

  void _showAlertDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deseja fazer mudanças na Tarefa?'),
          content: Text(
              "AO carregar sim pode fazer qulquer tipo de mudaça na tarefa antes de a reabrir"),
          actions: [
            TextButton(
              child: const Text('Sim'),
              onPressed: () {
                //adicionar função para quando a pessoa carrega n cancelar ela no finalizar a tarefa(não fazer nada)
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => editTarDetails(
                    id: tar[index]['IdTarefa'],
                    title: tar[index]['Titulo'],
                    subtitle: tar[index]['Descrip'],
                    coduser: tar[index]['CodUser'],
                    prio: tar[index]['Priority'],
                    numberOfButtons: 0,
                    mainButtonCallback: () {},
                    extraButtonCallback: () {
                      // Ação para o botão extra na página "Começadas"
                      // Implemente a ação específica para este botão na página "Começadas"
                    },
                  ),
                )); // Fecha o AlertDialog
              },
            ),
            TextButton(
              child: const Text('Não'),
              onPressed: () async {
                //print(ObController.text);
                _showAlertDialogReopen(index);
              },
            ),
          ],
        );
      },
    );
  }

  void _showAlertDialogReopen(dynamic index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Motivo para Reabertura de tarefa:'),
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
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                //print(ObController.text);

                if (ObController.text == "") {
                  texReopen = "Não existem observações";
                } else {
                  texReopen = ObController.text;
                }
                ResetTar(
                    tar[index]['IdTarefa'],
                    tar[index]['Titulo'],
                    tar[index]['Descrip'],
                    tar[index]['CodUser'],
                    tar[index]['Priority'],
                    texReopen);
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>  WebPage(title: 'Tarefas'),
                ));
              },
            ),
          ],
        );
      },
    );
  }
}

void ResetTar(dynamic idtar, dynamic title, dynamic descrip, dynamic coduser,
    dynamic prio, dynamic reopen) async {
  await http.get(Uri.parse(
      'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=18&id=$idtar&title=$title&descrip=$descrip&user=$coduser&prio=$prio&reopen=$reopen'));
}
