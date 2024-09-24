import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:sado/Paginas/Login/signUpCodeSecond.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:email_validator/email_validator.dart';
import 'package:sado/Paginas/Login/login.dart'; // Ensure this import is correct

class SignUpFirstForm extends StatefulWidget {
  const SignUpFirstForm({super.key});

  @override
  _SignUpFirstFormState createState() => _SignUpFirstFormState();
}

class _SignUpFirstFormState extends State<SignUpFirstForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController EmailController = TextEditingController();
  bool _isLoading = false; // Loading state

  void signInSendEmail() async {
    var email = EmailController.text.trim().toString();
    setState(() {
      _isLoading = true; // Show the progress indicator
    });

    try {
      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'U2',
          'email': email,
          'op': '0',
        },
      );
      if (response.statusCode == 200) {
        final tar = json.decode(response.body);

        if (tar == 0) {
          _showDialog(
              context,
              'Email Already Exists',
              'The email you entered is already registered, login or try another one.',
              2);
        } else {
          _showDialog(
              context,
              "Email Send",
              "We have just sent a Sign In confirmation email.\nCheck SPAM!",
              1);
        }
      } else {
        _showDialog(context, 'Error', 'Failed to connect to the server.', 0);
      }
    } catch (e) {
      _showDialog(context, 'Error',
          'An unexpected error occurred. Please try again later.', 0);
    } finally {
      setState(() {
        _isLoading = false; // Hide the progress indicator
      });
    }
  }

  void _showDialog(
      BuildContext context, String title, String message, int value) {
    if (value != 2) {
      showDialog(
        context: context,
        barrierDismissible:
            true, // Allows the dialog to be dismissed by tapping outside
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
                  Navigator.of(context)
                      .pop(true); // Return true when OK is pressed
                },
              ),
            ],
          );
        },
      ).then((dismissed) {
        if (dismissed == null || dismissed == true) {
          // dismissed == null means the dialog was closed by tapping outside
          // dismissed == true means the dialog was closed by pressing OK
          if (value == 1) {
            Navigator.push(
              context,
              SlideTransitionPageRoute(
                page: SignUpCodeSecondForm(
                  opcao: '0',
                ),
              ),
            );
          }
        }
      });
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
                child: Text('Login', style: TextStyle(color: Colors.blue)),
                onPressed: () {
                  Navigator.push(
                    context,
                    SlideTransitionPageRoute(
                      page: LoginForm(),
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
      body: Stack(
        children: [
          Form(
            key: _formKey,
            child: Flex(
              direction: Axis.horizontal,
              children: [
                // Left side (7/11 of the screen) - Form
                Expanded(
                  flex: 7,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Sign Up",
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
                              setState(() {
                                _isLoading = true; // Show progress indicator
                              });

                              // Delay execution to ensure progress indicator is shown
                              Future.delayed(Duration(milliseconds: 100), () {
                                signInSendEmail();
                              });
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
                            'Sign Up',
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
                // Right side (4/11 of the screen) - Blue background
                Expanded(
                  flex: 5,
                  child: Hero(
                    tag: 'blue-container',
                    child: Container(
                      color: Colors.blue,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Image.asset(
                            'lib/assets/Sado.png',
                            height: 120,
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Welcome!",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "You are where you find the best you are looking for!",
                            style: TextStyle(
                              color: Color.fromARGB(255, 200, 238, 255),
                              fontSize: 30,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            "Already have an Account?",
                            style: TextStyle(
                              color: Color.fromARGB(255, 200, 238, 255),
                              fontSize: 25,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                CustomHeroPageRoute(
                                  page:
                                      const LoginForm(), // Use LoginForm or the intended page
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  Color.fromARGB(150, 84, 155, 231),
                              minimumSize: Size(250, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: const Text(
                              'Login',
                              style: TextStyle(
                                color: Colors.white,
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
          ),
          if (_isLoading) // Show progress indicator if loading
            Container(
              color: Colors.black54, // Semi-transparent background
              child: Center(
                child: CircularProgressIndicator(),
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
                      TextFormField(
                        controller: EmailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          } else if (!EmailValidator.validate(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                              if (_formKey.currentState!.validate()) {
                                signInSendEmail();
                              }
                            },
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
                              signInSendEmail();
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
