import 'package:flutter/material.dart';
import 'package:appbar_epvc/Bar/barPage.dart';
import 'package:appbar_epvc/Bar/pedidosRegistados.dart';
import 'package:appbar_epvc/Bar/pedidosRegistados.dart';
import 'package:appbar_epvc/Bar/produtoPageBar.dart';
import 'package:appbar_epvc/Bar/restaurantePage.dart';
import 'package:appbar_epvc/Bar/saldoPage.dart';

class DrawerBar extends StatefulWidget {
  const DrawerBar({super.key});
  @override
  _DrawerBarState createState() => _DrawerBarState();
}

class _DrawerBarState extends State<DrawerBar> {
  //final _advancedDrawerController = AdvancedDrawerController();


    Future<String?> _showUnavaiable() async{
return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Restaurante em Desenvolvimento'),
          content: Text(
              'A parte do Restaurante encontra-se em desenvolvimento'),
          actions: [
            TextButton(
              onPressed: () { Navigator.of(context).pop(); /*Navigator.of(context).pop();*/},
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('OK'),
            ),
          ],
        ),
      );
  }


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
                  MaterialPageRoute(builder: (context) => PedidosRegistadosPage()),
                );
              },
              leading: Icon(Icons.history),
              title: Text('Histórico de Pedidos'),
            ),
            ListTile(
              onTap: () {
                _showUnavaiable();
                /*Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RestaurantePage()),
                );*/
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
