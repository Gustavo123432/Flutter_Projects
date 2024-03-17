import 'package:flutter/material.dart';
import 'package:my_flutter_project/Admin/produtoPage.dart';
import 'package:my_flutter_project/Aluno/home.dart';
import 'package:my_flutter_project/Aluno/pedidosPageAluno.dart';
import 'package:my_flutter_project/Bar/barPage.dart';
import 'package:my_flutter_project/Bar/produtoPageBar.dart';

class DrawerBar extends StatefulWidget {
  const DrawerBar({super.key});
  @override
  _DrawerBarState createState() => _DrawerBarState();
}

class _DrawerBarState extends State<DrawerBar> {
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
                'lib/assets/barapp.png',
                fit: BoxFit.contain,
              ),
              
            ),
            /*ListTile(
              onTap: () {
                /*Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Dashboard()),
                );*/
              },
              leading: Icon(Icons.home),
              title: Text('Dashboard'),
            ),*/
            /*ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeAlunoMain()),
                );
              },
              leading: Icon(Icons.home),
              title: Text('Home'),
            ),*/
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BarPagePedidos()),
                );
              },
              leading: Icon(Icons.archive),
              title: Text('Pedidos'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProdutoPageBar()),
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
    );
  }

  /*void _handleMenuButtonPressed() {
    _advancedDrawerController.showDrawer();
  }*/
}
