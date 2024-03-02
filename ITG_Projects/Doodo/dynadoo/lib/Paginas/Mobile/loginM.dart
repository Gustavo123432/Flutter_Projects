// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, annotate_overrides
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Componentes/login/AuthUtils.dart';




String errorMessage = '';

class LoginFormM extends StatefulWidget {
  const LoginFormM({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginFormMState createState() => _LoginFormMState();
}

class _LoginFormMState extends State<LoginFormM> {
  final TextEditingController NameController = TextEditingController();
  final TextEditingController PwdController = TextEditingController();

void login(BuildContext context) async {
  final name = NameController.text;
  final pwd = PwdController.text;
  final loginType = 'default'; // Defina um valor padrão para loginType se necessário
  await AuthUtils.login(context, name, pwd, loginType);
}


  double opacityLevel = 1.0;
  /////////////////////////////////////////
  /////////////////////////////////////////
  /////////////////////////////////////////
 @override
  void initState() {
    super.initState();
    AuthUtils.verifyLogin(context);
  }
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Hero(
              tag: 'Logo',
              child: Image.asset(
                'assets/images/logoDoodo.jpg',
                width: 350,
              ),
            ),
          ),
          SizedBox(
            width: 350,
            child: TextField(
              controller: NameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
          ),
          SizedBox(
            width: 350,
            child: TextField(
              controller: PwdController,
              decoration: const InputDecoration(labelText: 'Palavra Passe'),
              obscureText: true,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              login(context);
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

}