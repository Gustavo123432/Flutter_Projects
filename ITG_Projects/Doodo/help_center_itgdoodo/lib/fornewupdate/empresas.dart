// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously
import 'dart:convert';
import 'package:help_center_itgdoodo/fornewupdate/createEmpresa.dart';
import 'package:help_center_itgdoodo/fornewupdate/detailsEmpresa.dart';
import 'package:help_center_itgdoodo/fornewupdate/empresaD.dart';
import 'package:help_center_itgdoodo/usersTickets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmpresasPage extends StatefulWidget {
  const EmpresasPage({super.key, required this.title});
  final String title;
  @override
  // ignore: library_private_types_in_public_api
  _EmpresasPageState createState() => _EmpresasPageState();
}

class _EmpresasPageState extends State<EmpresasPage> {
  int _selectedIndex = 0;
  dynamic tar;
  List<String> order = <String>[
    'N Tarefa',
    'Titulo',
    'Prioridade',
    'Atribuido',
    'Minhas'
  ];
  dynamic orderv;

  dynamic user, nome = 'Nome', mail = 'Mail';
  int length = 0;
  String _page_title = "Tarefas";

  void _onItemTapped(int index) {
    setState(() {
      if (index == 0) {
        _page_title = "Tarefas";
      } else if (index == 1) {
        _page_title = "Estado Das Tarefas";
      } else if (index == 2) {
        _page_title = "Tarefas Finalizadas";
      } else if (index == 3) {
        _page_title = "Funcionários";
      }
      _selectedIndex = index;
    });
  }

  getAllProducts(String order) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    String pedido = 'all';
    dynamic response = await http.get(Uri.parse(
        "http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=10&order=$order&id=$id"));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  dynamic Users;
  getUser() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=13&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        user = json.decode(response.body);
      });
      nome = user[0]['Name'];
      mail = user[0]['Mail'];

      return user;
    }
  }

  List<String> empresas = [];

  getUserList(String order) async {
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=16&order=$order'));
    if (response.statusCode == 200) {
      setState(() {
        Users = jsonDecode(response.body) as List;
      });
      length = int.parse(Users.length.toString());

      return Users;
    }
  }

  void adicionarEmpresa(String novaEmpresa) {
    setState(() {
      empresas.add(novaEmpresa);
    });
  }

  List<Widget> cardList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _page_title,
              style: const TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 25,
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _showAlertDialog(context);
                  },
                  child: const Icon(
                    Icons.exit_to_app,
                    size: 26.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _selectedIndex == 0 ? _buildList() : _buildPage(_selectedIndex),
      drawer: Drawer(
        child: Column(
          // Wrap the contents in a Column
          children: [
            buildHeader(
              context,
              nome: nome,
              mail: mail,
            ),
            Card(
              elevation:
                  10, // Adjust the elevation as needed for the desired shadow effect
              child: Column(
                children: <Widget>[
                  ExpansionTile(
                    title: Text("Empresas"),
                    initiallyExpanded: true,
                    leading: Icon(Icons.person), //add icon
                    childrenPadding:
                        EdgeInsets.only(left: 60), //children padding

                    children: [
                      ListTile(
                        leading: const Icon(Icons.home),
                        title: const Text(
                          'Empresas',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        selected: _selectedIndex == 0,
                        onTap: () {
                          _onItemTapped(0);
                          Navigator.pop(context);
                        },
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      const Divider(
                        height: 12,
                      ),
                    ],
                  ),
                  // Add a divider between list items if desired
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text(
                      'Funcionários',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    selected: _selectedIndex == 2,
                    onTap: () {
                      _onItemTapped(2);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    await getAllProducts(orderv.toString());
  }

  Widget buildHeader(
    BuildContext context, {
    required String nome,
    required String mail,
  }) =>
      Material(
        color: Colors.blue,
        child: InkWell(
          child: Container(
            child: Row(
              children: [
                SizedBox(height: 120, width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nome,
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mail,
                      style: TextStyle(fontSize: 14, color: Colors.white),
                    ),
                  ],
                ),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.transparent,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Icon(
                          Icons.change_history,
                          size: 26.0,
                        ),
                      ),
                    ),
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.transparent,
                      child: GestureDetector(
                        onTap: () {},
                        child: const Icon(
                          Icons.help_center_outlined,
                          size: 26.0,
                        ),
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ),
      );

  Widget _buildList() {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Wrap(
            spacing: 16, // Espaçamento horizontal entre os cartões
            runSpacing: 16, // Espaçamento vertical entre as linhas de cartões
            children: cardList,
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _addCard();
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  void _addCard() {
    setState(() {
      cardList.add(
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => empresadPage(),
              ),
            );
          },
          child: SizedBox(
            width: 450,
            height: 450,
            child: CardWithHoverEffect(
              child: Container(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Adicione os elementos de texto e imagem aqui

                    Text(
                      'Nome Empresa',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Divider(height: 18),

                    // Equipa Responsável
                    Text(
                      'Equipa Responsável',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Tickets em Aberto
                    Text(
                      'Tickets em Aberto: XX', // Substitua XX pela quantidade real de tickets em aberto
                    ),

                    // Nome Responsável
                    Text(
                      'Nome Responsável: Nome do Responsável',
                    ),

                    // Contato Responsável
                    Text(
                      'Contato Responsável: contato@empresa.com', // Substitua pelo contato real
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  void showSnackBar(String message) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        message,
        style: TextStyle(
          fontSize: 16, // Customize font size
        ),
      ),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
      backgroundColor: Colors.green, // Customize background color
      elevation: 6.0, // Add elevation
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0), // Customize border radius
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Widget _buildPage(int index) {
    // Implemente suas próprias páginas personalizadas aqui
    switch (index) {
      case 1:
        return empresadPage();
      case 2:
        return UsersTicketsPage();
      default:
        return Container(); // Retorne um contêiner vazio como fallback
    }
  }

  @override
  void initState() {
    getUser();
    getAllProducts('all');
    getUserList('all');
    super.initState();
  }
}

void _showAlertDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Pretende fazer Log Out?'),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.of(context).pop(); // Fecha o AlertDialog
            },
          ),
          TextButton(
            child: const Text('Confirmar'),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.remove('id');
              /*  Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (BuildContext ctx) => const LoginForm()));*/
            },
          ),
        ],
      );
    },
  );
}

class CardWithHoverEffect extends StatefulWidget {
  final Widget child;

  CardWithHoverEffect({required this.child});

  @override
  _CardWithHoverEffectState createState() => _CardWithHoverEffectState();
}

class _CardWithHoverEffectState extends State<CardWithHoverEffect> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: Card(
        elevation: isHovered ? 10.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: widget.child,
      ),
    );
  }

  void _onHover(bool hovering) {
    setState(() {
      isHovered = hovering;
    });
  }
}
