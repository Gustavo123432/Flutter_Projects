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
import 'package:sado/Paginas/Secundarias/Places/createPlace.dart';
import 'package:sado/Paginas/Secundarias/Places/createPlace.dart';
import 'package:sado/Paginas/Secundarias/Places/placeInfo.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PlacesCompanyPage extends StatefulWidget {
  final String idCompany;
  PlacesCompanyPage({required this.idCompany});

  @override
  _PlacesCompanyPageState createState() => _PlacesCompanyPageState();
}

class _PlacesCompanyPageState extends State<PlacesCompanyPage> {
  List<dynamic> places = [];
  String? selectedCompanyId;
  List<dynamic> filteredPlaces = [];
  TextEditingController searchController = TextEditingController();
  List<String> selectedPlaceIds = [];
  bool isTrashVisible = false;
  List<dynamic> companies = [];
  bool isLoading = true;
  bool notExist = true;

  @override
  void initState() {
    super.initState();
    fetchPlaces(widget.idCompany.toString());
  }

  Future<void> fetchPlaces(String companyId) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idCodMaster = prefs.getString("idMaster");

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'P1',
          'id': companyId, // Assume this parameter is needed
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          places = data;
          filteredPlaces = data;
          notExist = places.isEmpty;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load places');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        notExist = true;
      });
      print('Error: $e');
    }
  }

  void _filterPlaces() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredPlaces = places.where((place) {
        return /*user['FirstName'].toLowerCase().contains(query) ||
                user['LastName'].toLowerCase().contains(query) ||*/
            place['IdPlace']?.toLowerCase().contains(query) ??
                false || place['NIF']?.toLowerCase().contains(query) ??
                false;
      }).toList();
    });
  }

  Future<void> deleteUser() async {
    for (String placeId in selectedPlaceIds) {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'M3',
          'id': placeId,
        },
      );

      print(response.body);

      if (response.statusCode == 200) {
        _showDialog(context, "Place Deleted", "Place Deleted successfully.", 1);
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
                            currentPage: PlacesCompanyPage(
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
              ? Center(child: Text("No Places found."))
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
                                  onPressed: _filterPlaces,
                                ),
                                border: OutlineInputBorder(),
                              ),
                              onChanged: (value) {
                                _filterPlaces();
                              },
                            ),
                          ),
                          Visibility(
                            visible: isTrashVisible,
                            child: IconButton(
                              icon: Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                // Implement the bulk delete functionality here
                                if (selectedPlaceIds.isNotEmpty) {
                                  print(
                                      'Deleting users with IDs: $selectedPlaceIds');
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
                                DataColumn(label: Text('Actions')),
                              ],
                              rows: filteredPlaces.map((place) {
                                return DataRow(
                                  selected: selectedPlaceIds
                                      .contains(place['IdPlace']),
                                  cells: [
                                    DataCell(
                                      Checkbox(
                                        value: selectedPlaceIds
                                            .contains(place['IdPlace']),
                                        onChanged: (bool? checked) {
                                          setState(() {
                                            if (checked == true) {
                                              if (!selectedPlaceIds
                                                  .contains(place['IdPlace'])) {
                                                selectedPlaceIds
                                                    .add(place['IdPlace']);
                                              }
                                            } else {
                                              selectedPlaceIds
                                                  .remove(place['IdPlace']);
                                            }
                                            isTrashVisible =
                                                selectedPlaceIds.isNotEmpty;
                                          });
                                        },
                                      ),
                                    ),
                                    DataCell(Text(place['IdPlace'] ?? 'N/A')),
                                    DataCell(Text(place['Name'] ?? 'N/A')),
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
                                                          PlaceDetailsPage(
                                                              place: place,
                                                              idCompany: widget
                                                                  .idCompany),
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
                                            visible: selectedPlaceIds
                                                .contains(place['IdData']),
                                            child: IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () {
                                                // Implement the delete functionality here
                                                print(
                                                    'Deleting user ${place['CodUser']}');
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
                      CreatePlace(idCompany: widget.idCompany),
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
