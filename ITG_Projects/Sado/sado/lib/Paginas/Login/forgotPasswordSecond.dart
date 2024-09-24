import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:sado/Paginas/Login/login.dart'; // Ensure this import is correct

class ForgotPasswordSecondForm extends StatefulWidget {
  const ForgotPasswordSecondForm({super.key});

  @override
  _ForgotPasswordSecondFormState createState() =>
      _ForgotPasswordSecondFormState();
}

class _ForgotPasswordSecondFormState extends State<ForgotPasswordSecondForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController PasswordController = TextEditingController();

  void signInDataPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var pwd = PasswordController.text.trim().toString();
    var idUser = prefs.getString("idUserCode");

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'U5',
          'pwd': pwd,
          'id': idUser,
        },
      );

      if (response.statusCode == 200) {
        print("Password Update");
        sendEmail();
      }
    } catch (e) {
      /* _showDialog(
          'Error', 'An unexpected error occurred. Please try again later.', 0);*/
    }
  }

  void sendEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    var email = prefs.getString("email");

    if (!EmailValidator.validate(email!)) {
      _showDialog('Invalid Email', 'Please enter a valid email address.', 0);
      return;
    } else {
      try {
        final response = await http.post(
          Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
          body: {
            'query_param': 'U6',
            'email': email,
            'op': '2',
          },
        );
        if (response.statusCode == 200) {
          _showDialog(
              "Password Change", "Password was changed successfully", 1);
        } else {}
      } catch (e) {}
    }
  }

  void _showDialog(String title, String message, int value) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
                if (value == 1) {
                  Navigator.push(
                    context,
                    SlideTransitionPageRoute(
                      page:
                          const LoginForm(), // Use LoginForm or the intended page
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

  @override
  Widget build(BuildContext context) {
    verifylogin(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        const webScreenSize = 600;
        if (constraints.maxWidth > webScreenSize) {
          return webScreenLayout();
        } else {
          return mobileScreenLayout();
        }
      },
    );
  }

  Widget webScreenLayout() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Flex(
        direction: Axis.horizontal,
        children: [
          // Left side (7/11 of the screen) - Form
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Change Password",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: PasswordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: TextStyle(fontSize: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                        style: TextStyle(fontSize: 20),
                        autofillHints: [
                          AutofillHints.telephoneNumber
                        ], // Autofill for Contact
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Password Confirmation',
                          labelStyle: TextStyle(fontSize: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                        style: TextStyle(fontSize: 20),
                        autofillHints: [
                          AutofillHints.telephoneNumber
                        ], // Autofill for Contact
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password Confirmation is required';
                          } else if (value != PasswordController.text) {
                            return "Password don't match";
                          }
                          return null;
                        },
                        obscureText: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          signInDataPassword();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: Size(200, 50),
                        side: BorderSide(
                          color: Color.fromARGB(150, 84, 155, 231),
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              tag: 'blue-container',
              child: Container(
                color: Colors.blue,
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  'lib/assets/logo.png',
                  width: 200,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 350,
            child: TextField(
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              // Handle Sign Up
            },
            child: const Text('Sign Up'),
          ),
        ],
      ),
    );
  }
}
