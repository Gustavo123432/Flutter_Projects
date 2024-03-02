// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, annotate_overrides
import 'dart:async';
import 'dart:convert';
import 'Componentes/Login/auth_service.dart';
import 'mobile/secondScreen.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';


String errorMessage = '';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  // ignore: library_private_types_in_public_api

  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController NameController = TextEditingController();
  final TextEditingController PwdController = TextEditingController();

  void login() {
    final name = NameController.text;
    final pwd = PwdController.text;
    AuthService.login(context, name, pwd); // Passa o context aqui
  }

  double opacityLevel = 1.0;
  /////////////////////////////////////////
  /////////////////////////////////////////
  /////////////////////////////////////////

 @override
Widget build(BuildContext context) {
     AuthService.verifylogin(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const webScreenSize = 600;
        if (constraints.maxWidth > webScreenSize) {
          //webscreen
          return webScreenLayout(); // <-- send user Web screen
        } else {
          //mobile screen
          return mobileScreenLayout(); // <-- send user mobile screen
        }
      },
    );
  }

  Widget webScreenLayout() {
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
                'images/logoDoodo.jpg',
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
                  login();
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

  Widget mobileScreenLayout() {
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
                'images/logoDoodo.jpg',
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
              login();
            },
            child: const Text('Login'),
          ),
        ],
      ),
    );
  }

}

