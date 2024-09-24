import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_number_input_v2/intl_phone_number_input.dart';
import 'package:sado/Paginas/Principais/Admin/Company/collaboratorsCompany.dart';
import 'package:sado/Paginas/Principais/Admin/dashboardPage.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateCompanyForm extends StatefulWidget {
  @override
  CreateCompanyForm({
    super.key,
  });

  @override
  _CreateCompanyFormState createState() => _CreateCompanyFormState();
}

class _CreateCompanyFormState extends State<CreateCompanyForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nifController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contController = TextEditingController();

  dynamic numberint;
  dynamic selectedColor = Colors.blue;
  bool isHovered = false;

  @override
  void initState() {
    super.initState();
  }

  void sendEmpresaData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = _nameController.text.trim().toString();
    var address = _addressController.text.trim().toString();
    var contact = _contController.text.trim().toString();
    var nif = _nifController.text.trim().toString();
    var email = _mailController.text.trim().toString();
    var idUser = prefs.getString("idUser");
    final color = selectedColor.toString().substring(10, 16);
    print(idUser);
    print(selectedColor);
    if (color[0].toString() == 'l') {
      _showDialog(
          context, "Change Colour", "Select a different colour Please!", 0);
    } else {
      try {
        final response = await http.post(
          Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
          body: {
            'query_param': 'C2',
            'name': name,
            'address': address,
            'nif': nif,
            'phone': contact,
            'email': email,
            'id': idUser,
            'colour': color,
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
                    Navigator.of(context).pop();
                    /*Navigator.push(
                      context,
                      SlideTransitionPageRoute(
                      //page: AdminDrawer(currentPage: Company(idCompany: widget.idCompany), numero: 2),
                      ),
                    );*/
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

  String initialCountry = 'PT';
  PhoneNumber number = PhoneNumber(isoCode: 'PT');

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero, // Remove default padding around the dialog
      child: AlertDialog(
        backgroundColor: Colors.white.withOpacity(0.9),
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("Add Company"),
          Container(
            color: Colors.black,
            width: 550,
            height: 1,
          ),
        ]),
        content: Form(
          key: _formKey,
          child: SizedBox(
            width: 550,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      border: OutlineInputBorder(),
                    ),
                    autofillHints: [AutofillHints.name], // Autofill for Name
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Company Name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _mailController,
                    decoration: const InputDecoration(
                      labelText: 'Company Mail',
                      border: OutlineInputBorder(),
                    ),
                    autofillHints: [AutofillHints.email], // Autofill for Name
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Company Mail is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Company Address',
                      border: OutlineInputBorder(),
                    ),
                    autofillHints: [
                      AutofillHints.addressCityAndState
                    ], // Autofill for Name
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Company Address is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nifController,
                    decoration: const InputDecoration(
                      labelText: 'Company NIF',
                      border: OutlineInputBorder(),
                    ),
                    autofillHints: [AutofillHints.nif], // Autofill for Name
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Company NIF is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  InternationalPhoneNumberInput(
                        onInputChanged: (phoneNumber) {
                          setState(() {
                            number = phoneNumber;
                    
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
                        textFieldController: _contController,
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
                            _contController.text = number.dialCode.toString() +
                                " " +
                                _contController.text;
                          }
                          return null;
                        },
                        onSaved: (phoneNumber) {},
                      ),
                    
                  const SizedBox(height: 10),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          const Text(
                            'Selected Color:',
                            style: TextStyle(fontSize: 18),
                          ),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.only(
                                top: (isHovered) ? 5 : 16.0,
                                bottom: !(isHovered) ? 5 : 16),
                            child: InkWell(
                              onTap: () {
                                _showColorPickerDialog();
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: selectedColor,
                                  borderRadius: BorderRadius.circular(25),
                                ),
                              ),
                              onHover: (val) {
                                setState(() {
                                  isHovered = val;
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            child: const Text('Cancelar'),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                sendEmpresaData();
              }
            },
            child: const Text("Confirmar"),
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
