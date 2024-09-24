import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/placesCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/placesCompany.dart';
import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebarx/sidebarx.dart';

class PlaceDetailsPage extends StatefulWidget {
  final Map<String, dynamic> place;
  final String idCompany;

  PlaceDetailsPage({required this.place, required this.idCompany});

  @override
  _PlaceDetailsPageState createState() => _PlaceDetailsPageState();
}

class _PlaceDetailsPageState extends State<PlaceDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final _controller = SidebarXController(selectedIndex: 3);

  bool _isLoading = false;
  bool editar = false;

  @override
  void initState() {
    super.initState();
  
    simulatorUserInfo();
  }

  Future<int> simulatorUserInfo() async {
    var concluido = 1;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(seconds: 2));
    _nameController.text = widget.place['Name'] ?? '';
    _noteController.text = widget.place['Description'] ?? '';

    setState(() {
      _isLoading = false;
    });

    return concluido;
  }

  void updateDataPlace() async {
    var name = _nameController.text.trim().toString();
    var id = widget.place["IdPlace"];
    var note = _noteController.text.trim().toString();

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'P4',
          'name': name,
          'id': id,
          'description': note
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        _showDialog(context, "Place Update", "Place updated successfully.", 1);
      } else {
        _showDialog(context, 'Error', 'Failed to connect to the server.', 0);
      }
    } catch (e) {
      _showDialog(context, 'Error',
          'An unexpected error occurred. Please try again later.', 0);
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
                                  idCompany: widget.idCompany),
                              numero: 5,
                            )),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deletePlace() async {
    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'P3',
          'id': widget.place['IdPlace'],
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        _showDialog(context, "Place Deleted", "Place Deleted successfully.", 1);
      } else {
        _showDialog(context, 'Error', 'Failed to connect to the server.', 0);
      }
    } catch (e) {
      _showDialog(context, 'Error',
          'An unexpected error occurred. Please try again later.', 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: Container(
              width: 500, // Largura fixa para o diálogo
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.9,
              ),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Customer Information",
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close,
                                  color: Colors.black54,
                                  size: 24,
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextFormField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Place Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  enabled: editar,
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Please enter a place name'
                                      : null,
                                ),
                              
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _noteController,
                                  decoration: InputDecoration(
                                    labelText: 'Customer Note',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  enabled: editar,
                                  minLines: 5,
                                  maxLines: 5,
                                ),
                                SizedBox(height: 16),
                                editar
                                    ? ElevatedButton(
                                        onPressed: () {
                                          if (_formKey.currentState
                                                  ?.validate() ??
                                              false) {
                                          updateDataPlace();
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              Size(double.infinity, 48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text('Save'),
                                      )
                                    : SizedBox(height: 8),
                                SizedBox(height: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      Navigator.pop(context);
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity, 48),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text('Cancel'),
                                ),
                                SizedBox(height: 8),
                                !editar
                                    ? ElevatedButton(
                                        onPressed: () {
                                          deletePlace();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          minimumSize:
                                              Size(double.infinity, 48),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text('Delete'),
                                      )
                                    : SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}
