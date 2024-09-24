import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sado/Paginas/Login/login.dart';
import 'package:sado/Paginas/Principais/Admin/Settings/accessSettings.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/customersCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/placesCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/suppliersCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Settings/companySettings.dart';
import 'package:sado/Paginas/Principais/Admin/dashboardPage.dart';
import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/Paginas/Secundarias/logout.dart';
import 'package:sado/animation/animation_page.dart';
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
  Widget currentPage = DashboardPage(); // Track the current page
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
                Navigator.pushReplacement(
                  context,
                  SlideTransitionPageRoute(
                    page: LoginForm(),
                  ),
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
                child: FutureBuilder<List<Company>>(
                  future: futureCompanies,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No companies found.'));
                    }

                    final companies = snapshot.data!;
                    return AnimatedBuilder(
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
                            _controller.selectedIndex != 5 &&
                            _controller.selectedIndex != 6 &&
                            _controller.selectedIndex != 7 &&
                            _controller.selectedIndex != 9 &&
                            _controller.selectedIndex != 10 &&
                            _controller.selectedIndex != 11 &&
                            _controller.selectedIndex != 12 &&
                            _controller.selectedIndex != 8 &&
                            _controller.selectedIndex != 13) {
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
                            newPage = Center(child: Text("Assets Page"));
                            break;
                          case 2:
                            _key.currentState?.closeDrawer();
                            newPage = CollaboratorsCompanyPage(
                              idCompany: companies.isNotEmpty
                                  ? companies.first.id
                                  : '',
                            );
                            break;
                          case 3:
                            _key.currentState?.closeDrawer();
                            newPage = SuppliersCompanyPage(
                              idCompany: companies.isNotEmpty
                                  ? companies.first.id
                                  : '',
                            );
                            break;
                          case 4:
                            _key.currentState?.closeDrawer();
                            newPage = CustomersCompanyPage(
                              idCompany: companies.isNotEmpty
                                  ? companies.first.id
                                  : '',
                            );
                            break;
                          case 5:
                            _key.currentState?.closeDrawer();
                            newPage = PlacesCompanyPage(
                              idCompany: companies.isNotEmpty
                                  ? companies.first.id
                                  : '',
                            );
                            break;
                          case 6:
                            _key.currentState?.closeDrawer();
                            newPage = Center(child: Text("Records Type Page"));
                            break;
                          case 7:
                            _key.currentState?.closeDrawer();
                            newPage = Center(child: Text("Reports Page"));
                            break;
                          case 9:
                            _key.currentState?.closeDrawer();
                            newPage = CompanySettingsPage();
                            break;
                          case 10:
                            _key.currentState?.closeDrawer();
                            newPage = UserPage();
                            break;
                          case 11:
                            _key.currentState?.closeDrawer();
                            newPage = AccessSettingsPage();
                            break;
                          case 12:
                            _key.currentState?.closeDrawer();
                            newPage = Center(child: Text("App Settings Page"));
                            break;
                          case 13:
                            _key.currentState?.closeDrawer();
                            newPage = LogoutDialog();
                            break;
                          default:
                            _key.currentState?.closeDrawer();
                            newPage = Center(child: Text("Unexpected Page"));
                        }

                        // Update the current page and return it
                        widget.currentPage = newPage;
                        return newPage;
                      },
                    );
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
/*
Fixo Drawer
-Dash |
-assets |
-collaborators|
-supliers-|
-customers |
-locations
-records type
-reports
-setting
  -company
  -user
  -profile
  -appsettings
 */

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
          color: Color.fromARGB(255, 84, 129, 143),
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
                'lib/assets/company.png', // Replace with the path to your image
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
        const SidebarXItem(icon: Icons.business, label: "  Assets"),
        const SidebarXItem(icon: Icons.group, label: "  Collaborators"),
        const SidebarXItem(icon: Icons.handshake, label: "  Suppliers"),
        const SidebarXItem(icon: Icons.shopping_cart, label: "  Customers"),
        const SidebarXItem(icon: Icons.location_on, label: "  Places"),
        const SidebarXItem(icon: Icons.file_present_rounded, label: "  Records Types"),
        const SidebarXItem(icon: Icons.bar_chart, label: "  Reports"),
        SidebarXItem(
          icon: Icons.settings,
          label: "  Settings",
          onTap: () {
            // Toggle the expanded state on click
            setState(() {
              _isSettingsExpanded = !_isSettingsExpanded;
            });
          },
        ),
        if (_isSettingsExpanded) ...[
          const SidebarXItem(icon: Icons.business, label: "      Company"),
          const SidebarXItem(icon: Icons.group, label: "      Users"),
          const SidebarXItem(icon: Icons.security, label: "      Accesses"),
          const SidebarXItem(
              icon: Icons.settings_applications, label: "      App Settings"),
          const SidebarXItem(icon: Icons.logout, label: "      Logout"),
        ],
      ],
    );
  }
}

