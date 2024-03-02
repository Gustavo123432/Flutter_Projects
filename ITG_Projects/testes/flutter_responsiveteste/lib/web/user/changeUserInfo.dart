// ignore_for_file: non_constant_identifier_names, file_names, library_private_types_in_public_api, camel_case_types
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_responsiveteste/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:http/http.dart' as http;

String errorMessage = '';

class changeUserInfo extends StatefulWidget {
  const changeUserInfo({super.key});

  @override
  _changeUserInfoState createState() => _changeUserInfoState();
}

class _changeUserInfoState extends State<changeUserInfo> {
  dynamic User;
  var NomeController = TextEditingController();
  TextEditingController ContactoController = TextEditingController();
  TextEditingController PassController = TextEditingController();
  TextEditingController Conf_PassController = TextEditingController();
  bool _isPasswordVisible = false;

  getUserInfo() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=9&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        User = jsonDecode(response.body);
        NomeController.text = User[0]['Name'];
        ContactoController.text = User[0]['Cont'];
        PassController.text = User[0]['pwd'];
        Conf_PassController.text = User[0]['pwd'];
      });
      return User;
    }
  }

  setUserInfo(String Nome, String Cont, String Pwd) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=6&Name=$Nome&Cont=$Cont&Pwd=$Pwd&id=$id'));
    if (response.statusCode == 200) {
      setState(() {});
    }
  }

  @override
  void initState() {
    getUserInfo();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Change User Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Card(
                elevation: 3,
                child: Container(
                  color: Colors.white,
                  width: 350,
                  height: 500,
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.blue,
                        
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            TextField(
                              controller: NomeController,
                              decoration:
                                  const InputDecoration(labelText: 'Nome'),
                              obscureText: false,
                            ),
                            TextField(
                              controller: ContactoController,
                              decoration:
                                  const InputDecoration(labelText: 'Contacto'),
                              obscureText: false,
                              //keyboardType: TextInputType.number,
                              //inputFormatters: <TextInputFormatter>[
                              //FilteringTextInputFormatter.digitsOnly
                              //],
                            ),
                            TextField(
                              controller: PassController,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
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
                            TextField(
                              controller: Conf_PassController,
                              decoration: InputDecoration(
                                labelText: 'Repita a Password',
                                suffixIcon: IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                  icon: Icon(_isPasswordVisible ? null : null),
                                ),
                              ),
                              obscureText: !_isPasswordVisible,
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                //Criar Função onde confirmar se o nome/contacto/2xPass está direto
                                //Adicionar AlertDiolog para o User confirmar
                                _emptyFields();
                              },
                              child: const Text('Confirmar'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _emptyFields() async {
    final nome = NomeController.text;
    final contacto = ContactoController.text;
    final pass = PassController.text;
    final Conf_Pass = Conf_PassController.text;

    if (nome.isEmpty || contacto.isEmpty || pass.isEmpty) {
      errorMessage = 'Preencha todos os campos';
      //print(errorMessage);
    } else if (pass != Conf_Pass) {
      errorMessage = 'As palavras passes não são iguais';
      //print(errorMessage);
    } else {
      setUserInfo(nome, contacto, pass);
      Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => const LoginForm(),
      ));
    }
  }
}
