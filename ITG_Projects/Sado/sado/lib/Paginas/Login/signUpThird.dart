import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sado/Paginas/Registo/userRegister.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:sado/Paginas/Login/login.dart'; // Ensure this import is correct

class SignUpThirdForm extends StatefulWidget {
  const SignUpThirdForm({super.key});

  @override
  _SignUpThirdFormState createState() => _SignUpThirdFormState();
}

class _SignUpThirdFormState extends State<SignUpThirdForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController NameController = TextEditingController();
  final TextEditingController AddressController = TextEditingController();
  final TextEditingController ContactController = TextEditingController();
  final TextEditingController NIFController = TextEditingController();
  final TextEditingController PasswordController = TextEditingController();

  void signInDataPassword() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = PasswordController.text.trim().toString();
    var idUser = prefs.getString("idUserCode");
    await prefs.setString('idUser', idUser.toString());

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'U4',
          'pwd': name,
          'id': idUser,
        },
      );

      if (response.statusCode == 200) {
        print("Password Update");
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
      _showDialog(
          context, 'Invalid Email', 'Please enter a valid email address.', 0);
      return;
    } else {
      try {
        final response = await http.post(
          Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
          body: {
            'query_param': 'U2',
            'email': email,
            'op': '2',
          },
        );

        if (response.statusCode == 200) {
          print("Welcome, Email Send");
          print(response.body);
          print(email);
        } else {}
      } catch (e) {}
    }
  }

  void signInData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var name = NameController.text.trim().toString();
    var address = AddressController.text.trim().toString();
    var contact = ContactController.text.trim().toString();
    var nif = NIFController.text.trim().toString();
    var idUser = prefs.getString("idUserCode");
    await prefs.setString('idUser', idUser.toString());

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'U4',
          'name': name,
          'address': address,
          'nif': nif,
          'cont': contact,
          'iduser': idUser,
        },
      );

      if (response.statusCode == 200) {
        _showDialog(context, "Sign In Successfully",
            "Registration was successful.\nWelcome!", 1);
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
                        page: UserRegisterForm(),
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
                      "Enter Password",
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
                          signInData();
                          sendEmail();
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
                  padding: const EdgeInsets.only(left:25, right: 25, top: 40),
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
                      const Text(
                      "Enter Password",
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 25,
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
                      
                      SizedBox(height: 20),
                      // Sign In Button
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.blue,
                        child: IconButton(
                          icon: Icon(Icons.arrow_forward),
                          color: Colors.white,
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              signInDataPassword();
                          signInData();
                          sendEmail();
                            }
                          },
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
