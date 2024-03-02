import 'package:flutter/material.dart';
import 'package:responsive/Componentes/drawerWidget.dart';
import 'package:responsive/Paginas/Desktop/loginD.dart';
import 'package:responsive/Paginas/Mobile/loginM.dart';
import 'package:responsive/Paginas/tablet/loginT.dart';
import 'package:responsive/Responsive/responsive_Layout.dart';
import 'package:responsive/Componentes/drawer.dart'; // Importe o seu MyDrawer

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    
      body: ResponsiveLayoutPage(
        mobileBody: LoginFormM(),
        tabletBody: LoginFormT(),
        desktopBody: LoginFormD(),
        builder: (context, layout) {
          return MyDrawer(currentLayoutType: layout.toString());
        },
      ),
    );
  }
}
