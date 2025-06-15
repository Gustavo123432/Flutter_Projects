import 'package:flutter/material.dart';
import 'package:appbar_epvc/Admin/produtoPage.dart';
import 'package:appbar_epvc/Aluno/home.dart';
import 'package:appbar_epvc/Aluno/pedidosPageAluno.dart';
import 'package:appbar_epvc/Aluno/reservasPageAluno.dart';
import 'package:appbar_epvc/Aluno/settingsPage.dart';
import 'package:appbar_epvc/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appbar_epvc/Aluno/support_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DrawerHome extends StatefulWidget {
  final Future<void> Function(BuildContext, Widget)? onNavigation;
  const DrawerHome({super.key, this.onNavigation});
  @override
  _DrawerHomeState createState() => _DrawerHomeState();
}

class _DrawerHomeState extends State<DrawerHome> {
  //final _advancedDrawerController = AdvancedDrawerController();
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    if (user == null || user.isEmpty) {
      print('DrawerHome: No username found in SharedPreferences');
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '1',
          'user': user,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
          print('DrawerHome: User data fetched successfully');
        });
      } else {
        print('DrawerHome: Failed to fetch user data: ${response.statusCode}');
      }
    } catch (e) {
      print('DrawerHome: Error fetching user data: $e');
    }
  }

  void _handleNavigation(BuildContext context, Widget destination) {
    if (widget.onNavigation != null) {
      widget.onNavigation!(context, destination);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Pretende Sair?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.orange),
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
              style: TextButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.orange),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String userEmail = (users.isNotEmpty && users[0]['Email'] != null)
        ? users[0]['Email'].toString()
        : 'Email não disponível';

    return Drawer(
      child: Container(
        width: 250, // Defina a largura fixa aqui
        color: Colors.white, // Add consistent background color
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            Container(
              width: 150.0,
              height: 150.0,
              margin: const EdgeInsets.only(
                top: 24.0,
                bottom: 64.0,
              ),
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: Color.fromARGB(66, 255, 255, 255),
                shape: BoxShape.circle,
              ),
              child: Image.asset(
                'lib/assets/barapp.png',
                fit: BoxFit.contain,
              ),
            ),
            ListTile(
              onTap: () {
                _handleNavigation(context, HomeAlunoMain());
              },
              leading: Icon(Icons.home),
              title: Text('Início'),
            ),
            ListTile(
              onTap: () {
                _handleNavigation(context, ShoppingCartPage());
              },
              leading: Icon(Icons.shopping_cart),
              title: Text('Carrinho'),
            ),
            ListTile(
              onTap: () {
                _handleNavigation(context, PedidosPageAlunos());
              },
              leading: Icon(Icons.archive),
              title: Text('Pedidos'),
            ),
            ListTile(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Em Desenvolvimento'),
                    content: Text(
                        'O Restaurante não está disponível no momento.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              leading: Icon(Icons.restaurant),
              title: Text('Reservas'),
            ),
            ListTile(
              onTap: () {
                _handleNavigation(context, SettingsPage());
              },
              leading: Icon(Icons.settings),
              title: Text('Definições'),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                 if (userEmail != 'Email não disponível') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SupportPage(userEmail: userEmail)),
                  );
                } else {
                   ScaffoldMessenger.of(context).showSnackBar(
                     SnackBar(content: Text('Não foi possível obter o seu email. Tente novamente mais tarde.')),
                  );
                }
              },
              leading: Icon(Icons.help_outline),
              title: Text('Suporte'),
            ),
            ListTile(
              onTap: () {
                logout(context);
              },
              leading: Icon(Icons.logout),
              title: Text('Sair'),
            ),
            Spacer(),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
              ),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  vertical: 0.25,
                ),
                child: Text('Terms of Service | Privacy Policy'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
