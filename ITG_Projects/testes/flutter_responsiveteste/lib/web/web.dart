// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously
import 'dart:convert';
import 'package:flutter_responsiveteste/main.dart';
import 'package:flutter_responsiveteste/web/Tarefas/calendarUser.dart';
import 'package:flutter_responsiveteste/web/user/changeUserInfo.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'user/users.dart';

import 'Tarefas/defaultTar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

class Event {
  final String title;
  final String description;
  final DateTime from;
  final DateTime to;

  const Event({
    required this.title,
    required this.description,
    required this.from,
    required this.to,
  });
}

class WebPage extends StatefulWidget {
  const WebPage({super.key, required this.title});
  final String title;
  @override
  // ignore: library_private_types_in_public_api
  _WebPageState createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  int _selectedIndex = 0;
  String _imageData = '';

  dynamic length = 0;
  dynamic user, nome = 'Nome', mail = 'Mail';
  String _page_title = "Calendário";

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        _page_title = "Calendário";
      } else if (index == 1) {
        _page_title = "Calendários 2";
      } else if (index == 2) {
        _page_title = "Funcionários";
      }
      _selectedIndex = index;
    });
  }

  Future<void> _fetchImageData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    try {
      final response = await http.get(Uri.parse(
          'https://services.interagit.com/API/api_Calendar.php?query_param=3&imageName=$id.png'));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        setState(() {
          _imageData = data['imageData'];
        });
      } else {
        print('Failed to load image data. Error ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching image data: $e');
    }
  }

  getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');

    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=2&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        user = json.decode(response.body);
      });
      nome = user[0]['name'];
      mail = user[0]['mail'];
      //print('$nome e $mail');
      return user;
    }
  }

  @override
  Widget build(BuildContext context) {
    [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      SfGlobalLocalizations.delegate,
    ];
    [
      const Locale('pt'),
    ];
    const Locale('pt');
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _page_title,
              style: const TextStyle(color: Colors.white),
            ),
            const SizedBox(
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
                    _showAlertDialog(context);
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
      body: _buildPage(_selectedIndex),
      drawer: Drawer(
        child: Column(
          children: [
            buildHeader(
              context,
              nome: nome,
              mail: mail,
            ),

            Card(
              elevation: 10,
              child: Column(
                children: <Widget>[
                  ExpansionTile(
                    title: const Text("Calendários"),
                    initiallyExpanded: true,
                    leading: const Icon(Icons.calendar_today),
                    childrenPadding: const EdgeInsets.only(left: 60),
                    children: [
                      ListTile(
                        leading: const Icon(Icons.calendar_month),
                        title: const Text(
                          'Calendário',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _selectedIndex == 0,
                        onTap: () {
                          _onItemTapped(0);
                          Navigator.pop(context);
                        },
                      ),
                      const Divider(height: 12),
                      ListTile(
                        leading: const Icon(Icons.perm_contact_calendar),
                        title: const Text(
                          'calendario por Users',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _selectedIndex == 1,
                        onTap: () {
                          _onItemTapped(1);
                          Navigator.pop(context);
                        },
                      ),
                    ],
                  ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text(
                      'Funcionários',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      _onItemTapped(2);
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 16), // Adiciona espaçamento vertical
                ],
              ),
            ),
            const Spacer(),
            // Adicione margem ao botão no final do Drawer
            /*Container(
              margin: EdgeInsets.only(
                  bottom: 16), // Adicione a margem inferior desejada
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ticketsPage(),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  primary: Colors.blue, // Cor de fundo do botão
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8.0), // Borda arredondada
                  ),
                ),
                child: Text(
                  'Help Center',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            )*/
          ],
        ),
      ),
    );
  }

  Widget buildHeader(
    BuildContext context, {
    required String nome,
    required String mail,
  }) =>
      Material(
        color: Colors.blue,
        child: InkWell(
          child: Column(
            children: [
              const SizedBox(
                height: 5,
                width: double.infinity,
              ),
              ClipOval(
                child: _imageData.isNotEmpty
                    ? Image.memory(
                        base64.decode(_imageData),
                        fit: BoxFit.cover,
                        height: 100,
                        width: 100,
                      )
                    : const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 100,
                      ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: const TextStyle(fontSize: 20, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mail,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                  ),
                ],
              ),
              Column(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.transparent,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => const changeUserInfo(),
                        ));
                      },
                      child: const Icon(
                        Icons.settings,
                        size: 26.0,
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      );

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return defaultTar();
      case 1:
        return calendarUsersPage();
      case 2:
        return usersPage();
      default:
        return Container(); 
    }
  }

  @override
  void initState() {
    getUser();
    super.initState();
    _fetchImageData();
  }
}

void _showAlertDialog(BuildContext context) {
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
