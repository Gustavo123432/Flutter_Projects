// ignore_for_file: file_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

String errorMessage = '';

class createTar extends StatefulWidget {
  @override
  _createTarState createState() => _createTarState();
}

class _createTarState extends State<createTar> {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _descriptionController = TextEditingController();
  List Users = [];
  String selectedOption = '1';
  List<String> priority = <String>['Normal', 'Prioritária', 'Urgente'];
  dynamic orderv = 'Normal';

  getUserList() async {
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=4'));
    if (response.statusCode == 200) {
      setState(() {
        Users = jsonDecode(response.body) as List;
        
      });
      return Users;
    }
  }

  createTar(String Title, String Descrip, int id, dynamic prio) async {
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=8&title=$Title&descrip=$Descrip&id=$id&prio=$prio'));
    if (response.statusCode == 200) {
      setState(() {
        Users = jsonDecode(response.body) as List;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getUserList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Criar Tarefa'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Card(
                    elevation: 3,
                    child: Container(
                      color: Colors.white,
                      width: 400,
                      height: 350,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 350,
                            child: TextField(
                              controller: _titleController,
                              decoration: const InputDecoration(
                                labelText: 'Coloque um Título',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          SizedBox(
                            width: 350,
                            child: TextField(
                              controller: _descriptionController,
                              keyboardType: TextInputType.multiline,
                              maxLines: 4,
                              decoration: const InputDecoration(
                                labelText: 'Coloque uma Descrição',
                                border: OutlineInputBorder(),
                              ),
                            ),
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
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              // Print the entered data to the console
                              _emptyFields();
                            },
                            child: const Text('Criar Tarefa'),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ));
  }

  void _emptyFields() async {
    final title = _titleController.text;
    final description = _descriptionController.text;

    if (title.isEmpty || description.isEmpty) {
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Preencha todos os campos',
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
        backgroundColor: Colors.red, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else {
      createTar(title, description, int.parse(selectedOption), orderv);
     
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Tarefa criada',
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

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
