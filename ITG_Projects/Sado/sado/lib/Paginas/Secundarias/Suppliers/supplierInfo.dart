import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';
import 'package:sado/Paginas/Principais/Admin/Company/suppliersCompany.dart';
import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sidebarx/sidebarx.dart';

class SupplierDetailsPage extends StatefulWidget {
  final Map<String, dynamic> supplier;
  final String idCompany;

  SupplierDetailsPage({required this.supplier, required this.idCompany});

  @override
  _SupplierDetailsPageState createState() => _SupplierDetailsPageState();
}

class _SupplierDetailsPageState extends State<SupplierDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _address1Controller = TextEditingController();
  final TextEditingController _address2Controller = TextEditingController();
  final TextEditingController _zipCodeController = TextEditingController();

  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  final _controller = SidebarXController(selectedIndex: 3);

  bool _isLoading = false;
  bool editar = true;

  String? _countryName;
  String? _flagPath;
  String phoneNumber = ""; // Store the original phone number
  String dialCode = "";
  String _selectedCountryCode = 'PT';

  Country? _selectedCountry;
  late PhoneNumber number;

  List<Country> _countries = CountryList.countries;

  @override
  void initState() {
    super.initState();
    simulatorUserInfo();
  }

  Future<int> simulatorUserInfo() async {
    var concluido = 1;

    _nameController.text = widget.supplier['Name'] ?? '';
    _typeController.text = widget.supplier['Type'] ?? '';
    _mailController.text = widget.supplier['Mail'] ?? '';
    _address1Controller.text = widget.supplier['Address'] ?? '';
    _noteController.text = widget.supplier['Description'] ?? '';
    _address2Controller.text = widget.supplier['Address2'] ?? '';
    _zipCodeController.text = widget.supplier['ZipCode'] ?? '';
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(Duration(seconds: 1));

    // Extract country code and phone number from stored value
    String storedPhoneNumber = widget.supplier['Phone'] ?? '';
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

    _countryController.text = widget.supplier['Country'] ?? 'PT';
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

  void updateDataSupplier() async {
    var name = _nameController.text.trim().toString();
    var address = _address1Controller.text.trim().toString();
    var contact = dialCode + " " + _phoneController.text.trim().toString();
    var type = _typeController.text.trim().toString();
    var email = _mailController.text.trim().toString();
    var note = _noteController.text.trim().toString();
    var address2 = _address2Controller.text.trim().toString();
    var zipcode = _zipCodeController.text.trim().toString();
    var country = _countryController.text.trim().toString();
    var id = widget.supplier["IdSupplier"];

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'S4',
          'name': name,
          'type': type,
          'address': address,
          'phone': contact,
          'mail': email,
          'description': note,
          'address2': address2,
          'zipcode':zipcode,
          'country':country,
          'id': id
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        _showDialog(
            context, "Supplier Update", "Supplier updated successfully.", 1);
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
                              currentPage: SuppliersCompanyPage(
                                  idCompany: widget.idCompany),
                              numero: 3,
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

  void _onCountrySelected(Country? selectedCountry) {
    setState(() {
      _selectedCountry = selectedCountry;
      _countryName = selectedCountry?.name;
      _flagPath = selectedCountry?.flagPath;
      _countryController.text = selectedCountry?.code ?? '';
    });
  }

  Future<void> deleteSupplier() async {
    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'S3',
          'id': widget.supplier['IdSupplier'],
        },
      );
      print(response.body);
      if (response.statusCode == 200) {
        _showDialog(
            context, "Supplier Deleted", "Supplier Deleted successfully.", 1);
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                "Supplier Information",
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
                                    labelText: 'Supplier Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  enabled: editar,
                                  maxLength:
                                      75, // Restricts input to 75 characters

                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Name is required';
                                    }
                                    if (value.length > 75) {
                                      return 'You have exceeded the character limit.';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),
                                TextFormField(
                                  controller: _mailController,
                                  decoration: InputDecoration(
                                    labelText: 'Supplier Email',
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
                                  controller: _address1Controller,
                                  decoration: InputDecoration(
                                    labelText: 'Supplier Address 1',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  enabled: editar,
                                  maxLength: 150,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Address is required';
                                    }
                                    if (value.length > 150) {
                                      return 'You have exceeded the character limit.';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 200,
                                      child: TextFormField(
                                        controller: _address2Controller,
                                        decoration: InputDecoration(
                                          labelText: 'Supplier Address 2',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        enabled: editar,
                                        maxLength: 100,
                                        validator: (value) {
                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    SizedBox(
                                      width: 250,
                                      child: TextFormField(
                                        controller: _zipCodeController,
                                        decoration: InputDecoration(
                                          labelText:
                                              'Supplier Zip Code / Postal Code',
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        enabled: editar,
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
                                  ],
                                ),
                                SizedBox(height: 10),
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
                                    validator: (value) => value == null
                                        ? 'Please select a country'
                                        : null,
                                  ),
                                ),
                                SizedBox(height: 20),
                                TextFormField(
                                  controller: _typeController,
                                  decoration: InputDecoration(
                                    labelText: 'Supplier Type',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  maxLength:
                                      75, // Restricts input to 75 characters

                                  enabled: editar,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Type is required';
                                    }
                                    if (value.length > 75) {
                                      return 'You have exceeded the character limit.';
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    if (value.length > 75) {}
                                  },
                                ),
                                SizedBox(height: 10),
                                IgnorePointer(
                                  ignoring: !editar,
                                  child: InternationalPhoneNumberInput(
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
                                    textFieldController: _phoneController,
                                    inputDecoration: InputDecoration(
                                      labelText: 'Supplier Phone Number',
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
                                    labelText: 'Supplier Note',
                                    alignLabelWithHint:
                                        true, // Ensures the label stays on top

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
                                            updateDataSupplier();
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
                                          deleteSupplier();
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
