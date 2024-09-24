import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/customersCompany.dart';
import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebarx/sidebarx.dart';

class CustomerDetailsPage extends StatefulWidget {
  final Map<String, dynamic> customer;
  final String idCompany;

  CustomerDetailsPage({required this.customer, required this.idCompany});

  @override
  _CustomerDetailsPageState createState() => _CustomerDetailsPageState();
}

class _CustomerDetailsPageState extends State<CustomerDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nifController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  final _controller = SidebarXController(selectedIndex: 3);

  bool _isLoading = false;
  bool editar = true;

  String phoneNumber = ""; // Store the original phone number
  String dialCode = "";

  Country? _selectedCountry;
  late PhoneNumber number;

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
    _nameController.text = widget.customer['Name'] ?? '';
    _nifController.text = widget.customer['NIF'] ?? '';
    _mailController.text = widget.customer['Mail'] ?? '';
    _addressController.text = widget.customer['Address'] ?? '';
    _noteController.text = widget.customer['Description'] ?? '';

    // Extract country code and phone number from stored value
    String storedPhoneNumber = widget.customer['Phone'] ?? '';
    RegExp dialCodeRegex = RegExp(r'^(\+\d+)\s*(.*)$');
    Match? match = dialCodeRegex.firstMatch(storedPhoneNumber);

    dialCode = match != null ? match.group(1)! : '';
    phoneNumber = match != null ? match.group(2)! : '';

    // Get the country ISO code from the dial code
    String? isoCode = getCountryCodeFromDialCode(dialCode);
    number = isoCode != null
        ? PhoneNumber(isoCode: isoCode)
        : PhoneNumber(isoCode: 'AF');

    _phoneController.text = phoneNumber;

    setState(() {
      _isLoading = false;
    });

    return concluido;
  }

  String? getCountryCodeFromDialCode(String dialCode) {
    Map<String, String>? result = CountryCodes.findCountryByDialCode(dialCode);
    return result?['code']; // Return the ISO code
  }

  void updateDataCustomer() async {
    var name = _nameController.text.trim().toString();
    var address = _addressController.text.trim().toString();
    var contact = dialCode + " " + _phoneController.text.trim().toString();
    var nif = _nifController.text.trim().toString();
    var email = _mailController.text.trim().toString();
    var id = widget.customer["IdCustomer"];
    var note = _noteController.text.trim().toString();

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'M4',
          'name': name,
          'nif': nif,
          'address': address,
          'phone': contact,
          'mail': email,
          'id': id,
          'description': note,
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        _showDialog(
            context, "Customer Update", "Customer updated successfully.", 1);
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
                              currentPage: CustomersCompanyPage(
                                  idCompany: widget.idCompany),
                              numero: 4,
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

  Future<void> deleteCustomer() async {
    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'M3',
          'id': widget.customer['IdCustomer'],
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        _showDialog(
            context, "Customer Deleted", "Customer Deleted successfully.", 1);
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
                                    labelText: 'Customer Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  enabled: editar,
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Please enter a customer name'
                                      : null,
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _mailController,
                                  decoration: InputDecoration(
                                    labelText: 'Customer Email',
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
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _addressController,
                                  decoration: InputDecoration(
                                    labelText: 'Customer Address',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  enabled: editar,
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Please enter a customer address'
                                      : null,
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  controller: _nifController,
                                  decoration: InputDecoration(
                                    labelText: 'Customer Type',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  enabled: editar,
                                  validator: (value) => value?.isEmpty ?? true
                                      ? 'Please enter customer type'
                                      : null,
                                ),
                                SizedBox(height: 16),
                                IgnorePointer(
                                  ignoring: !editar,
                                  child: InternationalPhoneNumberInput(
                                    initialValue: number,
                                    selectorConfig: SelectorConfig(
                                      selectorType:
                                          PhoneInputSelectorType.BOTTOM_SHEET,
                                    ),
                                    ignoreBlank: false,
                                    autoValidateMode: AutovalidateMode.disabled,
                                    selectorTextStyle:
                                        TextStyle(color: Colors.black),
                                    textFieldController: _phoneController,
                                    inputDecoration: InputDecoration(
                                      labelText: 'Customer Phone Number',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      enabled: editar,
                                    ),
                                    formatInput: true,
                                    keyboardType:
                                        TextInputType.numberWithOptions(
                                            signed: true),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter a phone number';
                                      }
                                      if (value == phoneNumber) {
                                        return null;
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
                                            updateDataCustomer();
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
                                          deleteCustomer();
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
