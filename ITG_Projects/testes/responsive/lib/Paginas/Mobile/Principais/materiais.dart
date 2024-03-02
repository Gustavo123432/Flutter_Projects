import 'package:flutter/material.dart';
import '../../../Componentes/drawerWidget.dart';
import '../../../Componentes/logout.dart';
import '../../../Componentes/gridview.dart';
import '../Secundárias/criarmaterial.dart';

class MateriaisM extends StatefulWidget {
  @override
  _MateriaisMState createState() => _MateriaisMState();
}

class _MateriaisMState extends State<MateriaisM> {
  List<Map<String, dynamic>> _itens = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: Text('Materiais'),
        elevation: 2,
        shadowColor: Theme.of(context).shadowColor,
        actions: [
          GestureDetector(
            onTap: () {
              LogoutDialog();
            },
            child: const Icon(
              Icons.exit_to_app,
              size: 26.0,
            ),
          ),
        ],
      ),
     drawer: DrawerWidget(),
      body: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Conteúdo da página de materiais
                ],
              ),
            ),
          ],
        ),
    ),
    
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CriaMaterialMPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
