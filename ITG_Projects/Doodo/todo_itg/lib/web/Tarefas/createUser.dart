import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class CreateUser extends StatefulWidget {
  @override
  _CreateUser createState() => _CreateUser();
}

class _CreateUser extends State<CreateUser> {
  TextEditingController _nomeController = TextEditingController();
  TextEditingController _logController = TextEditingController();
  TextEditingController _mailController = TextEditingController();
  TextEditingController _contController = TextEditingController();
  TextEditingController _sobNController = TextEditingController();
  TextEditingController _passController = TextEditingController();
  TextEditingController _confPassController = TextEditingController();
  dynamic type;

  bool _isPasswordVisible = false;
  List<String> order = <String>['User', 'Admin'];
  dynamic orderv = 'User';
  dynamic numberint;

  CreateUser(String name, String pwd, String log, String cont, String mail,
      String type) async {
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=15&name=$name&pwd=$pwd&log=$log&cont=$cont&mail=$mail&type=$type'));
    if (response.statusCode == 200) {
      setState(() {
        //Users = jsonDecode(response.body) as List;
      });
    }
  }

  String initialCountry = 'PT';
  PhoneNumber number = PhoneNumber(isoCode: 'PT');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Criar User'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Card(
                    elevation: 3,
                    child: Container(
                      color: Colors.white,
                      width: 550,
                      height: 500,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 220,
                                height: 75,
                                child: TextField(
                                  controller: _nomeController,
                                  decoration: const InputDecoration(
                                    labelText: 'Coloque um Primeiro Nome ',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              SizedBox(
                                width: 220,
                                height: 75,
                                child: TextField(
                                  controller: _sobNController,
                                  decoration: const InputDecoration(
                                    labelText: 'Coloque um Sobrenome',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 220,
                                height: 75,
                                child: TextField(
                                  controller: _logController,
                                  decoration: const InputDecoration(
                                    labelText: 'Coloque um Login',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              SizedBox(
                                width: 220,
                                height: 75,
                                child: TextField(
                                  controller: _mailController,
                                  keyboardType: TextInputType.multiline,
                                  decoration: const InputDecoration(
                                    labelText: 'Coloque o Email',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          InternationalPhoneNumberInput(
                            onInputChanged: (PhoneNumber number) {
                              numberint = number.phoneNumber;
                            },
                            onInputValidated: (bool value) {},
                            selectorConfig: SelectorConfig(
                              selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                              showFlags: true,
                            ),
                            ignoreBlank: false,
                            autoValidateMode: AutovalidateMode.disabled,
                            selectorTextStyle: TextStyle(color: Colors.black),
                            initialValue: number,
                            textFieldController: _contController,
                            formatInput: false,
                            keyboardType: TextInputType.numberWithOptions(
                                signed: true, decimal: true),
                            inputBorder: OutlineInputBorder(),
                            onSaved: (PhoneNumber number) {
                              print(number);
                            },
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 220,
                                height: 75,
                                child: TextField(
                                  controller: _passController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Password',
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                      icon: Icon(
                                        _isPasswordVisible
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                    ),
                                  ),
                                  obscureText: !_isPasswordVisible,
                                ),
                              ),
                              SizedBox(
                                width: 8,
                              ),
                              SizedBox(
                                width: 220,
                                height: 75,
                                child: TextField(
                                  controller: _confPassController,
                                  decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Repita a Password',
                                    suffixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _isPasswordVisible =
                                              !_isPasswordVisible;
                                        });
                                      },
                                      icon: Icon(
                                          _isPasswordVisible ? null : null),
                                    ),
                                  ),
                                  obscureText: !_isPasswordVisible,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          DropdownButton<String>(
                            value: orderv,
                            hint: Text(orderv),
                            icon: const Icon(Icons.expand_more),
                            elevation: 16,
                            style: const TextStyle(color: Colors.black),
                            underline: Container(
                              height: 2,
                              color: Colors.blue,
                            ),
                            items: order
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                            onChanged: (value) {
                              // This is called when the user selects an item.
                              setState(() {
                                orderv = value.toString();
                              });
                            },
                          ),
                          SizedBox(
                            height: 8,
                          ),
                          const SizedBox(height: 16.0),
                          ElevatedButton(
                            onPressed: () {
                              _emptyFields();
                            },
                            child: const Text('Criar User'),
                          ),
                        ],
                      ),
                    )),
              ],
            ),
          ),
        ));
  }

  void _emptyFields() async {
    final nome = _nomeController.text;
    final log = _logController.text;

    final email = _mailController.text;
    final cont = _contController.text;
    final pass = _passController.text;
    final Conf_Pass = _confPassController.text;

    if (nome.isEmpty ||
        log.isEmpty ||
        email.isEmpty ||
        cont.isEmpty ||
        pass.isEmpty ||
        Conf_Pass.isEmpty) {
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
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
      print(name);
      print(_passController.text);
      print(_logController.text);
      print(numberint);
      print(_mailController.text);
      print(type);

      CreateUser(name, _passController.text, _logController.text, numberint,
          _mailController.text, type);

      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
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
