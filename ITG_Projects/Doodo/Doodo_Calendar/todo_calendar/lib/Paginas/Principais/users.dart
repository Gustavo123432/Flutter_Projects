// ignore_for_file: file_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_itg/Paginas/Secundarias/Users/changePass.dart';

import 'package:todo_itg/Paginas/Secundarias/Users/createUser.dart';

import '../../Componentes/drawer.dart';
import '../../login.dart';
import '../Secundarias/Users/changeUserInfoADM.dart';

class usersPage extends StatefulWidget {
  const usersPage({super.key});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<usersPage> {
  dynamic Users;
  int length = 0;
  dynamic type = 'all';

  @override
  void initState() {
    getUserList('all');

    super.initState();
  }

  getUserList(String order) async {
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=4&order=$order'));
    if (response.statusCode == 200) {
      setState(() {
        Users = jsonDecode(response.body) as List;
      });
      length = int.parse(Users.length.toString());
      return Users;
    }
  }

  DeleteUser(String id) async {
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=7&id=$id'));
  }

  Future<void> _refreshData() async {
    await getUserList(type);
  }

  List<String> order = <String>['Numero', 'Nome', 'Tipo de User'];
  dynamic orderv;
  void _showAlertDialog(int id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Deseja eleminar este user da sua lista?'),
          content: const Text("algun texto ainda tenho de pensar"),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            ElevatedButton(
              onPressed: () {
                DeleteUser(id.toString());
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => const usersPage()));
              },
              child: const Text("Confirmar"),
            ),
          ],
        );
      },
    );
  }

  void _logoutshowAlertDialog(BuildContext context) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Funcionários",
              style: TextStyle(color: Colors.white),
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
                    _logoutshowAlertDialog(context);
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
      backgroundColor: Colors.blueGrey[50],
      drawer: const MyDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: <Widget>[
          Card(
              child: SizedBox(
                  height: 60,
                  child: Row(
                    children: [
                      const Text('    Ordenar por  '),
                      DropdownButton<String>(
                        value: orderv,
                        hint: const Text('Escolha a opção'),
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
                            type = orderv;
                            getUserList(type);
                          });
                        },
                      )
                    ],
                  ))),
          Expanded(
            child: ListView.builder(
              itemCount:
                  length, // Assuming Users and U_Image have the same length
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  child: Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  ClipOval(
                                      child: Users[index]['UImage']
                                                  .toString() !=
                                              "null"
                                          ? (index < length
                                              ? Image.memory(
                                                  base64.decode(
                                                      Users[index]['UImage']),
                                                  fit: BoxFit.cover,
                                                  height: 100,
                                                  width: 100,
                                                )
                                              : CircleAvatar(
                                                  backgroundColor: Color(
                                                      int.parse(
                                                              Users[index]
                                                                  ['Color'],
                                                              radix: 16) +
                                                          0xFF000000),
                                                  radius:
                                                      50, // Half of the desired size
                                                  child: const Icon(
                                                    Icons.person,
                                                    color: Colors.white,
                                                    size: 70,
                                                  ),
                                                ))
                                          : CircleAvatar(
                                              backgroundColor: Color(int.parse(
                                                      Users[index]['Color'],
                                                      radix: 16) +
                                                  0xFF000000),
                                              radius:
                                                  50, // Half of the desired size
                                              child: const Icon(
                                                Icons.person,
                                                color: Colors.white,
                                                size: 70,
                                              ),
                                            )),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        Users[index]['Name'] ?? "Error 404",
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        Users[index]['Type'] == "1"
                                            ? "Admin"
                                            : Users[index]['Type'] == "0"
                                                ? "User"
                                                : "ds",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Contact information
                              buildInfoRow(
                                "Email:",
                                Users[index]['Mail'] ?? "Error 404",
                              ),
                              buildInfoRow(
                                "Contacto:",
                                Users[index]['Cont'] ?? "Error 404",
                              ),
                              buildInfoRow(
                                "Log:",
                                Users[index]['Log'] ?? "Error 404",
                              ),
                            ],
                          ),
                          const Spacer(),
                          Column(
                            children: [
                              SizedBox(
                                width: 150,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return MyFormDialogPage(
                                          id: Users[index]['IdUser'],
                                          name: Users[index]['Name'],
                                          log: Users[index]['Log'],
                                          mail: Users[index]['Mail'],
                                          num: Users[index]['Cont'],
                                          type: Users[index]['Type'],
                                          color: Users[index]['Color'],
                                          image: Users[index]['UImage'],
                                        ); // Chame a nova página com o AlertDialog
                                      },
                                    );
                                  },
                                  child: const Text('Alterar User'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 150,
                                child: ElevatedButton(
                                  onPressed: () {
                                    _showAlertDialog(
                                        int.parse(Users[index]['IdUser']));
                                  },
                                  child: const Text("Apagar User"),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 150,
                                child: ElevatedButton(
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return changePassDialogPage(
                                            id: int.parse(
                                                Users[index]['IdUser']));
                                      },
                                    );
                                  },
                                  child: const Text("Alterar PassWord"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                );
              },
            ),
          )
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const CreateUser(),
          ));
        },
        child: const Icon(Icons.add), // You can change the icon as needed
      ),
    );
  }

  Widget buildInfoRow(String label, String value) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ));
  }
}
