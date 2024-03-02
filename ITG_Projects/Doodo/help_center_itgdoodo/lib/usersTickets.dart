import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:help_center_itgdoodo/fornewupdate/detailsEmpresa.dart';
import 'package:help_center_itgdoodo/fornewupdate/empresas.dart';
import 'package:help_center_itgdoodo/tickets/finishedTar.dart';
import 'package:help_center_itgdoodo/tickets/finishedTarDetails.dart';
import 'package:http/http.dart' as http;

class UsersTicketsPage extends StatefulWidget {
  @override
  _UsersTicketsPageState createState() => _UsersTicketsPageState();
}

class _UsersTicketsPageState extends State<UsersTicketsPage> {
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
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=16&order=$order'));
    if (response.statusCode == 200) {
      setState(() {
        Users = jsonDecode(response.body) as List;
      });
      length = int.parse(Users.length.toString());

      return Users;
    }
  }

  Future<void> _refreshData() async {
    await getUserList(type);
  }

  List<String> order = <String>['Numero', 'Nome', 'Tipo de User'];
  dynamic orderv;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: Padding(
        padding: const EdgeInsets.all(12),
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
                            type = orderv;
                            getUserList(type);
                          });
                        },
                      )
                    ],
                  ))),
          Expanded(
            child: ListView.builder(
              itemCount: length, // Set the number of items
              itemBuilder: (context, index) {
                return Card(
                  elevation: 3,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.blue,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                            SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  Users[index]['Name'] == null
                                      ? "Error 404"
                                      : Users[index]['Name'],
                                  style: TextStyle(
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
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        // Contact information
                        buildInfoRow(
                            "Email:",
                            Users[index]['Mail'] == null
                                ? "Error 404"
                                : Users[index]['Mail']),
                        buildInfoRow(
                            "Contacto:",
                            Users[index]['Cont'] == null
                                ? "Error 404"
                                : Users[index]['Cont']),
                        buildInfoRow(
                            "Log:",
                            Users[index]['Log'] == null
                                ? "Error 404"
                                : Users[index]['Log']),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (context) => finishedTar()));
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
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ));
  }
}
