import 'package:flutter/material.dart';
import 'package:flutter_advanced_drawer/flutter_advanced_drawer.dart';
import 'package:my_flutter_project/Admin/pedidosPage.dart';
import 'package:my_flutter_project/Admin/produtoPage.dart';
import 'package:my_flutter_project/Admin/users.dart';

class DrawerHome extends StatefulWidget {
  const DrawerHome({Key key}) : super(key: key);

  @override
  _DrawerHomeState createState() => _DrawerHomeState();
}

class _DrawerHomeState extends State<DrawerHome> {
  final _advancedDrawerController = AdvancedDrawerController();

  @override
  Widget build(BuildContext context) {
    return AdvancedDrawer(
      controller: _advancedDrawerController,
      backdropColor: Colors.black.withOpacity(0.5),
      child: Scaffold(
        appBar: AppBar(
          title: Text('My App'),
          leading: IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              _advancedDrawerController.showDrawer();
            },
          ),
        ),
        body: Center(
          child: Text('Main Content'),
        ),
        drawer: Drawer(
          child: Container(
            width: 250,
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
                    /*Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Dashboard()),
                    );*/
                  },
                  leading: Icon(Icons.home),
                  title: Text('Dashboard'),
                ),
                ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => UserTable()),
                    );
                  },
                  leading: Icon(Icons.account_circle_rounded),
                  title: Text('Users'),
                ),
                ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => PedidosPage()),
                    );
                  },
                  leading: Icon(Icons.archive),
                  title: Text('Registos'),
                ),
                ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ProdutoPage()),
                    );
                  },
                  leading: Icon(Icons.local_pizza),
                  title: Text('Produtos'),
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
        ),
      ),
    );
  }
}
