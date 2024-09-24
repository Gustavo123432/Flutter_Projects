import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sado/Paginas/Login/login.dart';
import 'package:sado/Paginas/Secundarias/createCompany.dart';
import 'package:sado/animation/animation_page.dart';
import 'dart:convert';
import 'package:sado/drawer/adminDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:sidebarx/sidebarx.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  dynamic companies;
  bool isLoading = true;
  bool notExist = true;
    final _controller = SidebarXController(
    selectedIndex: 0, // Set the default selected index here
    extended: true,
  );

  @override
  void initState() {
    super.initState();
    fetchCompanies();
  }

  Future<void> fetchCompanies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idUser = prefs.getString("idUser");
    print(idUser);
    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'C1',
          'id': idUser,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          companies = json.decode(response.body);
          print(companies);
          print(companies['Mail']);
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load companies');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
    companies == null;
    if (companies == null) {
      notExist = true;
    } else {
      notExist = false;
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
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
            ),
            TextButton(
                child: const Text('Confirmar'),
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  await prefs.clear();
                  Navigator.pushReplacement(
                    context,
                    SlideTransitionPageRoute(
                      page: LoginForm(),
                    ),
                  );
                }),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
     /* appBar: AppBar(
        title: Text('Dashboard'),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),*/
      //drawer: SideBarWidget(controller: _controller,),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notExist
              ? Center(child: Text("Create New Company, Please!"))
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5, // Número de colunas na grade
                      crossAxisSpacing: 1.0,
                      mainAxisSpacing: 1.0,
                      childAspectRatio:
                          1.5, // Ajuste o aspecto do cartão conforme necessário
                    ),
                    itemCount: companies.length,
                    itemBuilder: (context, index) {
                      final company = companies[index];
                      return GestureDetector(
                        onTap: () {
                          // Descomente isto se quiser navegar para a CompanyDetailsPage ao tocar
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  CompanyDetailsPage(company: company),
                            ),
                          );
                        },
                        child: Container(
                          width: 100, // Ajuste conforme necessário
                          height: 150, // Ajuste conforme necessário
                          child: Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            elevation: 2,
                            child: Column(
                              children: [
                                // Círculo ao redor da imagem e nome
                                Expanded(
                                  flex: 2,
                                  child: Center(
                                    child: Container(
                                      constraints: BoxConstraints(
                                        minWidth:
                                            100, // Largura mínima do círculo
                                        minHeight:
                                            100, // Altura mínima do círculo
                                      ),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Color(
                                          int.parse(company['Colour'],
                                                  radix: 16) +
                                              0xFF000000,
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Center(
                                            child: Image.asset(
                                              'lib/assets/company.png', // Caminho para a imagem local
                                              width: 45,
                                              height: 45,
                                            ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  8), // Espaço entre a imagem e o nome
                                          Text(
                                            company['Name'],
                                            style: TextStyle(
                                              fontSize: 18.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),

                                // Detalhes no fundo, alinhados
                                Expanded(
                                  flex: 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Detalhes à esquerda
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            // Total de colaboradores
                                            Text(
                                              'Total: ${company['TotalEmployees']}',
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.grey,
                                              ),
                                            ),
                                            // NIF
                                            Text(
                                              'NIF: ${company['NIF']}',
                                              style: TextStyle(
                                                fontSize: 12.0,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Número de bens associados (à direita)
                                        Text(
                                          'Assets: ${company['NumberOfAssets']}',
                                          style: TextStyle(
                                            fontSize: 12.0,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: SpeedDial(
        icon: Icons.more_horiz,
        iconTheme:
            IconThemeData(color: Colors.white), // Set icon color to white
        backgroundColor: Color.fromARGB(255, 130, 201, 189),
        children: [
          /*SpeedDialChild(
              child: Icon(Icons.filter_list),
              onTap: () {
                //_showFilterDialog();
              }),
          SpeedDialChild(
            child: Icon(Icons.edit),
            onTap: () {
              //_toggleEditMode();
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.file_upload),
            onTap: () {
              //_pickFile();
            },
          ),*/
          SpeedDialChild(
            child: Icon(Icons.add),
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false, // Set to false to allow transparency
                  pageBuilder: (BuildContext context, _, __) =>
                      CreateCompanyForm(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
              /*Navigator.push(
                context,
                SlideTransitionPageRoute(
                  page: CreateCompanyForm(),
                ),
              );*/
            },
          ),
        ],
      ),
    );
  }
}

class CompanyDetailsPage extends StatelessWidget {
  final dynamic company;

  CompanyDetailsPage({required this.company});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(company['Name']),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text('Details about ${company['Name']}'),
      ),
    );
  }
}
