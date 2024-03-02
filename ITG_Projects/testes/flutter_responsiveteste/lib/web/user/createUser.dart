// ignore_for_file: file_names, non_constant_identifier_names, library_private_types_in_public_api, prefer_interpolation_to_compose_strings, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_responsiveteste/web/web.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';


class CreateUser extends StatefulWidget {
  const CreateUser({super.key});

  @override
  _CreateUser createState() => _CreateUser();
}

class _CreateUser extends State<CreateUser> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _logController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _contController = TextEditingController();
  final TextEditingController _sobNController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confPassController = TextEditingController();

  dynamic type;

  final bool _isPasswordVisible = false;
  List<String> order = <String>['User', 'Admin'];
  dynamic orderv = 'User';
  dynamic numberint;
  dynamic selectedColor = Colors.blue;
  dynamic _selectedImage;
  dynamic idd;
  bool isHovered = false;

  FCreateUser(String name, String pwd, String log, String cont, String mail,
      String type, String color) async {
    _selectedImage = base64.encode(_selectedImage);
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=5&name=$name&pwd=$pwd&log=$log&cont=$cont&mail=$mail&type=$type&color=$color'));
    if (response.statusCode == 200) {
      setState(() {
        idd = json.decode(response.body);
      });
      //print(idd);
      idd = idd[0]['iduser'];
      //print(_selectedImage);
      _uploadImage(int.parse(idd.toString()));
    }

    //print(_selectedImage);
    //print(id);
    return idd;
  }

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    dynamic imagefile = await pickedFile!.readAsBytes();

    setState(() {
      _selectedImage = imagefile;
    });
  }

  Future<void> _uploadImage(
    int id,
  ) async {
    if (_selectedImage != null) {
      try {
        final response = await http.post(
          Uri.parse('https://services.interagit.com/API/api_Calendar_Post.php'),
          body: {
            'query_param': '10',
            'image': _selectedImage.toString(),
            'id': id.toString(),
          },
        );
        //print(response.body.toString());

        if (response.statusCode == 200) {
          // Image uploaded successfully
          //print('Image uploaded successfully');
        } else {
          // Handle error
          //print('Error uploading image: ${response.statusCode}');
        }
      } catch (e) {
        // Handle error
        //print('Error uploading image: $e');
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create User'),
      ),
      body: Center(
        child: Container(
          width: 650,
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                      onTap: _getImage,
                      child: CircleAvatar(
                          radius: 50.0,
                          child: ClipOval(
                            child: (_selectedImage != null)
                                ? Image.memory(_selectedImage)
                                : Icon(
                                    Icons.person,
                                    size: 47,
                                    color: selectedColor,
                                  ),
                          ))),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'First Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _sobNController,
                    decoration: const InputDecoration(
                      labelText: 'Last Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _logController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _mailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  InternationalPhoneNumberInput(
                    onInputChanged: (PhoneNumber number) {
                      numberint = number.phoneNumber;
                    },
                    onInputValidated: (bool value) {},
                    selectorConfig: const SelectorConfig(
                      selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                      showFlags: true,
                    ),
                    ignoreBlank: false,
                    autoValidateMode: AutovalidateMode.disabled,
                    selectorTextStyle: const TextStyle(color: Colors.black),
                    initialValue: number,
                    textFieldController: _contController,
                    formatInput: false,
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: true,
                    ),
                    inputBorder: const OutlineInputBorder(),
                    onSaved: (PhoneNumber number) {
                      //print(number);
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _passController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: !_isPasswordVisible,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _confPassController,
                          decoration: const InputDecoration(
                            labelText: 'Repeat Password',
                            border: OutlineInputBorder(),
                          ),
                          obscureText: !_isPasswordVisible,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: orderv,
                        hint: const Text('Select an Option'),
                        elevation: 14,
                        style: const TextStyle(color: Colors.black),
                        underline: Container(
                          height: 2,
                          color: Colors.blue,
                        ),
                        items:
                            order.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            orderv = value.toString();
                          });
                        },
                        icon: const Icon(Icons.expand_more),
                      ),
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
                  ElevatedButton(
                    onPressed: () {
                      _emptyFields();
                    },
                    child: const Text('Create User'),
                  ),
                ],
              ),
            ),
          ),
        ),
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

  void _emptyFields() async {
    final nome = _nomeController.text;
    final log = _logController.text;

    final email = _mailController.text;
    final cont = _contController.text;
    final pass = _passController.text;
    final Conf_Pass = _confPassController.text;
    final color = selectedColor.toString().substring(10, 16);
    //print(color);

    if (nome.isEmpty ||
        log.isEmpty ||
        email.isEmpty ||
        cont.isEmpty ||
        pass.isEmpty ||
        Conf_Pass.isEmpty ||
        color.isEmpty) {
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text(
          'Preencha todos os campos',
          style: TextStyle(
            fontSize: 16, // Customize font size
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
        backgroundColor: Colors.red, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (Conf_Pass != pass) {
    } else {
      if (orderv == "User") {
        type = "0";
      } else {
        type = "1";
      }
      String name = nome + ' ' + _sobNController.text;
      //print(name);
      //print(_passController.text);
      //print(_logController.text);
      //print(numberint);
      //print(_mailController.text);
      //print(type);
      //print(color);

      FCreateUser(name, _passController.text, _logController.text, numberint,
          _mailController.text, type, color);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WebPage(title: 'Calendário'),
          ));
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text(
          'User criado',
          style: TextStyle(
            fontSize: 16, // Customize font size
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
        backgroundColor: Colors.green, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }
}
