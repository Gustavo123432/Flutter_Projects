// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, annotate_overrides
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Componentes/login/AuthUtils.dart';




String errorMessage = '';

class LoginFormD extends StatefulWidget {
  const LoginFormD({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _LoginFormDState createState() => _LoginFormDState();
}

class _LoginFormDState extends State<LoginFormD> {
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
      backgroundColor: Colors.white, // Background color
      body: Center(
        child: Container(
          width: 570,
          height: 520,
          padding: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.5),
                spreadRadius: 5,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logoDoodo.jpg',
                width: 350,
                height: 150,
              ),
              SizedBox(
                width: 350,
                child: TextField(
                  controller: NameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person), // User icon
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 350,
                child: TextField(
                  controller: PwdController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock), // Lock icon
                  ),
                  obscureText: true,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  login(context);
                },
                style: ElevatedButton.styleFrom(
                  // ignore: deprecated_member_use
                  backgroundColor: Colors.blue, // Button color
                  minimumSize: const Size(350, 50), // Button size
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    color: Colors.white, // Text color
                    fontSize: 18, // Text size
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