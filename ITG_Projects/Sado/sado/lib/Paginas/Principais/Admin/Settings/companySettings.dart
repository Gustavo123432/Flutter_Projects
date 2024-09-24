import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sado/assets/models/countriesData.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CompanySettingsPage extends StatefulWidget {
  @override
  _CompanySettingsPageState createState() => _CompanySettingsPageState();
}

class _CompanySettingsPageState extends State<CompanySettingsPage> {
  List<dynamic> company = [];
  List<String> countryList = [];
  Map<String, String> isoToCountryMap = {};
  Map<String, String> countryToIsoMap = {};
  bool isLoading = true;
  bool notExist = false;
  bool isEditing = false;

  TextEditingController nameController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController nifController = TextEditingController();
  TextEditingController dunsController = TextEditingController();
  TextEditingController colourController = TextEditingController();
  TextEditingController noteController = TextEditingController();

  Color selectedColor = Colors.blue;
  String? selectedCountry;

  @override
  void initState() {
    super.initState();
    initializeCountryData();
    fetchCompany();
  }

  void initializeCountryData() {
    countryList = CountryList.countries.map((country) => country.name).toList();
    isoToCountryMap = {
      for (var country in CountryList.countries) country.code: country.name
    };
    countryToIsoMap = {
      for (var country in CountryList.countries) country.name: country.code
    };
  }

  String getCountryNameFromCode(String isoCode) {
    return isoToCountryMap[isoCode] ?? "Unknown";
  }

  Color hexToColor(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 6 || hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  String colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  Future<void> fetchCompany() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idCodMaster = prefs.getString("idMaster");

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
          company = data;
          notExist = company.isEmpty;
          isLoading = false;
          if (!notExist) {
            nameController.text = company[0]['Name'];
            emailController.text = company[0]['Mail'];
            addressController.text = company[0]['Address'];
            phoneController.text = company[0]['Phone'];
            nifController.text = company[0]['NIF'];
            dunsController.text = company[0]['DUNS'];
            colourController.text = company[0]['Colour'];
            selectedColor = hexToColor(company[0]['Colour']);
            if (company[0]['Country'] == null)
              noteController.text = "";
            else
              noteController.text = company[0]['Description'];

            selectedCountry = getCountryNameFromCode(company[0]['Country']);
          }
        });
      } else {
        throw Exception('Failed to load company');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        notExist = true;
      });
      print('Error: $e');
    }
  }

  Future<void> updateCompany() async {
//    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'C4',
          'id': company[0]['IdCompany'],
          'name': nameController.text,
          'email': emailController.text,
          'address': addressController.text,
          'phone': phoneController.text,
          'nif': nifController.text,
          'duns': dunsController.text,
          'colour': selectedColor.value.toRadixString(16).substring(2),
          'description': noteController.text,
          'country': countryToIsoMap[selectedCountry ?? ''] ?? '',
        },
      );
      print(response.body);

      if (response.statusCode == 200) {
        print('Company updated successfully');
        setState(() {
          isEditing = false;
        });
      } else {
        throw Exception('Failed to update company');
      }
   /* } catch (e) {
      print('Error: $e');
    }*/
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Select Color'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (Color color) {
                setState(() {
                  selectedColor = color;
                });
              },
              showLabel: true,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Select'),
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  colourController.text = colorToHex(selectedColor);
                });
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Center(child: CircularProgressIndicator())
        : notExist
            ? Center(child: Text("Please, contact Support Team"))
            : MaterialApp(
                home: Scaffold(
                  appBar: AppBar(
                    title: Text('Company: ' + company[0]['Name']),
                    actions: [
                      IconButton(
                        icon: Icon(isEditing ? Icons.save : Icons.edit),
                        onPressed: () {
                          if (isEditing) {
                            updateCompany();
                          } else {
                            setState(() {
                              isEditing = true;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  body: ProfileForm(
                    isEditing: isEditing,
                    nameController: nameController,
                    emailController: emailController,
                    phoneController: phoneController,
                    addressController: addressController,
                    nifController: nifController,
                    dunsController: dunsController,
                    colourController: colourController,
                    noteController: noteController,
                    selectedCountry: selectedCountry,
                    countryList: countryList,
                    selectedColor: selectedColor,
                    onCountryChanged: (String? newValue) {
                      setState(() {
                        selectedCountry = newValue;
                      });
                    },
                    onColorTap: _showColorPickerDialog,
                  ),
                ),
              );
  }
}

class ProfileForm extends StatelessWidget {
  final bool isEditing;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController addressController;
  final TextEditingController phoneController;
  final TextEditingController nifController;
  final TextEditingController dunsController;
  final TextEditingController colourController;
  final TextEditingController noteController;
  final String? selectedCountry;
  final List<String> countryList;
  final Color selectedColor;
  final ValueChanged<String?> onCountryChanged;
  final VoidCallback onColorTap;

  ProfileForm({
    required this.isEditing,
    required this.nameController,
    required this.emailController,
    required this.addressController,
    required this.phoneController,
    required this.nifController,
    required this.dunsController,
    required this.colourController,
    required this.noteController,
    required this.selectedCountry,
    required this.countryList,
    required this.selectedColor,
    required this.onCountryChanged,
    required this.onColorTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Company Information',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nameController,
                      enabled: isEditing,
                      decoration: InputDecoration(
                        labelText: 'Company Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                ],
              ),
              SizedBox(height: 20),
              TextField(
                controller: emailController,
                enabled: isEditing,
                decoration: InputDecoration(
                  labelText: 'Company Mail',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: phoneController,
                enabled: isEditing,
                decoration: InputDecoration(
                  labelText: 'Company Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: addressController,
                      enabled: isEditing,
                      decoration: InputDecoration(
                        labelText: 'Company Address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: selectedCountry,
                      onChanged: isEditing ? onCountryChanged : null,
                      items: countryList
                          .map<DropdownMenuItem<String>>((String country) {
                        return DropdownMenuItem<String>(
                          value: country,
                          child: Text(country),
                        );
                      }).toList(),
                      decoration: InputDecoration(
                        labelText: 'Company Country',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: nifController,
                      enabled: isEditing,
                      decoration: InputDecoration(
                        labelText: 'Company NIF',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: TextField(
                      controller: dunsController,
                      enabled: isEditing,
                      decoration: InputDecoration(
                        labelText: 'Company DUNS',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: noteController,
                decoration: InputDecoration(
                  labelText: 'Collaborator Note',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                minLines: 5,
                maxLines: 5,
                enabled: isEditing,
              ),
              SizedBox(height: 20),
              Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Text(
                      'Select Company Color',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: isEditing ? onColorTap : null,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: selectedColor,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }
}
