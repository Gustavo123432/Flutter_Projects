import 'dart:convert';
import 'package:Calldo/login.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:Calldo/Drawer/drawerMain.dart';

void main() {
  runApp(Dashboard());
}

class Dashboard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dashboard - Calldo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        appBarTheme: AppBarTheme(
          color: Colors.red,
          iconTheme: IconThemeData(
              color: Colors.white), // ícones da AppBar serão brancos
        ),
        textTheme: TextTheme(
           
              TextStyle(color: Colors.white), // texto da AppBar será branco
        ),
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  dynamic users;

  @override
  void initState() {
    super.initState();
    // Chame a função UserInfo quando o widget for inicializado
    UserInfo();
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://services.interagit.com/registarCallAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    }
  }

  void logout(BuildContext context) {
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
                await prefs.clear();

                // ignore: use_build_context_synchronously
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext ctx) => const LoginForm()));
                ModalRoute.withName('/');
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
        backgroundColor: Colors.red,
        title: Row(
          children: [
            ClipOval(
              child: users != null && users.toString() != "null"
                  ? users[0]['Imagem'] != null &&
                          users[0]['Imagem'].toString() != "null"
                      ? Image.memory(
                          base64.decode(users[0]['Imagem']),
                          fit: BoxFit.cover,
                          height: 50,
                          width: 50,
                        )
                      : Icon(
                          Icons.person,
                          size: 47,
                        )
                  : Icon(
                      Icons.person,
                      size: 47,
                    ),
            ),
            SizedBox(
              width: 8,
            ),
            users != null && users.toString() != "null"
                ? Text(
                    'Bem Vindo(a): ' +
                        users[0]['Nome'] +
                        " " +
                        users[0]['Apelido'],
                    style: TextStyle(color: Colors.white), // Texto será branco
                  )
                : Text(""),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      drawer: DrawerMain(),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DashboardItem(
              title: 'Item 1',
              icon: Icons.home,
              onPressed: () {
                // Adicione funcionalidade para o item 1
              },
            ),
            DashboardItem(
              title: 'Item 2',
              icon: Icons.notifications,
              onPressed: () {
                // Adicione funcionalidade para o item 2
              },
            ),
            DashboardItem(
              title: 'Item 3',
              icon: Icons.settings,
              onPressed: () {
                // Adicione funcionalidade para o item 3
              },
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardItem extends StatelessWidget {
  final String title;
  final IconData icon;
  final Function onPressed;

  DashboardItem(
      {required this.title, required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 100,
      child: ElevatedButton.icon(
        onPressed: () {
          onPressed();
        },
        icon: Icon(icon),
        label: Text(title),
      ),
    );
  }
}
