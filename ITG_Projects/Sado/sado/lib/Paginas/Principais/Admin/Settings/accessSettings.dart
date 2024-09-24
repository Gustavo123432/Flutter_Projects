import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Login/login.dart';
import "package:sado/Paginas/Secundarias/Accesses/accessInfo.dart";
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AccessSettingsPage extends StatefulWidget {
  @override
  _AccessSettingsPageState createState() => _AccessSettingsPageState();
}

class _AccessSettingsPageState extends State<AccessSettingsPage> {
  List<dynamic> accesses = [];
  List<dynamic> companies = [];
  bool isLoading = true;
  bool notExist = true;

  @override
  void initState() {
    super.initState();
    fetchUsersByCompanyId();
  }

  Future<void> fetchUsersByCompanyId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idCodMaster = prefs.getString("idMaster");

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'A2',
          'id': idCodMaster,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print(data);
        setState(() {
          accesses = data;
          notExist = accesses.isEmpty;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load accesses');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        notExist = true;
      });
      print('Error: $e');
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
    return Scaffold(
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : notExist
              ? Center(child: Text("Create a New Access, Please!"))
              : ListView(
                  padding: const EdgeInsets.all(8.0),
                  children: accesses.map((access) {
                    String? nomeAccess;
                    var accessn = access['Deleted'];
                    switch (accessn) {
                      case '0':
                        nomeAccess = "Active";
                        break;
                      case '1':
                        nomeAccess = "Desactive";
                        break;
                      default:
                        nomeAccess = "N/A";
                    }
                    return Card(
                      color: access['Deleted'] == '1' ? Colors.grey[300] : Colors.white, // Changes the card color if deleted
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${access['Name']}',
                              style: TextStyle(
                                fontSize: 20.0,
                                fontWeight: FontWeight.bold,
                                color: access['Deleted'] == '1' ? Colors.black54 : Colors.black, // Adjusts text color for disabled state
                              ),
                            ),
                            SizedBox(height: 12.0),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Status:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: access['Deleted'] == '1' ? Colors.black54 : Colors.black,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    nomeAccess,
                                    style: TextStyle(
                                      color: access['Deleted'] == '1' ? Colors.black54 : Colors.black,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    '1:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.transparent,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16.0),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: IconButton(
                                icon: Icon(Icons.edit),
                                onPressed: () {
                                  // Allows editing even if the access is marked as deleted
                                  Navigator.of(context).push(
                                    PageRouteBuilder(
                                      opaque: false,
                                      pageBuilder: (BuildContext context, _, __) => AccessDetailsPage(
                                        access: access,
                                      ),
                                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                        return FadeTransition(
                                          opacity: animation,
                                          child: child,
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
