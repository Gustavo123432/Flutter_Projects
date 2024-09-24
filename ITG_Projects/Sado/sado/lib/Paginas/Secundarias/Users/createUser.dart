import 'dart:convert';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';
import 'package:sado/Paginas/Principais/Admin/userPage.dart';
import 'package:sado/Paginas/Registo/companiesRegister.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/assets/models/countriesData.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Company {
  final String name;
  final String id;

  Company({required this.id, required this.name});

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['IdCompany'],
      name: json['Name'],
    );
  }
}

class ProfileAccess {
  final String name;
  final String permission;

  ProfileAccess({required this.name, required this.permission});

  factory ProfileAccess.fromJson(Map<String, dynamic> json) {
    return ProfileAccess(
      name: json['Name'],
      permission: json['Access'],
    );
  }
}

class CreateUserForm extends StatefulWidget {
  @override
  CreateUserForm({super.key});

  @override
  _CreateUserFormState createState() => _CreateUserFormState();
}

class _CreateUserFormState extends State<CreateUserForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nifController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();

  var contador = 0;

  String? _selectedCompany;
  String? _selectedProfileAccess;
  String _selectedCountryCode = 'PT';
  bool _isLoading = false;
  bool pwdVisible = false;
  bool pwdVisiblee = false;
  bool dropLoad = true;

  late PhoneNumber number;
  late String initialCountry;

  List<Company> _companies = [];
  List<ProfileAccess> _profileAccessPermissions = [];

  @override
  void initState() {
    super.initState();
    _initializeCountry();
    fetchCompanies();
    fetchProfileAccessPermissions();
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
        _countryController.text = countryCode;
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

  Future<void> fetchCompanies() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idMaster = prefs.getString("idMaster");
    final response = await http.post(
      Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
      body: {
        'query_param': 'C1',
        'id': idMaster,
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        _companies = data.map((json) => Company.fromJson(json)).toList();
      });
    } else {
      print('Failed to load companies');
    }
  }

  Future<void> fetchProfileAccessPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idMaster = prefs.getString("idMaster");

    setState(() {
      dropLoad = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'A1',
          'id': idMaster,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _profileAccessPermissions =
              data.map((json) => ProfileAccess.fromJson(json)).toList();
        });
      } else {
        print('Failed to load profile access permissions');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        dropLoad = false;
      });
    }
  }

  void sendUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = _firstNameController.text.trim().toString();
    var lastName = _lastNameController.text.trim().toString();
    var contact = _phoneController.text.trim().toString();
    var nif = _nifController.text.trim().toString();
    var email = _mailController.text.trim().toString();
    var birthday = _dateController.text.trim().toString();
    var country = _selectedCountryCode;
    var pwd = _passwordController.text.trim().toString();
    var codCompany = _selectedCompany;
    var codAccess = _selectedProfileAccess;

    if (pwd == null) {
      pwd = " ";
    }
    var idUser = prefs.getString("idUser");

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'W2',
          'fname': name,
          'lname': lastName,
          'mail': email,
          'phone': contact,
          'bdate': birthday,
          'nif': nif,
          'country': country,
          'pwd': pwd,
          'codcompany': codCompany,
          'codaccess': codAccess,
        },
      );

      if (response.statusCode == 200) {
        _showDialog(
            context, "User Register", "Registration was successful.", 1);
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
                      page: AdminDrawer(currentPage: UserPage(), numero: 10),
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

  void _onCountryChange(String? newCountryCode) {
    setState(() {
      _selectedCountryCode = newCountryCode!;
      _countryController.text = newCountryCode;
      if (contador == 0) {
        contador = 1;
      }
    });
  }

  void _onCompanyChange(String? value) {
    setState(() {
      _selectedCompany = value;
    });
  }

  void _onProfileAccessChange(String? value) {
    setState(() {
      _selectedProfileAccess = value;
      pwdVisible = value != '0'; // Shows password fields if value is not '0'
    });
  }

  void _onDropdownOpen() async {
    setState(() {
      dropLoad = true;
    });

    // Simulate loading delay
    await Future.delayed(Duration(seconds: 10));

    setState(() {
      dropLoad = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    DateTime eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);

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
                  const Text("Add User", style: TextStyle(color: Colors.blue)),
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
                          labelText: 'First Name',
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
                            return 'First Name is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: InputDecoration(
                          labelText: 'Last Name',
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
                        autofillHints: [AutofillHints.familyName],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Last Name is required';
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
                          labelText: 'Email',
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
                            return 'Email is required';
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
                      child: TextFormField(
                        controller: _dateController,
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          labelStyle: TextStyle(fontSize: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
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
                            return 'Please enter the company phone number';
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
                        controller: _nifController,
                        decoration: InputDecoration(
                          labelText: 'NIF',
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
                            return 'NIF is required';
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
                          width: 240,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCompany,
                            hint: Text('Select Company'),
                            onChanged: _onCompanyChange,
                            items: _companies.map((Company company) {
                              return DropdownMenuItem<String>(
                                value: company.id,
                                child: Text(company.name),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a company';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 20),
                        SizedBox(
                          width: 240,
                          child: DropdownButtonFormField<String>(
                            value: _selectedProfileAccess,
                            hint: Text('Select Profile Access'),
                            onChanged: (value) {
                              _onProfileAccessChange(value);
                            },
                            items: _profileAccessPermissions
                                .map((ProfileAccess profile) {
                              return DropdownMenuItem<String>(
                                value: profile.permission,
                                child: Text(profile.name),
                              );
                            }).toList(),
                            decoration: InputDecoration(
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            validator: (value) {
                              if (value == null) {
                                return 'Please select a profile access';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (pwdVisible) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 240,
                            child: TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(fontSize: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    pwdVisiblee
                                        ? Icons.visibility
                                        : Icons.visibility_off,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      pwdVisiblee = !pwdVisiblee;
                                    });
                                  },
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                  horizontal: 15,
                                ),
                              ),
                              style: TextStyle(fontSize: 20),
                              obscureText: !pwdVisiblee,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Password is required';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 240,
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
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
                              obscureText: !pwdVisiblee,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
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
                        items: CountryList.countries.map((Country country) {
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
                        onChanged: (value) async {
                          if (value != null) {
                            setState(() {
                              _selectedCountryCode = value;
                            });
                          }
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
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState?.validate() ?? false) {
                            sendUserData();
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
