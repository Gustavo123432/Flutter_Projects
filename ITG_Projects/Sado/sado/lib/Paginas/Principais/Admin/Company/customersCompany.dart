import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Login/login.dart';
import 'package:sado/Paginas/Principais/Admin/dashboardPage.dart';
import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/Paginas/Secundarias/Collaborators/collaboratorInfo.dart';
import 'package:sado/Paginas/Secundarias/Collaborators/createCollaborator.dart';
import 'package:sado/Paginas/Secundarias/Customers/createCustomer.dart';
import 'package:sado/Paginas/Secundarias/Customers/customerInfo.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CustomersCompanyPage extends StatefulWidget {
  final String idCompany;
  CustomersCompanyPage({required this.idCompany});

  @override
  _CustomersCompanyPageState createState() => _CustomersCompanyPageState();
}

class _CustomersCompanyPageState extends State<CustomersCompanyPage> {
  List<dynamic> customers = [];
  String? selectedCompanyId;
  List<dynamic> filteredCustomers = [];
  TextEditingController searchController = TextEditingController();
  List<String> selectedCustomerIds = [];
  bool isTrashVisible = false;
  List<dynamic> companies = [];
  bool isLoading = true;
  bool notExist = true;

  @override
  void initState() {
    super.initState();
    fetchCustomers(widget.idCompany.toString());
  }

  Future<void> fetchCustomers(String companyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idCodMaster = prefs.getString("idMaster");

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'M1',
          'id': idCodMaster,
          'idcompany': companyId, // Assume this parameter is needed
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          customers = data;
          filteredCustomers = data;

          notExist = customers.isEmpty;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load customers');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        notExist = true;
      });
      print('Error: $e');
    }
  }

  void _filterCustomers() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredCustomers = customers.where((customer) {
        return /*user['FirstName'].toLowerCase().contains(query) ||
                user['LastName'].toLowerCase().contains(query) ||*/
            customer['IdCustomer']?.toLowerCase().contains(query) ??
                false || customer['NIF']?.toLowerCase().contains(query) ??
                false;
      }).toList();
    });
  }

  Future<void> deleteUser() async {
    for (String customerId in selectedCustomerIds) {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'M3',
          'id': customerId,
        },
      );

      print(response.body);

      if (response.statusCode == 200) {
        _showDialog(
            context, "Customer Deleted", "Customer Deleted successfully.", 1);
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
                        builder: (context) => AdminDrawer(
                            currentPage: CustomersCompanyPage(
                              idCompany: widget.idCompany,
                            ),
                            numero: 2)),
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
              ? Center(child: Text("No Customers found."))
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
                                  onPressed: _filterCustomers,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _filterCustomers();
                              },
                            ),
                          ),
                          Visibility(
                            visible: isTrashVisible,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Implement the bulk delete functionality here
                                if (selectedCustomerIds.isNotEmpty) {
                                  print(
                                      'Deleting users with IDs: $selectedCustomerIds');
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
                                DataColumn(label: Text('Phone')),
                                DataColumn(label: Text('NIF')),
                                DataColumn(label: Text('Address')),
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filteredCustomers.map((customer) {
                                return DataRow(
                                  selected: selectedCustomerIds
                                      .contains(customer['IdCustomer']),
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: selectedCustomerIds
                                            .contains(customer['IdCustomer']),
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            if (checked == true) {
                                              if (!selectedCustomerIds.contains(
                                                  customer['IdCustomer'])) {
                                                selectedCustomerIds.add(
                                                    customer['IdCustomer']);
                                              }
                                            } else {
                                              selectedCustomerIds.remove(
                                                  customer['IdCustomer']);
                                            }
                                            isTrashVisible =
                                                selectedCustomerIds.isNotEmpty;
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(
                                        Text(customer['IdCustomer'] ?? 'N/A')),
                                    DataCell(Text(customer['Name'] ?? 'N/A')),
                                    DataCell(Text(customer['Mail'] ?? 'N/A')),
                                    DataCell(Text(customer['Phone'] ?? 'N/A')),
                                    DataCell(Text(customer['NIF'] ?? 'N/A')),
                                    DataCell(
                                        Text(customer['Address'] ?? 'N/A')),
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
                                                  pageBuilder: (BuildContext
                                                              context,
                                                          _,
                                                          __) =>
                                                      CustomerDetailsPage(
                                                          customer: customer,
                                                          idCompany:
                                                              widget.idCompany),
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
                                            visible: selectedCustomerIds
                                                .contains(customer['IdData']),
                                            child: IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                // Implement the delete functionality here
                                                print(
                                                    'Deleting user ${customer['CodUser']}');
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
            child: Icon(Icons.add),
            onTap: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  pageBuilder: (BuildContext context, _, __) =>
                      CreateCustomer(idCompany: widget.idCompany),
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
