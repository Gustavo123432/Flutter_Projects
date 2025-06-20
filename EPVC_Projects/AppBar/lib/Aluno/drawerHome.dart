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
        color: Colors.orange, // Change to orange background
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            

            SizedBox(height: 64), // Space after the close icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Image
                  if (users.isNotEmpty && users[0]['Imagem'] != null && users[0]['Imagem'].isNotEmpty)
                    Container(
                      width: 80.0,
                      height: 80.0,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        image: DecorationImage(
                          image: MemoryImage(base64Decode(users[0]['Imagem'])),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  else
                    Container(
                      width: 80.0,
                      height: 80.0,
                      margin: const EdgeInsets.only(bottom: 16.0),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[200],
                      ),
                      child: Icon(Icons.person, size: 40, color: Colors.grey[600]),
                    ),
                  Text(
                    // Display user's name or a default string
                    users.isNotEmpty && users[0]['Nome'] != null && users[0]['Nome'].isNotEmpty
                        ? (users[0]['Nome'].length > 15 ? '${users[0]['Nome'].substring(0, 15)}...' : users[0]['Nome'])
                        : '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                ],
              ),
            ),
            SizedBox(height: 32), // Space before menu items

            ListTile(
              onTap: () {
                _handleNavigation(context, HomeAlunoMain());
              },
              leading: Icon(Icons.home, color: Colors.white),
              title: Text('Inicio', style: TextStyle(color: Colors.white)),
              selected: true, // Mark as selected
              selectedTileColor: Color.fromARGB(255, 255, 140, 0), // A slightly darker orange for selection
            ),
            ListTile(
              onTap: () {
                _handleNavigation(context, ShoppingCartPage()); // Mapped to My Wallet
              },
              leading: Icon(Icons.shopping_cart, color: Colors.white),
              title: Text('Carrinho', style: TextStyle(color: Colors.white)),
            ),
            /*ListTile(
              onTap: () {
                // TODO: Implement navigation for Notification
              },
              leading: Icon(Icons.notifications, color: Colors.white),
              title: Text('Notification', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              onTap: () {
                // TODO: Implement navigation for Favourite
              },
              leading: Icon(Icons.favorite, color: Colors.white),
              title: Text('Favourite', style: TextStyle(color: Colors.white)),
            ),*/
            Divider(color: Colors.white70, indent: 16, endIndent: 16),

            ListTile(
              onTap: () {
                _handleNavigation(context, PedidosPageAlunos()); // Mapped to Track Your Order
              },
              leading: Icon(Icons.archive, color: Colors.white),
              title: Text('Pedidos', style: TextStyle(color: Colors.white)),
            ),
            /*ListTile(
              onTap: () {
                // TODO: Implement navigation for Coupons
              },
              leading: Icon(Icons.local_activity, color: Colors.white),
              title: Text('Coupons', style: TextStyle(color: Colors.white)),
            ),*/
            ListTile(
              onTap: () {
                _handleNavigation(context, SettingsPage());
              },
              leading: Icon(Icons.settings, color: Colors.white),
              title: Text('Definições', style: TextStyle(color: Colors.white)),
            ),
            /*ListTile(
              onTap: () {
                // TODO: Implement navigation for Invite a Friend
              },
              leading: Icon(Icons.people, color: Colors.white),
              title: Text('Invite a Friend', style: TextStyle(color: Colors.white)),
            ),*/
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
              leading: Icon(Icons.help_center, color: Colors.white),
              title: Text('Suporte', style: TextStyle(color: Colors.white)),
            ),
            ListTile(
              onTap: () {
                logout(context);
              },
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text('Terminar Sessão', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
