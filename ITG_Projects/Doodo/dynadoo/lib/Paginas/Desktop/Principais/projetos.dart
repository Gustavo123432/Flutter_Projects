import 'package:flutter/material.dart';
import '../../../Componentes/drawer.dart';
import '../../../Componentes/drawerWidget.dart';
import '../../../Componentes/gridview.dart';
import '../../../Componentes/logout.dart';
import '../../../Paginas/Desktop/Secundárias/createProjeto.dart';
import '../../../Responsive/responsive_Layout.dart';

class ProjetosDPage extends StatefulWidget {
  @override
  _ProjetosDPageState createState() => _ProjetosDPageState();
}

class _ProjetosDPageState extends State<ProjetosDPage> {
  List<int> _gridItems = [];
  int _itemCount = 0;

  void _addGridItem() {
    setState(() {
      _itemCount++;
      _gridItems.add(_itemCount);
    });
  }

  void _addDrawerAba(int numeroItem) {
    setState(() {
      MyDrawer.abas.add('Item $numeroItem');
      MyDrawer.subAbas['Item $numeroItem'] = ['Dashboard', 'Tarefas'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Projetos'),
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
      body: Row(
        children: [
          // Aqui está o drawer
          DrawerWidget(),
          Expanded(
            child: Center(
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _addGridItem();
          _addDrawerAba(_itemCount);
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CreateProjetoDPage()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

