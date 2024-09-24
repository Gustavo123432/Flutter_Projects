import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:sado/Paginas/Principais/Admin/dashboardPage.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:sado/Paginas/Login/login.dart'; // Ensure this import is correct
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CompaniesRegisterForm extends StatefulWidget {
  const CompaniesRegisterForm({super.key});

  @override
  _CompaniesRegisterFormState createState() => _CompaniesRegisterFormState();
}

class _CompaniesRegisterFormState extends State<CompaniesRegisterForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController NameController = TextEditingController();
  final TextEditingController CountryController = TextEditingController();
  final TextEditingController ContactController = TextEditingController();
  final TextEditingController NIFController = TextEditingController();
  final TextEditingController EmailController = TextEditingController();
  final TextEditingController DUNSController = TextEditingController();
  final TextEditingController AddressController = TextEditingController();

  dynamic numberint;
  dynamic selectedColor = Colors.blue;
  bool isHovered = false;
  var contador = 0;

  String _selectedCountryCode = 'ES';
  bool _isLoading = true; // Track loading state
  late PhoneNumber number;
  late String initialCountry;

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
          contador == 1;
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

  void companyRegister() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = NameController.text.trim().toString();
    var address = AddressController.text.trim().toString();
    var contact = ContactController.text.trim().toString();
    var nif = NIFController.text.trim().toString();
    var email = EmailController.text.trim().toString();
    var duns = DUNSController.text.trim().toString();
    var country = CountryController.text.trim().toString();
    var idUser = prefs.getString("idUser");

    print(country);

    final color =
        selectedColor.value.toRadixString(16).substring(2); // Corrected line

    if (color[0].toString() == 'l') {
      _showDialog(
          context, "Change Colour", "Select a different colour Please!", 0);
    } else {
      try {
        final response = await http.post(
          Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
          body: {
            'query_param': 'C2',
            'mail': email,
            'nif': nif,
            'duns': duns,
            'name': name,
            'address': address,
            'phone': contact,
            'colour': color, // Corrected line
            'country': country,
            'codmaster': idUser,
          },
        );

        if (response.statusCode == 200) {
          _showDialog(
              context, "Company Register", "Registration was successful.", 1);
        } else {
          _showDialog(context, 'Error', 'Failed to connect to the server.', 0);
        }
      } catch (e) {
        _showDialog(context, 'Error',
            'An unexpected error occurred. Please try again later.', 0);
      }
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
            backgroundColor: Colors.white, // Customize the background color
            actions: <Widget>[
              TextButton(
                child: Text('OK', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (value == 1) {
                    Navigator.push(
                      context,
                      SlideTransitionPageRoute(
                      page: AdminDrawer(currentPage: DashboardPage(), numero: 0),
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

  void changeColor(Color color) {
    setState(() {
      selectedColor = color;
    });
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
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
                              "Company Registration",
                              style: TextStyle(
                                color: Colors.blueAccent,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 30),
                            SizedBox(
                              width: 700,
                              child: TextFormField(
                                controller: NameController,
                                decoration: InputDecoration(
                                  labelText: 'Company Name',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                autofillHints: [AutofillHints.organizationName],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the company name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: 700,
                              child: TextFormField(
                                controller: EmailController,
                                decoration: InputDecoration(
                                  labelText: 'Company Email',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: [AutofillHints.email],
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the company email';
                                  } else if (!EmailValidator.validate(value)) {
                                    return 'Please enter a valid email address';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            SizedBox(height: 20),
                            Container(
                              width: 700, // Maximum width
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
                                  labelText: 'Company Phone Number',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter the company phone number';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 350,
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedCountryCode,
                                    decoration: InputDecoration(
                                      labelText: 'Country',
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
                                const SizedBox(width: 20),
                                SizedBox(
                                  width: 350,
                                  child: TextFormField(
                                    controller: AddressController,
                                    decoration: InputDecoration(
                                      labelText: 'Company Address',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    autofillHints: [
                                      AutofillHints.fullStreetAddress
                                    ],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the company address';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 350,
                                  child: TextFormField(
                                    controller: NIFController,
                                    decoration: InputDecoration(
                                      labelText: 'Company NIF',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    autofillHints: [AutofillHints.nif],
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the company NIF';
                                      } else if (value.length != 9) {
                                        return 'NIF should be 9 digits';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(height: 20),
                                SizedBox(
                                  width: 350,
                                  child: TextFormField(
                                    controller: DUNSController,
                                    decoration: InputDecoration(
                                      labelText: 'Company DUNS (Optional)',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    keyboardType: TextInputType.number,
                                    /*autofillHints: [AutofillHints.nif],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter the company NIF';
                                } else if (value.length != 9) {
                                  return 'NIF should be 9 digits';
                                }
                                return null;
                              },*/
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 30),
                            Text(
                              'Select Company Color',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 10),
                            GestureDetector(
                              onTap: _showColorPickerDialog,
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
                            SizedBox(height: 40),
                            ElevatedButton(
                              onPressed: () {
                                if (_formKey.currentState!.validate()) {
                                  companyRegister();
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
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Hero(
              tag: 'blue-container',
              child: Container(
                color: Colors.blue,
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'lib/assets/logo.png',
                  width: 200,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 350,
            child: TextField(
              //controller: CodeController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Handle Sign Up
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione uma Cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}
