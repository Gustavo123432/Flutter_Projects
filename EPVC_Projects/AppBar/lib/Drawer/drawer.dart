import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Admin/dashboard.dart';
import 'package:my_flutter_project/Admin/pedidosPage.dart';
import 'package:my_flutter_project/Admin/produtoPage.dart';
import 'package:my_flutter_project/Admin/turmasPage.dart';
import 'package:my_flutter_project/Admin/users.dart';
import 'package:my_flutter_project/Bar/pedidosRegistados.dart';
import 'package:my_flutter_project/Bar/produtoPageBar.dart';
import 'package:my_flutter_project/Drawer/logout.dart';
import 'package:my_flutter_project/login.dart';
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

  late SidebarXController _controller;  // Defined late here, will initialize in initState()
  final _key = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    pageController();
  }

  void pageController() {
    // Only assign the SidebarXController once based on the widget.numero value
    _controller = SidebarXController(
      selectedIndex: widget.numero,
      extended: true,
    );
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

                // Ensure navigation happens after the current frame finishes rendering
                
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (BuildContext ctx) => LoginForm()),
                  );
                
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
                    // Handle page transition logic based on selected index
                    if (_controller.selectedIndex == 8) {
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
                        newPage = DashboardPage();
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
                        //logout(context);  // Perform logout action directly here
                        newPage = LogoutDialog();
                        //return widget.currentPage;  // Return the current page
                      default:
                        _key.currentState?.closeDrawer();
                        newPage = Center(child: Text("Unexpected Page"));
                    }

                    // Update currentPage and return the new page
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

  final SidebarXController controller;

  @override
  _SideBarWidgetState createState() => _SideBarWidgetState();
}

class _SideBarWidgetState extends State<SideBarWidget> {
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
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
      ),
      extendedTheme: SidebarXTheme(width: 250),
      headerBuilder: (context, extended) {
        return Column(
          children: [
            SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(8.0),
              child: Image.asset(
                'lib/assets/barapp.png', // Replace with the path to your image
                height: 70,
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
        const SidebarXItem(icon: Icons.account_circle, label: "  Users"),
        const SidebarXItem(icon: Icons.group, label: "  Turmas"),
        const SidebarXItem(icon: Icons.archive_rounded, label: "  Registos"),
        const SidebarXItem(icon: Icons.local_pizza, label: "  Produtos"),
        const SidebarXItem(icon: Icons.logout, label: "      Logout"),
      ],
    );
  }
}
