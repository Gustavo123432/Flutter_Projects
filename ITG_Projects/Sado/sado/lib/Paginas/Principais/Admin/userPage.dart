import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sado/Paginas/Login/login.dart';
import 'package:sado/Paginas/Secundarias/Users/createuser.dart';
import 'package:sado/Paginas/Secundarias/Users/userInfo.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  _UserPageState createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<dynamic> users = [];
  List<dynamic> companies = [];
  String? selectedCompanyId;
  bool isLoading = true;
  bool notExist = true;
  List<dynamic> filteredUsers = [];
  TextEditingController searchController = TextEditingController();
  List<String> selectedUserIds = [];
  bool isTrashVisible = false;

  @override
  void initState() {
    super.initState();
    fetchUsers();
    fetchCompanies();
  }

  Future<void> fetchUsers() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idCodMaster = prefs.getString("idMaster");
    print(idCodMaster);

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'W1',
          'id': idCodMaster,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          users = data;
          filteredUsers = data;
          notExist = users.isEmpty;
          isLoading = false;
          print(data);
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        notExist = true;
      });
      print('Error: $e');
    }
  }

  Future<void> fetchCompanies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idCodMaster = prefs.getString("idMaster");
    print(idCodMaster);

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'C1',
          'id': idCodMaster,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          companies = data;
        });
      } else {
        throw Exception('Failed to load companies');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        notExist = true;
      });
      print('Error: $e');
    }
  }

  Future<void> fetchUsersByCompanyId(String companyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idCodMaster = prefs.getString("idMaster");

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'W3',
          'id': idCodMaster,
          'idcompany': companyId,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          users = data;
          filteredUsers = data;
          notExist = users.isEmpty;
          isLoading = false;
          print(data);
        });
      } else {
        throw Exception('Failed to load users');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        notExist = true;
      });
      print('Error: $e');
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Company Filter'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButtonFormField<String>(
                value: selectedCompanyId,
                onChanged: (newValue) {
                  setState(() {
                    selectedCompanyId = newValue;
                  });
                },
                items: companies.map((company) {
                  return DropdownMenuItem<String>(
                    value: company['IdCompany'].toString(),
                    child: Text(company['Name']),
                  );
                }).toList(),
                hint: Text('Select Company'),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Filtrar'),
              onPressed: () {
                if (selectedCompanyId != null) {
                  fetchUsersByCompanyId(selectedCompanyId!);
                }
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Mostrar Todos'),
              onPressed: () {
                fetchUsers();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _filterUsers() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        return /*user['FirstName'].toLowerCase().contains(query) ||
                user['LastName'].toLowerCase().contains(query) ||*/
            user['CodUser']?.toLowerCase().contains(query) ??
                false || user['NIF']?.toLowerCase().contains(query) ??
                false;
      }).toList();
    });
  }

  Future<void> deleteUser() async {
    for (String userId in selectedUserIds) {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'W5',
          'id': userId, // Directly use the userId
        },
      );

      print(response.body);

      if (response.statusCode == 200) {
        _showDialog(context, "User Deleted", "User Deleted successfully.", 1);
      } else {
        _showDialog(context, 'Error', 'Failed to connect to the server.', 0);
      }
    }
  }

  void _showDialog(
      BuildContext context, String title, String message, int value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(message),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          actions: <Widget>[
            TextButton(
              child: Text('OK', style: TextStyle(color: Colors.blue)),
              onPressed: () {
                Navigator.of(context).pop();
                if (value == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) =>
                            AdminDrawer(currentPage: UserPage(), numero: 10)),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notExist
              ? Center(child: Text("No users found."))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: searchController,
                              decoration: InputDecoration(
                                labelText: 'Search',
                                suffixIcon: IconButton(
                                  icon: Icon(Icons.search),
                                  onPressed: _filterUsers,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _filterUsers();
                              },
                            ),
                          ),
                          Visibility(
                            visible: isTrashVisible,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Implement the bulk delete functionality here
                                if (selectedUserIds.isNotEmpty) {
                                  print(
                                      'Deleting users with IDs: $selectedUserIds');
                                  deleteUser();
                                  // Add logic to delete selected users
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        margin: const EdgeInsets.all(8.0),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.vertical,
                            child: DataTable(
                              columns: [
                                DataColumn(label: Text('Select')),
                                DataColumn(label: Text('ID')),
                                DataColumn(label: Text('Name')),
                                DataColumn(label: Text('Mail')),
                                DataColumn(label: Text('Country')),
                                DataColumn(label: Text('NIF')),
                                DataColumn(label: Text('Birthdate')),
                                DataColumn(label: Text('Phone')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filteredUsers.map((user) {
                                String? countryName =
                                    CountryList.getCountryNameByCode(
                                        user['Country']);

                                return DataRow(
                                  selected:
                                      selectedUserIds.contains(user['IdData']),
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: selectedUserIds
                                            .contains(user['IdData']),
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            if (checked == true) {
                                              if (!selectedUserIds
                                                  .contains(user['IdData'])) {
                                                selectedUserIds
                                                    .add(user['IdData']);
                                              }
                                            } else {
                                              selectedUserIds
                                                  .remove(user['IdData']);
                                            }
                                            isTrashVisible =
                                                selectedUserIds.isNotEmpty;
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(Text(user['CodUser'] ?? 'N/A')),
                                    DataCell(Text(
                                        '${user['FirstName'] ?? 'N/A'} ${user['LastName'] ?? 'N/A'}')),
                                    DataCell(Text(user['Mail'] ?? 'N/A')),
                                    DataCell(Text(countryName ?? 'N/A')),
                                    DataCell(Text(user['NIF'] ?? 'N/A')),
                                    DataCell(Text(user['Birthdate'] ?? 'N/A')),
                                    DataCell(Text(user['Phone'] ?? 'N/A')),
                                    DataCell(
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.edit),
                                            onPressed: () {
                                              Navigator.of(context).push(
                                                PageRouteBuilder(
                                                  opaque: false,
                                                  pageBuilder:
                                                      (BuildContext context, _,
                                                              __) =>
                                                          UserDetailsPage(
                                                              user: user),
                                                  transitionsBuilder: (context,
                                                      animation,
                                                      secondaryAnimation,
                                                      child) {
                                                    return FadeTransition(
                                                      opacity: animation,
                                                      child: child,
                                                    );
                                                  },
                                                ),
                                              );
                                            },
                                          ),
                                          Visibility(
                                            visible: selectedUserIds
                                                .contains(user['IdData']),
                                            child: IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                // Implement the delete functionality here
                                                print(
                                                    'Deleting user ${user['CodUser']}');
                                                //for eatch user deleted size selectUser
                                                // Add logic to delete the single user
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: SpeedDial(
        icon: Icons.more_horiz,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 130, 201, 189),
        children: [
          SpeedDialChild(
            child: Icon(Icons.filter_list),
            onTap: () {
              _showFilterDialog();
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.add),
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (BuildContext context, _, __) =>
                      CreateUserForm(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
