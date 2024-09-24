import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sado/Paginas/Login/forgotPasswordSecond.dart';
import 'package:sado/Paginas/Login/signUpThird.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:sado/Paginas/Login/login.dart'; // Ensure this import is correct

class SignUpCodeSecondForm extends StatefulWidget {
  final String opcao;

  const SignUpCodeSecondForm({
    super.key,
    required this.opcao,
  });

  @override
  _SignUpCodeSecondFormState createState() => _SignUpCodeSecondFormState();
}

class _SignUpCodeSecondFormState extends State<SignUpCodeSecondForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController CodeController = TextEditingController();
  final TextEditingController EmailController = TextEditingController();
  final TextEditingController EmailInputController = TextEditingController();

  void checkCode() async {
    var code = CodeController.text;

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'U3',
          'cod': code,
        },
      );

      if (response.statusCode == 200) {
        dynamic tar = json.decode(response.body);
        /* print(tar);
        print(tar["iduser"]);*/
        if (tar["iduser"] != 'false') {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('idUserCode', tar['coduser'].toString());
          _showDialog('Code Success', 'Sucess', 1, 0);
        } else {
          _showDialog('Code Failed', 'Invalid Code.', 0, 0);
        }
      } else {
        _showDialog('Error', 'Failed to connect to the server.', 0, 0);
      }
    } catch (e) {
      _showDialog('Code Failed', 'Invalid code.', 0, 0);
    }
  }

  void signInResendEmail(var email) async {
    if (!EmailValidator.validate(email!)) {
      _showDialog('Invalid Email', 'Please enter a valid email address.', 0, 0);
      return;
    } else {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      try {
        if (widget.opcao == '0') {
          final response = await http.post(
            Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
            body: {
              'query_param': 'U2',
              'email': email,
              'op': '1',
            },
          );
          if (response.statusCode == 200) {
            _showDialog(
                "Email Resend",
                "We have just sent a Sign In confirmation email.\nCheck SPAM!",
                0,
                0);
          } else {
            _showDialog('Error', 'Failed to connect to the server.', 0, 0);
          }
        } else if (widget.opcao == '1') {
          final response = await http.post(
            Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
            body: {
              'query_param': 'U6',
              'email': email,
              'op': '1',
            },
          );
          if (response.statusCode == 200) {
            _showDialog(
                "Email Resend",
                "We have just sent a password recovery code to your email. \nCheck SPAM!",
                1,
                1);
          } else {
            _showDialog('Error', 'Failed to connect to the server.', 0, 0);
          }
        }
      } catch (e) {
        _showDialog('Error',
            'An unexpected error occurred. Please try again later.', 0, 0);
      }
    }
  }

  void _showDialog(String title, String message, int value, int teste) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  message,
                ),
              ),
              if (value == 3) SizedBox(height: 10),
              if (value == 3)
                TextField(
                  controller: EmailInputController,
                  decoration: InputDecoration(
                    labelText: 'Enter Email',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          backgroundColor: Colors.white,
          actions: <Widget>[
            if (value == 3) ...[
              TextButton(
                child: Text('Try Again', style: TextStyle(color: Colors.red)),
                onPressed: () {
                  Navigator.of(context).pop();
                  EmailInputController.clear();
                },
              ),
              TextButton(
                child: Text('Submit', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  String userInput = EmailInputController.text;
                  signInResendEmail(userInput);
                  Navigator.of(context).pop();
                },
              ),
            ] else if (teste == 1 && value == 1) ...[
              // Specific case where only pop is needed
              TextButton(
                child: Text('OK', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  Navigator.of(context).pop(); // Only close the dialog
                  //Navigator.of(context).pop(); // Pop twice as per original logic
                },
              ),
            ] else ...[
              TextButton(
                child: Text('OK', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog first

                  // Handle navigation based on opcao and value
                  if (value == 1) {
                    if (widget.opcao == '0') {
                      Navigator.push(
                        context,
                        SlideTransitionPageRoute(
                          page: const SignUpThirdForm(),
                        ),
                      );
                    } else if (widget.opcao == '1') {
                      Navigator.push(
                        context,
                        SlideTransitionPageRoute(
                          page: const ForgotPasswordSecondForm(),
                        ),
                      );
                    }
                  }
                },
              ),
            ],
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
      body: Form(
        key: _formKey, // Attach the form key to the form
        child: Flex(
          direction: Axis.horizontal,
          children: [
            // Left side (7/11 of the screen) - Form
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      "Enter Code",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 60,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    /*SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: EmailController,
                        decoration: InputDecoration(
                          labelText: 'Email Confirmation',
                          labelStyle: const TextStyle(fontSize: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                        style: const TextStyle(fontSize: 20),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Email Confirmation is required';
                          }
                          if (!EmailValidator.validate(value)) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),*/
                    SizedBox(
                      width: 500,
                      child: TextFormField(
                        controller: CodeController,
                        decoration: InputDecoration(
                          labelText: 'Insert Code',
                          labelStyle: const TextStyle(fontSize: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 15,
                            horizontal: 15,
                          ),
                        ),
                        style: const TextStyle(fontSize: 20),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Code is required';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        _showDialog("Enter Email", "Enter Email ", 3, 0);
                      },
                      child: const Text(
                        "You didn't receive the code, Click here!",
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          checkCode();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                        side: const BorderSide(
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
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Background Header Design
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(80),
                    bottomRight: Radius.circular(80),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.only(left: 25, right: 25, top: 40),
                  child: Image.asset(
                    'lib/assets/Sado.png',
                    height: 10,
                  ),
                ),
              ),
              SizedBox(height: 40),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 500,
                        child: TextFormField(
                          controller: CodeController,
                          decoration: InputDecoration(
                            labelText: 'Insert Code',
                            labelStyle: const TextStyle(fontSize: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                              horizontal: 15,
                            ),
                          ),
                          style: const TextStyle(fontSize: 20),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Code is required';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        onTap: () {
                          _showDialog("Enter Email", "Enter Email ", 3, 0);
                        },
                        child: const Text(
                          "You didn't receive the code, Click here!",
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            checkCode();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          minimumSize: const Size(200, 50),
                          side: const BorderSide(
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
      ),
    );
  }
}