/*body: Row(
        children: [
          // SidebarX widget always visible
          SidebarX(
            controller: _controller,
            theme: SidebarXTheme(
              decoration: BoxDecoration(
                color: Colors.blueGrey[900], // Background color for the sidebar
              ),
              textStyle: TextStyle(color: Colors.white), // Text style for all items
              selectedTextStyle: TextStyle(color: Colors.white), // Text style for selected item
              selectedItemDecoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(8),
              ),
              iconTheme: IconThemeData(color: Colors.white), // Icon style for all items
              selectedIconTheme: IconThemeData(color: Colors.white), // Icon style for selected item
            ),
            extendedTheme: SidebarXTheme(
              width: 250, // Width of the sidebar when extended
              decoration: BoxDecoration(
                color: Colors.blueGrey[800],
              ),
            ),
            items: [
              SidebarXItem(
                icon: Icons.home,
                label: 'Dashboard',
                onTap: () {
                  setState(() {
                    _selectedIndex = 0; // Set index to show DashboardPage
                  });
                },
              ),
              SidebarXItem(
                icon: Icons.business,
                label: 'Companies',
                onTap: () {
                  setState(() {
                    _selectedIndex = 1; // Set index to show CompaniesPage
                  });
                },
              ),
              SidebarXItem(
                icon: Icons.group,
                label: 'Users',
                onTap: () {
                  setState(() {
                    _selectedIndex = 2; // Set index to show UserPage
                  });
                },
              ),
              SidebarXItem(
                icon: Icons.settings,
                label: 'Settings',
                onTap: () {
                  setState(() {
                    _selectedIndex = 3; // Set index to show SettingsPage
                  });
                },
              ),
            ],
          ),

          // Main content area using IndexedStack to maintain state
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                // Dashboard Page
                DashboardPage(),
                
                // FutureBuilder for dynamically loading companies
                FutureBuilder<List<Company>>(
                  future: futureCompanies,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No companies found'));
                    } else {
                      final companies = snapshot.data!;
                      return ListView(
                        padding: EdgeInsets.zero,
                        children: companies.map<Widget>((company) {
                          return ExpansionTile(
                            title: Text(company.name),
                            children: <Widget>[
                              ListTile(
                                leading: Icon(Icons.inventory),
                                title: Text('Assets'),
                                onTap: () {
                                  print(company.id);
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.group),
                                title: Text('Collaborators'),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          CollaboratorsCompanyPage(idCompany: company.id),
                                    ),
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.handshake),
                                title: Text('Suppliers'),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/${company.name.toLowerCase()}/suppliers',
                                  );
                                },
                              ),
                              ListTile(
                                leading: Icon(Icons.shopping_cart),
                                title: Text('Customers'),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/${company.name.toLowerCase()}/customers',
                                  );
                                },
                              ),
                            ],
                          );
                        }).toList(),
                      );
                    }
                  },
                ),

                // Users Page
                UserPage(),

                // Settings Page
                //SettingsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}*/
/* 


// Main app entry point
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admin Panel',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
      // Define your routes here
      routes: {
        '/companya/assets': (context) => CompanyPage('Company A - Assets'),
        '/companya/suppliers': (context) =>
            CompanyPage('Company A - Suppliers'),
        '/companya/users': (context) => CompanyPage('Company A - Users'),
        '/companya/customers': (context) =>
            CompanyPage('Company A - Customers'),
        '/companyb/assets': (context) => CompanyPage('Company B - Assets'),
        '/companyb/suppliers': (context) =>
            CompanyPage('Company B - Suppliers'),
        '/companyb/users': (context) => CompanyPage('Company B - Users'),
        '/companyb/customers': (context) =>
            CompanyPage('Company B - Customers'),
        // Add more routes as needed
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text('Admin Panel'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState?.openDrawer();
          },
        ),
      ),
      drawer: AdminDrawer(),
      body: Center(
        child: Text('Home Page Content'),
      ),
    );
  }
}

// A placeholder page for different routes
class CompanyPage extends StatelessWidget {
  final String title;

  CompanyPage(this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Text('Content for $title'),
      ),
    );
  }
}*/
