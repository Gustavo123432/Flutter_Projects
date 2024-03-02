import 'package:Calldo/User/DashboardUsers.dart';
import 'package:Calldo/User/resgistarUsers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:Calldo/Admin/Dashboard/Dashboard.dart';
import 'package:Calldo/Admin/dados.dart';
import 'package:Calldo/Admin/registo.dart';
import 'package:Calldo/Admin/tabela_Users.dart';

class DrawerMainUsers extends StatefulWidget {
  const DrawerMainUsers({super.key});
  @override
  _DrawerMainUsersState createState() => _DrawerMainUsersState();
}

class _DrawerMainUsersState extends State<DrawerMainUsers> {
  //final _advancedDrawerController = AdvancedDrawerController();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Container(
        width: 250, // Defina a largura fixa aqui
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
                'lib/assets/logoCalldo.png',
                fit: BoxFit.contain,
              ),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DashboardUsers()),
                );
              },
              leading: Icon(Icons.home),
              title: Text('Dashboard'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegistarUsers()),
                );
              },
              leading: Icon(Icons.account_circle_rounded),
              title: Text('Users'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Registo()),
                );
              },
              leading: Icon(Icons.archive),
              title: Text('Registos'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Dados()),
                );
              },
              leading: Icon(Icons.sd_card),
              title: Text('Dados'),
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

  /*void _handleMenuButtonPressed() {
    _advancedDrawerController.showDrawer();
  }*/
}
