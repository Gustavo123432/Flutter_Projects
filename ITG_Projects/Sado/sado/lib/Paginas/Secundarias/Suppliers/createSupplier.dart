import 'dart:convert';

import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Company/suppliersCompany.dart';
import 'package:sado/Paginas/Principais/Admin/dashboardPage.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateSuppliersForm extends StatefulWidget {
  final String idCompany;
  @override
  CreateSuppliersForm({super.key, required this.idCompany});

  @override
  _CreateSuppliersFormState createState() => _CreateSuppliersFormState();
}

class _CreateSuppliersFormState extends State<CreateSuppliersForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contController = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  dynamic numberint;
  bool isHovered = false;
  bool _isLoading = false;

    String phoneNumber = ""; // Store the original phone number
  String dialCode = "";

  String _selectedCountryCode = 'PT';
  Country? _selectedCountry;
  String? _countryName;
  String? _flagPath;
  List<Country> _countries = CountryList.countries;

  @override
  void initState() {
    super.initState();
  }

  void sendSupplierData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = _nameController.text.trim().toString();
    var address = _addressController.text.trim().toString();
    var contact = _contController.text.trim().toString();
    var type = _typeController.text.trim().toString();
    var email = _mailController.text.trim().toString();
    var address2 = _address2Controller.text.trim().toString();
    var zipcode = _zipCodeController.text.trim().toString();
    var country = _countryController.text.trim().toString();

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'S2',
          'name': name,
          'type': type,
          'address': address,
          'id': widget.idCompany,
          'mail': email,
          'phone': contact,
          'address2': address2,
          'zipcode': zipcode,
          'country': country,
        },
      );

      if (response.statusCode == 200) {
        _showDialog(
            context, "Supplier Register", "Registration was successful.", 1);
      } else {
        _showDialog(context, 'Error', 'Failed to connect to the server.', 0);
      }
    } catch (e) {
      _showDialog(context, 'Error',
          'An unexpected error occurred. Please try again later.', 0);
    }
  }

  void _onCountrySelected(Country? selectedCountry) {
    setState(() {
      _selectedCountry = selectedCountry;
      _countryName = selectedCountry?.name;
      _flagPath = selectedCountry?.flagPath;
      _countryController.text = selectedCountry?.code ?? '';
    });
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
                        page: AdminDrawer(
                            currentPage: SuppliersCompanyPage(
                                idCompany: widget.idCompany),
                            numero: 3),
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

  String initialCountry = 'PT';
  PhoneNumber number = PhoneNumber(isoCode: 'PT');

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
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 255, 255, 255),
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
                ? Center(
                    child: SizedBox(
                      width: 50, // Adjust size as needed
                      height: 50, // Adjust size as needed
                      child: CircularProgressIndicator(),
                    ),
                  )
                : SingleChildScrollView(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Supplier Create",
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
                      Form(
                        key: _formKey,
                        child: SizedBox(
                          width: 500, // Change size here as well
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Supplier Name',
                                  icon: Icons.business,
                                  maxLength: 75,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Supplier Name is required';
                                    }
                                    if (value.length > 75) {
                                      return 'You have exceeded the character limit.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                _buildTextField(
                                  controller: _mailController,
                                  label: 'Supplier Mail',
                                  icon: Icons.email,
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
                                const SizedBox(height: 10),
                                _buildTextField(
                                  controller: _addressController,
                                  label: 'Supplier Address 1',
                                  icon: Icons.home,
                                  maxLength: 150,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Supplier Address 1 is required';
                                    }
                                    if (value.length > 150) {
                                      return 'You have exceeded the character limit.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                Row(children: [
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _address2Controller,
                                      label: 'Supplier Address 2',
                                      icon: Icons.home_work,
                                      maxLength: 100,
                                      validator: (value) {
                                        return null; // Optional field
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _buildTextField(
                                      controller: _zipCodeController,
                                      label: 'Zip Code',
                                      icon: Icons.location_pin,
                                      maxLength: 30,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Zip Code / Postal Code is required';
                                        }
                                        if (value.length > 30) {
                                          return 'You have exceeded the character limit.';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ]),
                                const SizedBox(height: 10),
                                DropdownButtonFormField<Country>(
                                  value: _selectedCountry,
                                  onChanged: (Country? newCountry) =>
                                      _onCountrySelected(newCountry),
                                  items: _countries.map((Country country) {
                                    return DropdownMenuItem<Country>(
                                      value: country,
                                      child: Row(
                                        children: [
                                          if (country.flagPath != null)
                                            Image.asset(country.flagPath!,
                                                width: 30, height: 20),
                                          const SizedBox(width: 10),
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
                                  validator: (value) => value == null
                                      ? 'Please select a country'
                                      : null,
                                ),
                                const SizedBox(height: 10),
                                _buildTextField(
                                  controller: _typeController,
                                  label: 'Supplier Type',
                                  icon: Icons.category,
                                  maxLength: 75,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Supplier type is required';
                                    }
                                    if (value.length > 75) {
                                      return 'You have exceeded the character limit.';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 10),
                                InternationalPhoneNumberInput(
                                    initialValue: number,
                                    selectorConfig: SelectorConfig(
                                      selectorType:
                                          PhoneInputSelectorType.DIALOG,
                                          useEmoji: false,
                                          showFlags: true,
                                    ),
                                    ignoreBlank: false,
                                    autoValidateMode: AutovalidateMode.disabled,
                                    selectorTextStyle:
                                        TextStyle(color: Colors.black),
                                    textFieldController: _contController,
                                    inputDecoration: InputDecoration(
                                      labelText: 'Supplier Phone Number',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
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
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            sendSupplierData();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text('Save'),
                      ),
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
                    ]),
                  ),
          ));
        },
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int? maxLength,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      maxLength: maxLength,
      validator: validator,
    );
  }
}
