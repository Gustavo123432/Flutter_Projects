import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Drawer com Aba Personalizada',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String nomeUsuario = "";
  TextEditingController controller = TextEditingController();

  List<DrawerItem> drawerItems = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Drawer com Aba Personalizada'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Nome do usuário'),
                onChanged: (value) {
                  setState(() {
                    nomeUsuario = value;
                  });
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (nomeUsuario.isNotEmpty) {
                  setState(() {
                    drawerItems.add(DrawerItem(nome: nomeUsuario, subItems: [
                      SubItem(nome: "Dashboard"),
                      SubItem(nome: "Tarefas"),
                    ]));
                  });
                }
              },
              child: const Text('Adicionar Categoria no Drawer'),
            ),
          ],
        ),
      ),
      drawer: DrawerWidget(drawerItems: drawerItems),
    );
  }
}

class DrawerItem {
  final String nome;
  final List<SubItem> subItems;

  DrawerItem({required this.nome, required this.subItems});
}

class SubItem {
  final String nome;

  SubItem({required this.nome});
}

class DrawerWidget extends StatelessWidget {
  final List<DrawerItem> drawerItems;

  const DrawerWidget({required this.drawerItems});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Meu Aplicativo',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          for (var item in drawerItems)
            ExpansionTile(
              title: Text(item.nome),
              children: <Widget>[
                for (var subItem in item.subItems)
                  ListTile(
                    title: Text(subItem.nome),
                    onTap: () {
                      // Lógica para navegar para a tela correspondente
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
