import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sado/Paginas/Registo/companiesRegister.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';

class UserRegisterForm extends StatefulWidget {
  const UserRegisterForm({super.key});

  @override
  _UserRegisterFormState createState() => _UserRegisterFormState();
}

class _UserRegisterFormState extends State<UserRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController FirstNameController = TextEditingController();
  final TextEditingController LastNameController = TextEditingController();
  final TextEditingController CountryController = TextEditingController();
  final TextEditingController ContactController = TextEditingController();
  final TextEditingController NIFController = TextEditingController();
  final TextEditingController DateController = TextEditingController();

  String _selectedCountryCode = 'ES';
  bool _isLoading = true; // Track loading state
  late PhoneNumber number;
  late String initialCountry;
  var contador = 0;

  @override
  void initState() {
    super.initState();
    _initializeCountry();
  }

  Future<void> _initializeCountry() async {
    setState(() {
      _isLoading = true; // Start loading
    });

    try {
      final ip = await getPublicIP();
      final countryCode = await getCountryFromIP(ip);

      setState(() {
        _selectedCountryCode = countryCode;
        CountryController.text = countryCode;
        if (contador == 0) {
          initialCountry = _selectedCountryCode;
          number = PhoneNumber(isoCode: _selectedCountryCode);
          contador = 1;
        }
      });
    } catch (e) {
      print(e); // Handle errors here
    } finally {
      setState(() {
        _isLoading = false; // End loading
      });
    }
  }

  Future<String> getPublicIP() async {
    final response = await http.get(Uri.parse('https://httpbin.org/ip'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['origin'];
    } else {
      throw Exception('Failed to get IP address');
    }
  }

  Future<String> getCountryFromIP(String ip) async {
    final response = await http.get(Uri.parse('http://ip-api.com/json/$ip'));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['countryCode'];
    } else {
      throw Exception('Failed to get country from IP');
    }
  }

  void signInData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var firstName = FirstNameController.text.trim().toString();
    var lastName = LastNameController.text.trim().toString();
    var country = CountryController.text.trim().toString();
    var contact = ContactController.text.trim().toString();
    var nif = NIFController.text.trim().toString();
    var birthday = DateController.text.trim().toString();
    var idUser = prefs.getString("idUser");
    print(idUser);
    print("\n"+country);

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'U5',
          'firstname': firstName,
          'lastname': lastName,
          'phone': contact,
          'date': birthday,
          'nif': nif,
          'country': country,
          'id': idUser,
        },
      );

      if (response.statusCode == 200) {
        _showDialog(
            context, "Thank You", "Registration was successful.\nWelcome!", 1);
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
    if (value != 2) {
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
                        builder: (context) => CompaniesRegisterForm(),
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
  }

  void _onCountryChange(String? newCountryCode) {
    setState(() {
      _selectedCountryCode = newCountryCode!;
      CountryController.text = newCountryCode;
      if (contador == 0) {
        contador = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const webScreenSize = 600;
        if (constraints.maxWidth > webScreenSize) {
          return webScreenLayout();
        } else {
          return mobileScreenLayout();
        }
      },
    );
  }

  Widget webScreenLayout() {
    DateTime now = DateTime.now();
    DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: _isLoading
            ? CircularProgressIndicator() // Show progress indicator when loading
            : Flex(
                direction: Axis.horizontal,
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Text(
                              "User Data",
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 240,
                                  child: TextFormField(
                                    controller: FirstNameController,
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      labelStyle: TextStyle(fontSize: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal: 15,
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 20),
                                    autofillHints: [
                                      AutofillHints.givenName,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'First Name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 240,
                                  child: TextFormField(
                                    controller: LastNameController,
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      labelStyle: TextStyle(fontSize: 20),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        vertical: 15,
                                        horizontal: 15,
                                      ),
                                    ),
                                    style: TextStyle(fontSize: 20),
                                    autofillHints: [
                                      AutofillHints.familyName,
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Last Name is required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 500,
                              child: TextFormField(
                                controller: DateController,
                                decoration: InputDecoration(
                                  labelText: 'Date of Birth',
                                  labelStyle: TextStyle(fontSize: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 15,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(Icons.calendar_today),
                                    onPressed: () async {
                                      DateTime? pickedDate =
                                          await showDatePicker(
                                        context: context,
                                        initialDate: eighteenYearsAgo,
                                        firstDate: DateTime(1900),
                                        lastDate: eighteenYearsAgo,
                                      );
                                      if (pickedDate != null) {
                                        DateController.text =
                                            DateFormat('yyyy-MM-dd')
                                                .format(pickedDate);
                                      }
                                    },
                                  ),
                                ),
                                readOnly: true,
                                style: TextStyle(fontSize: 20),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Date of Birth is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 500,
                              child: DropdownButtonFormField<String>(
                                value: _selectedCountryCode,
                                decoration: InputDecoration(
                                  labelText: 'Country',
                                  labelStyle: TextStyle(fontSize: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 15,
                                  ),
                                ),
                                items: CountryList.countries
                                    .map((Country country) {
                                  return DropdownMenuItem<String>(
                                    value: country.code,
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          country.flagPath,
                                          width: 24,
                                          height: 24,
                                        ),
                                        SizedBox(width: 8),
                                        Text(country.name),
                                      ],
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  _onCountryChange(value);
                                },
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Country is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Container(
                              width: 500, // Maximum width
                              child: InternationalPhoneNumberInput(
                                onInputChanged: (PhoneNumber number) {
                                  setState(() {
                                    number = number;
                                    if (contador == 0) {
                                      contador = 1;
                                    }
                                  });
                                },
                                selectorConfig: SelectorConfig(
                                  selectorType:
                                      PhoneInputSelectorType.BOTTOM_SHEET,
                                  showFlags: true,
                                ),
                                ignoreBlank: false,
                                autoValidateMode: AutovalidateMode.disabled,
                                textFieldController: ContactController,
                                formatInput: true,
                                maxLength: 15,
                                keyboardType: TextInputType.numberWithOptions(
                                  signed: true,
                                  decimal: true,
                                ),
                                initialValue: number,
                                inputDecoration: InputDecoration(
                                  labelText: 'Mobile Phone Number',
                                  //prefixIcon: Icon(Icons.phone),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8.0),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the mobile phone number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: 500,
                              child: TextFormField(
                                controller: NIFController,
                                decoration: InputDecoration(
                                  labelText: 'NIF',
                                  labelStyle: TextStyle(fontSize: 20),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                    horizontal: 15,
                                  ),
                                ),
                                style: TextStyle(fontSize: 20),
                                autofillHints: [
                                  AutofillHints.givenName,
                                ],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'NIF is required';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  signInData();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                minimumSize: Size(200, 50),
                                side: BorderSide(
                                  color: Color.fromARGB(150, 84, 155, 231),
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget mobileScreenLayout() {
    // Implement mobile screen layout
    return Container(); // Replace with actual mobile layout
  }
}
