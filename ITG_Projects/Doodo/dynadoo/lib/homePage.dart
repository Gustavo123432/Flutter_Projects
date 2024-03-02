import 'package:flutter/material.dart';


import 'Componentes/drawer.dart';
import 'Paginas/Desktop/loginD.dart';
import 'Paginas/Mobile/loginM.dart';
import 'Paginas/tablet/loginT.dart';
import 'Responsive/responsive_Layout.dart';

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
