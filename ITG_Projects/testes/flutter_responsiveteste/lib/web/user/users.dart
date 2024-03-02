// ignore_for_file: file_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_responsiveteste/web/user/createUser.dart';
import 'package:http/http.dart' as http;


class usersPage extends StatefulWidget {
  const usersPage({super.key});

  @override
  _UsersPageState createState() => _UsersPageState();
}

class _UsersPageState extends State<usersPage> {
  dynamic Users;
  dynamic U_Image;

  int length = 0;
  dynamic type = 'all';

  @override
  void initState() {
    getUserList('all');
    _fetchAllImageData();
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

  Future<void> _fetchAllImageData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://services.interagit.com/API/api_Calendar.php?query_param=8'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> imageList = json.decode(response.body);

        setState(() {
          U_Image = List<Map<String, dynamic>>.from(imageList);
        });
      } else {
        print('Failed to load image data. Error ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching image data: $e');
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            ClipOval(
                              child: U_Image != null
                                  ? (index < length
                                      ? Image.memory(
                                          base64.decode(
                                              U_Image[index]['imageData']),
                                          fit: BoxFit.cover,
                                          height: 100,
                                          width: 100,
                                        )
                                      : const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 100,
                                        ))
                                  : const Icon(
                                      Icons.person,
                                      color: Colors.white,
                                      size: 100,
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                  ),
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
