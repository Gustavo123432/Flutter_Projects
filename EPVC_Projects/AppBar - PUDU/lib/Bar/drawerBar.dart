import 'package:flutter/material.dart';
import 'package:my_flutter_project/Bar/barPage.dart';
import 'package:my_flutter_project/Bar/pedidosRegistados.dart';
import 'package:my_flutter_project/Bar/produtoPageBar.dart';
import 'package:my_flutter_project/Bar/restaurantePage.dart';
import 'package:my_flutter_project/Bar/saldoPage.dart';
import 'package:my_flutter_project/BotDelivery/homeBotDelivery.dart';

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
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BarPagePedidos()),
                );
              },
              leading: Icon(Icons.search),
              title: Text('Pedidos'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => PedidosRegistados()),
                );
              },
              leading: Icon(Icons.archive_outlined),
              title: Text('Pedidos Registados'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RestaurantePage()),
                );
              },
              leading: Icon(Icons.restaurant),
              title: Text('Restaurante'),
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
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => SaldoPage()),
                );
              },
              leading: Icon(Icons.account_balance_wallet),
              title: Text('Saldo'),
            ),
            ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomePudu()),
                );
              },
              leading: Image.asset(
                'lib/assets/bellabot_icon.png',
                width: 28,
                height: 28,
              ),
              title: Text('Bot Delivery'),
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
