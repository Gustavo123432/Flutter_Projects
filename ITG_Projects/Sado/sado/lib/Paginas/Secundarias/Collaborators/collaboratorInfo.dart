import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';
import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CollaboratorDetailsPage extends StatefulWidget {
  final Map<String, dynamic> user;
  final String idCompany;

  CollaboratorDetailsPage({required this.user, required this.idCompany});

  @override
  _CollaboratorDetailsPageState createState() =>
      _CollaboratorDetailsPageState();
}

class _CollaboratorDetailsPageState extends State<CollaboratorDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nifController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  bool _isLoading = false;
  bool editar = false;

  String? _countryName;
  String? _flagPath;
  String phoneNumber = "";
  String dialCode = "";

  Country? _selectedCountry;
  late PhoneNumber number;

  List<Country> _countries = CountryList.countries;

  @override
  void initState() {
    super.initState();
    simulatorUserInfo();
    //   number = PhoneNumber(isoCode: 'US');
  }

  @override
  void dispose() {
    _countryController.dispose();
    super.dispose();
  }

  Future<int> simulatorUserInfo() async {
    var concluido = 1;

    setState(() {
      _isLoading = true;
    });

    await Future.delayed(Duration(seconds: 3));
    _firstNameController.text = widget.user['FirstName'] ?? '';
    _lastNameController.text = widget.user['LastName'] ?? '';
    _mailController.text = widget.user['Mail'] ?? '';
    _dateController.text = widget.user['Birthdate'] ?? '';
    _nifController.text = widget.user['NIF'] ?? '';
    _noteController.text = widget.user['Description'] ?? '';

    // Extract country code and phone number from stored value
    String storedPhoneNumber = widget.user['Phone'] ?? '';
    RegExp dialCodeRegex = RegExp(r'^(\+\d+)\s*(.*)$');
    Match? match = dialCodeRegex.firstMatch(storedPhoneNumber);

    dialCode = match != null ? match.group(1)! : '';
    phoneNumber = match != null ? match.group(2)! : '';

    // Get the country ISO code from the dial code
    String? isoCode = getCountryCodeFromDialCode(dialCode);
    print(isoCode);

    if (isoCode != null) {
      print(isoCode);
      number = PhoneNumber(isoCode: isoCode);
    } else {
      number = PhoneNumber(isoCode: 'AF');

      print('No country found with dial code $dialCode');
    }

    _phoneController.text = phoneNumber;

    _countryController.text = widget.user['Country'] ?? '';
    final initialCountryCode = _countryController.text;
    _selectedCountry = getCountryByCode(initialCountryCode);

    if (_selectedCountry != null) {
      _countryName = _selectedCountry!.name;
      _flagPath = _selectedCountry!.flagPath;
    } else {
      _countryName = 'Invalid country code';
      _flagPath = null;
    }

    setState(() {
      _isLoading = false;
    });

    return concluido;
  }

  Country? getCountryByCode(String code) {
    return _countries.firstWhere(
      (country) => country.code == code.toUpperCase(),
      //orElse: () => Country(code: '', name: 'Invalid code', flagPath: null), // Use default country with invalid code
    );
  }

  String? getCountryCodeFromDialCode(String dialCode) {
    Map<String, String>? result = CountryCodes.findCountryByDialCode(dialCode);
    return result?['code']; // Return the ISO code
  }

  void updateDataUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = _firstNameController.text.trim().toString();
    var lastName = _lastNameController.text.trim().toString();
    var contact = dialCode + " " + _phoneController.text.trim().toString();
    var nif = _nifController.text.trim().toString();
    var email = _mailController.text.trim().toString();
    var birthday = _dateController.text.trim().toString();
    var country = _countryController.text.trim().toString();
    var id = widget.user["CodUser"];
    var idUser = prefs.getString("idUser");
    var note = _noteController.text.trim().toString();

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'W4',
          'fname': name,
          'lname': lastName,
          'mail': email,
          'phone': contact,
          'bdate': birthday,
          'nif': nif,
          'country': country,
          'id': id,
          'description': note
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        _showDialog(context, "Collaborator Update", "Collaborator updated successfully.", 1);
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
                        builder: (context) => AdminDrawer(currentPage: CollaboratorsCompanyPage(idCompany: widget.idCompany), numero: 2)),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _onCountrySelected(Country? selectedCountry) {
    setState(() {
      _selectedCountry = selectedCountry;
      _countryName = selectedCountry?.name;
      _flagPath = selectedCountry?.flagPath;
      _countryController.text = selectedCountry?.code ?? '';
    });
  }

  Future<void> deleteUser() async {
    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'W5',
          'id': widget.user['CodUser'],
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        _showDialog(context, "Collaborator Deleted", "Collaborator Deleted successfully.", 1);
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
    DateTime now = DateTime.now();
    DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

    return Dialog(
      backgroundColor: Colors.black12,
      insetPadding: EdgeInsets.zero, // Remove default padding around the dialog
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : AlertDialog(
              backgroundColor: Colors.white.withOpacity(0.9),
              title: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Collaborator Information",
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
                        controller: _firstNameController,
                        decoration: InputDecoration(
                          labelText: 'Collaborator First Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        enabled: editar,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a first name'
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Collaborator Last Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        enabled: editar,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter a last name'
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                          controller: _mailController,
                          decoration: InputDecoration(
                            labelText: 'Collaborator Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          enabled: editar,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!EmailValidator.validate(value)) {
                              return 'Please enter a valid email address';
                            }
                            return null;
                          }),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Collaborator Date of Birthday',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.calendar_today),
                            onPressed: () async {
                              DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: eighteenYearsAgo,
                                firstDate: DateTime(1900),
                                lastDate: eighteenYearsAgo,
                              );
                              if (picked != null) {
                                setState(() {
                                  _dateController.text =
                                      DateFormat('yyyy-MM-dd').format(picked);
                                });
                              }
                            },
                          ),
                        ),
                        enabled: editar,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter your date of birth'
                            : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    IgnorePointer(
                      ignoring: !editar,
                      child: Container(
                        width: 500,
                        child: InternationalPhoneNumberInput(
                          initialValue: number,
                          selectorConfig: SelectorConfig(
                            selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                          ),
                          ignoreBlank: false,
                          autoValidateMode: AutovalidateMode.disabled,
                          selectorTextStyle: TextStyle(color: Colors.black),
                          textFieldController: _phoneController,
                          inputDecoration: InputDecoration(
                            labelText: 'Collaborator Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            enabled:
                                editar, // Use 'enabled' property inside InputDecoration
                          ),
                          inputBorder: OutlineInputBorder(),
                          formatInput: true,
                          keyboardType:
                              TextInputType.numberWithOptions(signed: true),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a phone number';
                            }
                            if (value == phoneNumber) {
                              return null; // The phone number has not been changed
                            }
                            return null;
                          },
                          onInputChanged: (PhoneNumber number) {
                            setState(() {
                              phoneNumber = number.phoneNumber!;
                              dialCode = number.dialCode!;
                            });
                          },
                          onInputValidated: (bool value) {
                            print('Phone number is valid: $value');
                          },
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: _nifController,
                        decoration: InputDecoration(
                          labelText: 'NIF',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        enabled: editar,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Please enter NIF' : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 500,
                      child: DropdownButtonFormField<Country>(
                        value: _selectedCountry,
                        onChanged: editar
                            ? (Country? newCountry) =>
                                _onCountrySelected(newCountry)
                            : null,
                        items: _countries.map((Country country) {
                          return DropdownMenuItem<Country>(
                            value: country,
                            child: Row(
                              children: [
                                if (country.flagPath != null)
                                  Image.asset(country.flagPath!,
                                      width: 30, height: 20),
                                SizedBox(width: 10),
                                Text(country.name),
                              ],
                            ),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          labelText: 'Select Country',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        validator: (value) =>
                            value == null ? 'Please select a country' : null,
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: 'Collaborator Note',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        enabled: editar,
                        minLines: 5, // Define o número mínimo de linhas
                        maxLines: 5, // Define o número máximo de linhas
                      ),
                    ),
                    SizedBox(height: 16),
                    editar
                        ? ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                updateDataUser();
                              }
                            },
                            child: Text(editar ? 'Save' : ''),
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
                    editar
                        ? SizedBox(height: 8)
                        : ElevatedButton(
                            onPressed: () {
                              deleteUser();
                            },
                            child: Text(editar ? '' : 'Delete'),
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}
