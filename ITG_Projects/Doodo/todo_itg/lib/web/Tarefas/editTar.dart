import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:todo_itg/web/Tarefas/finishedTar.dart';
import 'package:todo_itg/web/web.dart';

// ignore: must_be_immutable
class editTarDetails extends StatefulWidget {
  dynamic id, title, subtitle, coduser, prio;

  int numberOfButtons;
  dynamic det;
  final void Function() mainButtonCallback;
  final void Function() extraButtonCallback;
  editTarDetails({
    super.key,
    required this.id,
    this.title,
    this.subtitle,
    this.prio,
    this.coduser,
    this.numberOfButtons = 1,
    required this.mainButtonCallback,
    this.extraButtonCallback = _defaultExtraButtonCallback,
  });

  static void _defaultExtraButtonCallback() {
    // Implemente uma ação padrão para o botão extra, ou deixe vazio
  }

  @override
  // ignore: library_private_types_in_public_api
  _editTarDetailsState createState() => _editTarDetailsState();
}

// ignore: camel_case_types
class _editTarDetailsState extends State<editTarDetails> {
  dynamic user, nome = 'Nome';
  final TextEditingController ObController = TextEditingController();
  late String texReopen;
  getUser(dynamic id) async {
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=13&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        user = json.decode(response.body);
      });
      nome = user[0]['Name'];
      selectedOption = id;
      if (widget.prio == '0') {
        orderv = 'Normal';
      } else if (widget.prio == '1') {
        orderv = 'Prioritária';
      } else {
        orderv = 'Urgente';
      }

      return user;
    }
  }

  List Users = [];
  String selectedOption = '1';
  List<String> priority = <String>['Normal', 'Prioritária', 'Urgente'];
  dynamic orderv;

  getUserList() async {
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=9'));
    if (response.statusCode == 200) {
      setState(() {
        Users = jsonDecode(response.body) as List;
      });
      return Users;
    }
  }

  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  bool isEditingTitle = false;
  bool isEditingSubtitle = false;

  @override
  void initState() {
    getUser(widget.coduser);
    _titleController = TextEditingController(text: widget.title);
    _subtitleController = TextEditingController(text: widget.subtitle);
    getUserList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Reabrir Tarefa'),
      ),
      backgroundColor: Colors.blueGrey[50],
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                child: Container(
                  color: Colors.white,
                  width: 500,
                  height: 500,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap the CircleAvatar and Title in a Row
                      const Text(
                        "Titulo",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (isEditingTitle)
                            Expanded(
                              child: TextField(
                                controller: _titleController,
                                onEditingComplete: saveTitle,
                              ),
                            )
                          else
                            Expanded(
                              child: Text(
                                _titleController.text,
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                isEditingTitle = !isEditingTitle;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      const Text(
                        "Descrição:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (isEditingSubtitle)
                            Expanded(
                              child: TextField(
                                controller: _subtitleController,
                                onEditingComplete: saveSubtitle,
                              ),
                            )
                          else
                            Expanded(
                              child: Text(
                                _subtitleController.text,
                                style: TextStyle(fontSize: 18.0),
                              ),
                            ),
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                isEditingSubtitle = !isEditingSubtitle;
                              });
                            },
                          ),
                        ],
                      ),

                      DropdownButton(
                        value: selectedOption,
                        icon: const Icon(Icons.expand_more),
                        elevation: 16,
                        style: const TextStyle(color: Colors.black),
                        underline: Container(
                          height: 2,
                          color: Colors.blue,
                        ),
                        items: Users.map(
                          (category) {
                            return DropdownMenuItem(
                              value: category['IdUser'].toString(),
                              child: Text(category['Name'].toString()),
                            );
                          },
                        ).toList(),
                        onChanged: (v) {
                          setState(() {
                            selectedOption = v.toString();
                            //print(selectedOption);
                          });
                        },
                      ),
                      DropdownButton<String>(
                        value: orderv,
                        //hint: Text('Escolha a opção'),
                        icon: const Icon(Icons.expand_more),
                        elevation: 16,
                        style: const TextStyle(color: Colors.black),
                        underline: Container(
                          height: 2,
                          color: orderv == 'Normal'
                              ? Colors.blue
                              : orderv == 'Prioritária'
                                  ? Colors.yellow
                                  : Colors.red,
                        ),
                        items: priority
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
                      ),

                      ElevatedButton(
                        onPressed: () {
                          _showAlertDialogReopen();
                        },
                        child: const Text('Reabrir Tarefa'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void startEditingTitle() {
    setState(() {
      isEditingTitle = true;
    });
  }

  void saveTitle() {
    setState(() {
      isEditingTitle = false;
    });
  }

  void startEditingSubtitle() {
    setState(() {
      isEditingSubtitle = true;
    });
  }

  void saveSubtitle() {
    setState(() {
      isEditingSubtitle = false;
    });
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
  }

  void _showAlertDialogReopen() {
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
                if (orderv == 'Prioritária') {
                  orderv = 1;
                } else if (orderv == 'Urgente') {
                  orderv = 2;
                } else {
                  orderv = 0;
                }

                ResetTar(
                    widget.id,
                    _titleController.text,
                    _subtitleController.text,
                    selectedOption,
                    orderv,
                    texReopen);
                showSnackBar('Tarefa reaberta com sucesso.');
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => WebPage(title: 'Tarefas'),
                ));
              },
            ),
          ],
        );
      },
    );
  }
}
