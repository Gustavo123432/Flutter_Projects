import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Admin/pedidosPage.dart';
import 'package:my_flutter_project/Admin/produtoPage.dart';
import 'package:my_flutter_project/Admin/turmasPage.dart';
import 'package:my_flutter_project/Admin/users.dart';
import 'package:my_flutter_project/Bar/pedidosRegistados.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebarx/sidebarx.dart'; // Import SidebarX package

// Model for Company
class Company {
  final String name;
  final String id;

  Company({required this.name, required this.id});

  // Factory method to create a Company object from JSON
  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      name: json['Name'],
      id: json['IdCompany'],
    );
  }
}

// Function to fetch companies from the API
Future<List<Company>> fetchCompanies() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var idUser = prefs.getString("idUser");
  final response = await http.post(
    Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
    body: {
      'query_param': 'C1',
      'id': idUser,
    },
  );

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => Company.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load companies');
  }
}

// AdminDrawer Widget
class AdminDrawer extends StatefulWidget {
  Widget currentPage = UserTable(); // Track the current page
  int numero;

  AdminDrawer({required this.currentPage, required this.numero});
  @override
  _AdminDrawerState createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  late Future<List<Company>> futureCompanies;

  var _controller = SidebarXController(
    selectedIndex: 0, // Set the default selected index here
    extended: true,
  );
  final _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    futureCompanies = fetchCompanies();
    pageController();
  }

  void pageController() {
    switch (widget.numero) {
      case 0:
        _controller = SidebarXController(
          selectedIndex: 0, // Set the default selected index here
          extended: true,
        );
      case 1:
        _controller = SidebarXController(
          selectedIndex: 1, // Set the default selected index here
          extended: true,
        );
      case 2:
        _controller = SidebarXController(
          selectedIndex: 2, // Set the default selected index here
          extended: true,
        );
      case 3:
        _controller = SidebarXController(
          selectedIndex: 3, // Set the default selected index here
          extended: true,
        );
      case 4:
        _controller = SidebarXController(
          selectedIndex: 4, // Set the default selected index here
          extended: true,
        );
      case 5:
        _controller = SidebarXController(
          selectedIndex: 5, // Set the default selected index here
          extended: true,
        );
      case 6:
        _controller = SidebarXController(
          selectedIndex: 6, // Set the default selected index here
          extended: true,
        );

      case 7:
        _controller = SidebarXController(
          selectedIndex: 5, // Set the default selected index here
          extended: true,
        );
      case 9:
        _controller = SidebarXController(
          selectedIndex: 9, // Set the default selected index here
          extended: true,
        );
      case 10:
        _controller = SidebarXController(
          selectedIndex: 10, // Set the default selected index here
          extended: true,
        );
      case 11:
        _controller = SidebarXController(
          selectedIndex: 11, // Set the default selected index here
          extended: true,
        );
      case 12:
        _controller = SidebarXController(
          selectedIndex: 12, // Set the default selected index here
          extended: true,
        );
      case 13:
        _controller = SidebarXController(
          selectedIndex: 13, // Set the default selected index here
          extended: true,
        );
    }
  }

  void logout(BuildContext context) {
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                /*Navigator.pushReplacement(
                  context,
                  /*SlideTransitionPageRoute(
                    page: LoginForm(),
                  ),*/
                );*/
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(builder: (context) {
      final isSmallScreen = MediaQuery.of(context).size.width < 600;

      return SafeArea(
        child: Scaffold(
          key: _key,
          appBar: isSmallScreen
              ? AppBar(
                  leading: IconButton(
                    onPressed: () {
                      _key.currentState?.openDrawer();
                    },
                    icon: Icon(Icons.menu),
                  ),
                )
              : null,
          drawer: SideBarWidget(controller: _controller), // Show sidebarX
          body: Row(
            children: [
              if (!isSmallScreen) SideBarWidget(controller: _controller),
              Expanded(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // Check the selected index and update the page accordingly
                    if (_controller.selectedIndex == 8) {
                      // Return the current page without changing it
                      return widget.currentPage;
                    } else if (_controller.selectedIndex != 0 &&
                        _controller.selectedIndex != 1 &&
                        _controller.selectedIndex != 2 &&
                        _controller.selectedIndex != 3 &&
                        _controller.selectedIndex != 4 &&
                        _controller.selectedIndex != 5) {
                      return widget.currentPage;
                    }

                    Widget newPage;

                    switch (_controller.selectedIndex) {
                      case 0:
                        _key.currentState?.closeDrawer();
                        newPage = Center(child: Text("Dashboard"));
                        break;
                      case 1:
                        _key.currentState?.closeDrawer();
                        newPage = UserTable();
                        break;
                      case 2:
                        _key.currentState?.closeDrawer();
                        newPage = TurmasPage();
                        break;
                      case 3:
                        _key.currentState?.closeDrawer();
                        newPage = PedidosPage();
                        break;
                      case 4:
                        _key.currentState?.closeDrawer();
                        newPage = ProdutoPage();
                        break;
                      case 5:
                        _key.currentState?.closeDrawer();
                        newPage = ProdutoPage();
                        break;
                      default:
                        _key.currentState?.closeDrawer();
                        newPage = Center(child: Text("Unexpected Page"));
                    }

                    // Update the current page and return it
                    widget.currentPage = newPage;
                    return newPage;
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class SideBarWidget extends StatefulWidget {
  const SideBarWidget({Key? key, required this.controller}) : super(key: key);

  // The SidebarXController should be defined as a final member of the widget
  final SidebarXController controller;

  @override
  _SideBarWidgetState createState() => _SideBarWidgetState();
}

class _SideBarWidgetState extends State<SideBarWidget> {
  final _controller = SidebarXController(selectedIndex: 0);

  // Boolean variable to track expansion state
  bool _isSettingsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return SidebarX(
        controller: widget.controller,
        theme: const SidebarXTheme(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 246, 141, 45),
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
          textStyle: TextStyle(color: Colors.white),
          selectedItemDecoration: BoxDecoration(
            color: Colors.white60,
            borderRadius: BorderRadius.all(
              Radius.circular(20),
            ),
          ),
        ),
        extendedTheme: SidebarXTheme(width: 250),
        headerBuilder: (context, extended) {
          return Column(
            children: [
              SizedBox(height: 20),
              SizedBox(
                height: 60,
                child: Image.asset(
                  'lib/assets/barapp.png', // Replace with the path to your image
                  fit: BoxFit.cover,
                ),
              ),
              SizedBox(height: 20),
            ],
          );
        },
        footerDivider: Divider(
          color: Colors.white,
          height: 1,
        ),
        items: [
          const SidebarXItem(icon: Icons.home, label: "  Dashboard"),
          const SidebarXItem(icon: Icons.business, label: "  Users"),
          const SidebarXItem(icon: Icons.group, label: "  Turmas"),
          const SidebarXItem(icon: Icons.handshake, label: "  Registos"),
          const SidebarXItem(icon: Icons.shopping_cart, label: "  Produtos"),
          /*const SidebarXItem(icon: Icons.location_on, label: "  Places"),
  const SidebarXItem(icon: Icons.file_present_rounded, label: "  Records Types"),
  const SidebarXItem(icon: Icons.bar_chart, label: "  Reports"),*/

          /*SidebarXItem(
    icon: Icons.settings,
    label: "  Settings",
    onTap: () {
      setState(() {
        _isSettingsExpanded = !_isSettingsExpanded;
      });
    },
  ),

  // Expanded items with label-based indentation
  if (_isSettingsExpanded) ...[
    const SidebarXItem(icon: Icons.business, label: "      Company"),
    const SidebarXItem(icon: Icons.group, label: "      Users"),
    const SidebarXItem(icon: Icons.security, label: "      Accesses"),
    const SidebarXItem(icon: Icons.settings_applications, label: "      App Settings"),
    const SidebarXItem(icon: Icons.logout, label: "      Logout"),
  ],*/
        ]);
  }
}
