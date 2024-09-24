import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/customersCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/placesCompany.dart';
import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/Paginas/Registo/companiesRegister.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreatePlace extends StatefulWidget {
  final String idCompany; // Define the type of id

  CreatePlace({Key? key, required this.idCompany}) : super(key: key);

  @override
  _CreatePlaceState createState() => _CreatePlaceState();
}

class _CreatePlaceState extends State<CreatePlace> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();

  var contador = 0;

  bool _isLoading = false;

  

  @override
  void initState() {
    super.initState();
    _initializeCountry();
  }

  Future<void> _initializeCountry() async {
    setState(() {
      _isLoading = true;
    });

    try {

      setState(() {
        if (contador == 0) {
         
          contador == 1;
        }
      });
    } catch (e) {
      print(e); // Consider using proper error handling here
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  void sendPlaceData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = _nameController.text.trim().toString();

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'P2',
          'name': name,
          'id': widget.idCompany,
        },
      );

      if (response.statusCode == 200) {
        _showDialog(
            context, "Place Register", "Registration was successful.", 1);
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
                    SlideTransitionPageRoute(
                      page: AdminDrawer(
                          currentPage: PlacesCompanyPage(
                              idCompany: widget.idCompany),
                          numero: 5),
                    ),
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
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.9),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Add Place",
                      style: TextStyle(color: Colors.blue)),
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
                          labelText: 'Place Name',
                          labelStyle: TextStyle(fontSize: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                        style: TextStyle(fontSize: 20),
                        autofillHints: [AutofillHints.givenName],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Place Name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            sendPlaceData();
                          }
                        },
                        child: Text('Submit'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancel'),
                        style: ElevatedButton.styleFrom(
                            //primary: Colors.grey,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
