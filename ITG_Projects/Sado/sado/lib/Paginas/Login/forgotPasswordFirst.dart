import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sado/Paginas/Login/signUpCodeSecond.dart';
import 'package:sado/Paginas/Login/signUpFirst.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:sado/Paginas/Login/login.dart'; // Ensure this import is correct

class ForgotPasswordForm extends StatefulWidget {
  const ForgotPasswordForm({super.key});

  @override
  _ForgotPasswordFormState createState() => _ForgotPasswordFormState();
}

class _ForgotPasswordFormState extends State<ForgotPasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController EmailController = TextEditingController();

  void forgotPasswordSendEmail() async {
    var email = EmailController.text.trim().toString();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('email', email);
    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'U6',
          'email': email,
          'op': '0',
        },
      );

      if (response.statusCode == 200) {
        final tar = json.decode(response.body);

        if (tar == 0) {
          _showDialog(
              context,
              "Email doesn't Exist",
              'The email you entered was not found, please try again or sign up.',
              2);
        } else {
          _showDialog(context, "Email Send",
              "We have just sent a Password Recovery email.\nCheck SPAM!", 1);
        }
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
                    Navigator.push(
                      context,
                      SlideTransitionPageRoute(
                        page: SignUpCodeSecondForm(
                          opcao: '1',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          );
        },
      );
    } else if (value == 2) {
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
                child: Text('Try Again', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop();
                  EmailController.clear();
                },
              ),
              TextButton(
                child: Text('Sign Up', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  Navigator.push(
                    context,
                    SlideTransitionPageRoute(
                      page: SignUpFirstForm(),
                    ),
                  );
                },
              ),
            ],
          );
        },
      );
    }
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
      body: Form(
        key: _formKey,
        child: Flex(
          direction: Axis.horizontal,
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Forgot Password",
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
                        controller: EmailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle: TextStyle(fontSize: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          prefixIcon: Icon(Icons.email_outlined, size: 24),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                        style: TextStyle(fontSize: 20),
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
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          forgotPasswordSendEmail();
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
                        'Enter',
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
          ],
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
            child: TextFormField(
              controller: EmailController,
              decoration: const InputDecoration(labelText: 'Email'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                /*if (!EmailValidator.validate(value)) {
                                return 'Please enter a valid email address';
                              }*/
                return null;
              },
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
