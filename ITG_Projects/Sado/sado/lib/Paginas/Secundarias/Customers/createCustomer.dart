import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/customersCompany.dart';
import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/Paginas/Registo/companiesRegister.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateCustomer extends StatefulWidget {
  final String idCompany; // Define the type of id

  CreateCustomer({Key? key, required this.idCompany}) : super(key: key);

  @override
  _CreateCustomerState createState() => _CreateCustomerState();
}

class _CreateCustomerState extends State<CreateCustomer> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nifController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  var contador = 0;

  String _selectedCountryCode = 'PT';
  bool _isLoading = false;

  late PhoneNumber number;
  late String initialCountry;

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
      final ip = await getPublicIP();
      final countryCode = await getCountryFromIP(ip);

      setState(() {
        _selectedCountryCode = countryCode;
        if (contador == 0) {
          initialCountry = _selectedCountryCode;
          number = PhoneNumber(isoCode: _selectedCountryCode);
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

  void sendCustomerData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = _nameController.text.trim().toString();
    var contact = _phoneController.text.trim().toString();
    var nif = _nifController.text.trim().toString();
    var email = _mailController.text.trim().toString();
    var address = _addressController.text.trim().toString();

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'M2',
          'name': name,
          'mail': email,
          'phone': contact,
          'nif': nif,
          'address': address,
          'id': widget.idCompany,
        },
      );

      if (response.statusCode == 200) {
        _showDialog(
            context, "Customer Register", "Registration was successful.", 1);
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
                          currentPage: CustomersCompanyPage(
                              idCompany: widget.idCompany),
                          numero: 4),
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
                  const Text("Add Customer",
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
                          labelText: 'Customer Name',
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
                            return 'Customer Name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: _mailController,
                        decoration: InputDecoration(
                          labelText: 'Customer Email',
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
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: [AutofillHints.email],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Customer Email is required';
                          }
                          if (!EmailValidator.validate(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 500,
                      child: InternationalPhoneNumberInput(
                        onInputChanged: (phoneNumber) {
                          setState(() {
                            number = phoneNumber;
                            if (contador == 0) {
                              contador = 1;
                            }
                          });
                        },
                        onInputValidated: (bool value) {},
                        selectorConfig: SelectorConfig(
                          selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                          useBottomSheetSafeArea: true,
                        ),
                        autoValidateMode: AutovalidateMode.disabled,
                        ignoreBlank: false,
                        autoFocus: false,
                        selectorTextStyle:
                            TextStyle(color: Colors.black, fontSize: 20),
                        initialValue: number,
                        textFieldController: _phoneController,
                        formatInput: false,
                        keyboardType: TextInputType.numberWithOptions(
                            signed: true, decimal: true),
                        inputBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter the customer phone number';
                          } else {
                            _phoneController.text = number.dialCode.toString() +
                                " " +
                                _phoneController.text;
                          }
                          return null;
                        },
                        onSaved: (phoneNumber) {},
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Customer Address',
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
                        keyboardType: TextInputType.number,
                        autofillHints: [AutofillHints.password],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Customer Address is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: _nifController,
                        decoration: InputDecoration(
                          labelText: 'Customer NIF',
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
                        keyboardType: TextInputType.number,
                        autofillHints: [AutofillHints.password],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Customer NIF is required';
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
                            sendCustomerData();
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
