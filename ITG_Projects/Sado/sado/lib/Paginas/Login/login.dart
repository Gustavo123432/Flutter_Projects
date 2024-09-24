import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sado/Paginas/Login/forgotPasswordFirst.dart';
import 'package:sado/Paginas/Login/signUpFirst.dart'; // Ensure this import is correct
import 'package:sado/Paginas/Login/signUpFirst.dart';
import 'package:sado/Paginas/Principais/Admin/dashboardPage.dart';
import 'package:sado/Paginas/Registo/userRegister.dart';
import 'package:sado/animation/animation_page.dart';
import 'package:email_validator/email_validator.dart';
import 'package:sado/drawer/adminDrawer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController pwdController = TextEditingController();

  bool _isLoading = false;

  void login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      var name = nameController.text;
      var pwd = pwdController.text;

      final response = await http.post(
        Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
        body: {
          'query_param': 'U1',
          'log': name.toString(),
          'pwd': pwd.toString(),
        },
      );

      if (response.statusCode == 200) {
        final tar = json.decode(response.body);

        if (tar == 0) {
          _showDialog(context, 'Email not Registered',
              'The email you entered is not registered, please Register', 2);
          setState(() {
            _isLoading = false;
          });
        } else if (tar != null &&
            tar.containsKey('iduser') &&
            tar['iduser'] != 'false') {
          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('idUser', tar['iduser'].toString());
          await prefs.setString('idMaster', tar['codmaster'].toString());
          _showDialog(
              context, 'Login Success', 'You have successfully logged in!', 3);
        } else {
          _showDialog(
              context, 'Login Failed', 'Invalid username or password.', 0);
          setState(() {
            _isLoading = false;
          });
        }
      } else {
        _showDialog(context, 'Error', 'Failed to connect to the server.', 0);
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showDialog(context, 'Error', 'An unexpected error occurred: $e', 0);
      setState(() {
        _isLoading = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<int> verifyCRegisto(String id) async {
    final response = await http.post(
      Uri.parse('https://services.interagit.com/API/Sado/api_Sado.php'),
      body: {
        'query_param': 'U7',
        'id': id,
      },
    );

    if (response.statusCode == 200) {
      final tar = json.decode(response.body);
      if (tar == 0) {
        Navigator.push(
          context,
          SlideTransitionPageRoute(
            page: UserRegisterForm(),
          ),
        );
        return 0;
      } else if (tar == 1) {
        Navigator.push(
          context,
          SlideTransitionPageRoute(
            page: AdminDrawer(currentPage: DashboardPage(), numero: 0),
          ),
        );
      }
    } else {
      return -1;
    }
    return -1;
  }

  Future<void> _showDialog(
      BuildContext context, String title, String message, int value) async {
    if (value != 2 && value != 3) {
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
                  nameController.clear();
                  pwdController.clear();
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
    } else if (value == 3) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var idUser = prefs.getString("idUser");
      var verify = await verifyCRegisto(idUser.toString());
      if (verify == 0) {
        Navigator.push(
          context,
          SlideTransitionPageRoute(
            page: UserRegisterForm(),
          ),
        );
        print("0");
      } else if (verify == 1) {
        print("1");
        Navigator.pushNamed(context, '/dashboard');
      }
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
                        controller: nameController,
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
                                login();
                              }
                            },
                      ),
                      SizedBox(height: 20),
                      TextFormField(
                        controller: pwdController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) {
                              if (_formKey.currentState!.validate()) {
                                login();
                              }
                            },
                      ),
                      SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUpFirstForm(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign Up',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForgotPasswordForm(),
                                ),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
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
                              login();
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

    Widget webScreenLayout() {

    verifylogin(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWeb = constraints.maxWidth > 600;
        return Scaffold(
          backgroundColor: Colors.white,
          body: Form(
            key: _formKey,
            child: Flex(
              direction: isWeb ? Axis.horizontal : Axis.vertical,
              children: [
                if (!isWeb)

                  // Content
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 100), // Spacer for the top area
                          Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(height: 20),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                          ),
                          SizedBox(height: 16),
                          Align(
                            alignment: Alignment.centerRight,
                            child: ElevatedButton(
                              onPressed: () {},
                              child: Text('Sign in'),
                              style: ElevatedButton.styleFrom(
                                shape: CircleBorder(),
                                padding: EdgeInsets.all(20),
                              ),
                            ),
                          ),
                          SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              TextButton(
                                onPressed: () {},
                                child: Text('Sign Up'),
                              ),
                              TextButton(
                                onPressed: () {},
                                child: Text('Forgot Password'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (isWeb)
                  Expanded(
                    flex: 4,
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
                            SizedBox(height: 50),
                            const Text(
                              "Welcome Back!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 60,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 30),
                            const Text(
                              "We're always here, waiting for you!",
                              style: TextStyle(
                                color: Color.fromARGB(255, 200, 238, 255),
                                fontSize: 30,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: 40),
                            const Text(
                              "Not have an Account?",
                              style: TextStyle(
                                color: Color.fromARGB(255, 200, 238, 255),
                                fontSize: 24,
                              ),
                            ),
                            SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  CustomHeroPageRoute(
                                    page: SignUpFirstForm(),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Color.fromARGB(150, 84, 155, 231),
                                minimumSize: const Size(200, 50),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: const Text(
                                'Sign Up',
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
                Expanded(
                  flex: isWeb ? 7 : 1,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isWeb)
                          const Text(
                            "Login to Account",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        if (isWeb) SizedBox(height: 20),
                        SizedBox(
                          width: 500,
                          child: TextFormField(
                            controller: nameController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: TextStyle(
                                fontSize: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Icon(Icons.email_outlined, size: 30),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 10,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Email is required';
                              }
                              /*if (!EmailValidator.validate(value)) {
                                return 'Please enter a valid email address';
                              }*/
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (_formKey.currentState!.validate()) {
                                login();
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 20),
                        SizedBox(
                          width: 500,
                          child: TextFormField(
                            controller: pwdController,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: TextStyle(
                                fontSize: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              prefixIcon: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Icon(Icons.lock, size: 30),
                              ),
                              contentPadding: EdgeInsets.symmetric(
                                vertical: 20,
                                horizontal: 10,
                              ),
                            ),
                            style: TextStyle(
                              fontSize: 18,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password is required';
                              }
                              return null;
                            },
                            obscureText: true,
                            onFieldSubmitted: (_) {
                              if (_formKey.currentState!.validate()) {
                                login();
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 30),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              SlideTransitionPageRoute(
                                page:
                                    const ForgotPasswordForm(), // Use LoginForm or the intended page
                              ),
                            );
                          },
                          child: const Text(
                            "Forgot Password?",
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        if (isWeb) SizedBox(height: 30),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              login();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            minimumSize: const Size(200, 50),
                            side: BorderSide(
                              color: Color.fromARGB(150, 84, 155, 231),
                              width: 2.0,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: _isLoading
                              ? CircularProgressIndicator()
                              : const Text(
                                  'Login',
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
      },
    );
  }
}

void verifylogin(context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var idUser = prefs.getString("idUser");
  if (idUser != null) {
    Navigator.push(
      context,
      SlideTransitionPageRoute(
        page: AdminDrawer(
          currentPage: DashboardPage(),
          numero: 0,
        ),
      ),
    );

    /*  Navigator.of(context).push(PageRouteBuilder(
  settings: RouteSettings(name: '/dashboard'), ));*/

    // Navigator.pushNamed(context, '/dashboard');

    /*showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Login Success'),
          content: Text("You are already logged in."),
          actions: <Widget>[
            TextButton(
              child: Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );*/
  }
}
