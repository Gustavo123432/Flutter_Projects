import 'package:flutter/material.dart';
import '../../../Componentes/drawerWidget.dart';
import '../../../Componentes/logout.dart';
import '../../../Componentes/gridview.dart';
import '../Secundárias/createProjeto.dart';

class ProjetosMPage extends StatefulWidget {
  @override
  _ProjetosMPageState createState() => _ProjetosMPageState();
}

class _ProjetosMPageState extends State<ProjetosMPage> {
  List<int> _gridItems = [];
  int _itemCount = 0;

  void _addGridItem() {
    setState(() {
      _itemCount++;
      _gridItems.add(_itemCount);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Projetos'),
        actions: [
          IconButton(
            icon: Icon(Icons.exit_to_app),
            onPressed: () {
              LogoutDialog.show(context);
            },
          ),
        ],
      ),
    drawer: DrawerWidget(),
      body: Center(
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 1.0,
            mainAxisSpacing: 1.0,
            childAspectRatio: 1.4,
          ),
          itemCount: _gridItems.length,
          itemBuilder: (BuildContext context, int index) {
            return GridItem(_gridItems[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addGridItem();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateProjetoMPage()),
          );
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
