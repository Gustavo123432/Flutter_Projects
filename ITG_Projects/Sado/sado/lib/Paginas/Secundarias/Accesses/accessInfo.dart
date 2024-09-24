import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Settings/accessSettings.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';

import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebarx/sidebarx.dart';

class StatusAccess {
  final String name;
  final String id;

  StatusAccess({required this.name, required this.id});
}

class AccessDetailsPage extends StatefulWidget {
  final Map<String, dynamic> access;

  AccessDetailsPage({required this.access});

  @override
  _AccessDetailsPageState createState() => _AccessDetailsPageState();
}

class _AccessDetailsPageState extends State<AccessDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  final _controller = SidebarXController(selectedIndex: 3);

  // Updated list with both status options
  List<StatusAccess> _statusAccessPermissions = [
    StatusAccess(name: "Ativo", id: "0"),
    StatusAccess(name: "Desative", id: "1"),
  ];

  String? _selectedStatusAccess;

  bool desativarStatus = false;

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
    _nameController.text = widget.access['Name'] ?? '';
    _selectedStatusAccess = widget.access['Deleted'] ?? '';

    if (widget.access['Access'] == '4' || widget.access['Access'] == '0') {
      desativarStatus = false;
    } else {
      desativarStatus = true;
    }

    setState(() {
      _isLoading = false;
    });

    return concluido;
  }

  void updateDataPlace() async {
    var name = _nameController.text.trim().toString();
    var id = widget.access["IdProfile"];
    print(_selectedStatusAccess);

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'A4',
          'name': name,
          'del': _selectedStatusAccess,
          'id': id
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        _showDialog(
            context, "Status Update", "Status updated successfully.", 1);
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
                            currentPage: AccessSettingsPage(), numero: 11)),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _onStatusAccessChange(String? value) {
    setState(() {
      _selectedStatusAccess = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black12,
      insetPadding: EdgeInsets.zero, // Remove default padding around the dialog
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : AlertDialog(
              backgroundColor: Colors.white,
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Access Information",
                    style: TextStyle(color: Colors.blue),
                  ),
                  SizedBox(
                    width: 325,
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.black,
                      size: 24,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                  ),
                ],
              ),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Access Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        enabled: editar,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter an access name'
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    desativarStatus
                        ? SizedBox(
                            width: 240,
                            child: DropdownButtonFormField<String>(
                              value: _selectedStatusAccess,
                              hint: Text('Select Status'),
                              onChanged: editar
                                  ? (value) {
                                      _onStatusAccessChange(value);
                                    }
                                  : null,
                              items: _statusAccessPermissions
                                  .map((StatusAccess access) {
                                return DropdownMenuItem<String>(
                                  value: access.id,
                                  child: Text(access.name),
                                );
                              }).toList(),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select status';
                                }
                                return null;
                              },
                            ),
                          )
                        : SizedBox(height: 1),
                    SizedBox(height: 16),
                    editar
                        ? ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                updateDataPlace();
                              }
                            },
                            child: Text('Save'),
                          )
                        : SizedBox(height: 8),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          editar = !editar; // Toggle edit mode
                        });
                      },
                      child: Text(editar ? 'Cancel' : 'Edit'),
                    ),
                    SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }
}
