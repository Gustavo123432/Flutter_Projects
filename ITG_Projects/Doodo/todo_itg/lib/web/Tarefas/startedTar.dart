import 'dart:convert';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_itg/web/Tarefas/finishedTar.dart';
import 'package:todo_itg/web/Tarefas/finishedTarDetails.dart';
import 'package:todo_itg/web/web.dart';
import 'finishedTar.dart';



class startedTar extends StatefulWidget {
  @override
  _startedTarState createState() => _startedTarState();
}

class _startedTarState extends State<startedTar> {
  final TextEditingController ObController = TextEditingController();

  dynamic tar;
  int length = 0;
      late  String tex;
  List<String> order = <String>[
    'N Tarefa',
    'Titulo',
    'Prioridade',
    'Atribuido',
    'Minhas'
  ];
  dynamic orderv;

  getAllProducts(String order) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic idd = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        "http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=11&order=$order&id=$idd"));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  // ignore: non_constant_identifier_names
  void CancelTar(dynamic id) async {
    await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=6&id=$id'));
    getAllProducts(orderv.toString());
    setState(() {});
  }

  // ignore: non_constant_identifier_names
  void EndTar(dynamic id, String det) async {
    await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=7&id=$id&det=$det'));
    getAllProducts(orderv.toString());
    setState(() {});
  }
 @override
  void dispose() {
    ObController.clear();
    super.dispose();
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
                            getAllProducts(orderv.toString());
                            print(value);
                          });
                        },
                      )
                    ],
                  ))),
          Expanded(
            child: length ==0 
           ? Center(child: Text("Neste Momento não existem tarefas Iniciadas"),)
            :ListView.builder(
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
                              getAllProducts(orderv.toString());
                            });
                          },
                        backgroundColor: Colors.green,
                        icon: Icons.done,
                        label: 'Terminar',
                      ),
                      SlidableAction(
                        onPressed: (context) {
                                 showSnackBar('Tarefa cancelada com sucesso.');
                          CancelTar(tar[index]['IdTarefa']);
                          setState(() {
                            getAllProducts(orderv.toString());
                          
                          });
                        },
                        backgroundColor: Colors.red,
                        icon: Icons.cancel,
                        label: 'Cancelar',
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: Row(
                      mainAxisSize:
                          MainAxisSize.min, // Ensure minimal horizontal space
                      children: [
                        tar[index]['Priority'] == '2'
                            ? CircleAvatar(child: Icon(Icons.report_problem))
                            : tar[index]['Priority'] == '1'
                                ? CircleAvatar(
                                    child: Icon(Icons.report_gmailerrorred))
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
                      mainAxisSize:
                          MainAxisSize.min, // Ensure minimal horizontal space
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(
                              right: 10.0), // Adjust the padding as needed
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
                          tipoTarefa: 2,
                            numberOfButtons: 2,
                                     mainButtonCallback: () {
                                         _showAlertDialog(context, index);
               
      },
      
      extraButtonCallback: () {
               showSnackBar('Tarefa cancelada com sucesso.');
                      CancelTar(tar[index]['IdTarefa']);
                            setState(() {
                              getAllProducts(orderv.toString());
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
    getAllProducts('all');
    
    super.initState();
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
              
                Navigator.of(context).pop();
               // Fecha o AlertDialog
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
                 getAllProducts(orderv.toString());
                });
                      Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => WebPage(title: '3'),
              ));
                showSnackBar('Tarefa concluída com sucesso.');
              },
            ),
          ],
        );
      },
    );
  }
}

