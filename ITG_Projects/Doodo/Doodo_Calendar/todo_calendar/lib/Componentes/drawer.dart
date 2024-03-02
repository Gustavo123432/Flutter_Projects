import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:todo_itg/Paginas/Principais/calendarUser.dart';
import 'package:todo_itg/Paginas/Principais/defaultTar.dart';
import 'package:todo_itg/Paginas/Principais/users.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({super.key});

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  dynamic user, nome = 'Nome', mail = 'Mail';
  String _imageData = '';

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
      return user;
    }
  }

  Future<void> _fetchImageData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic data;
    try {
      final response = await http.get(Uri.parse(
          'https://services.interagit.com/API/api_Calendar.php?query_param=20&id=$id'));

      if (response.statusCode == 200) {
        data = json.decode(response.body);

        setState(() {
          _imageData = data[0]['UImage'];
        });
      } else {
        print('Failed to load image data. Error ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching image data: $e');
    }
  }

  @override
  void initState() {
    getUser();
    super.initState();
    _fetchImageData();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    defaultTar(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = 0.0;
                              const end = 1.0;
                              const curve = Curves.easeInOut;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              var opacityAnimation = animation.drive(tween);

                              return FadeTransition(
                                opacity: opacityAnimation,
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                          ),
                        );
                      },
                    ),
                    const Divider(height: 12),
                    ListTile(
                      leading: const Icon(Icons.perm_contact_calendar),
                      title: const Text(
                        'Calendário por Usuários',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    calendarUsersPage(),
                            transitionsBuilder: (context, animation,
                                secondaryAnimation, child) {
                              const begin = 0.0;
                              const end = 1.0;
                              const curve = Curves.easeInOut;

                              var tween = Tween(begin: begin, end: end)
                                  .chain(CurveTween(curve: curve));
                              var opacityAnimation = animation.drive(tween);

                              return FadeTransition(
                                opacity: opacityAnimation,
                                child: child,
                              );
                            },
                            transitionDuration:
                                const Duration(milliseconds: 500),
                          ),
                        );
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
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const usersPage(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = 0.0;
                          const end = 1.0;
                          const curve = Curves.easeInOut;

                          var tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          var opacityAnimation = animation.drive(tween);

                          return FadeTransition(
                            opacity: opacityAnimation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16), // Adiciona espaçamento vertical
              ],
            ),
          ),
        ],
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
            ],
          ),
        ),
      );
}
