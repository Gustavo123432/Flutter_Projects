// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, annotate_overrides
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:my_flutter_project/Admin/users.dart';
import 'package:my_flutter_project/Aluno/barList.dart';
import 'package:my_flutter_project/Aluno/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

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
  bool _obscureText = true;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
    Future.delayed(Duration(seconds: 10), () {
      setState(() {
        _obscureText = true;
      });
    });
  }

  void login() async {
    // print("Iniciando login...");

    final name = NameController.text;
    final pwd = PwdController.text;
    // print("Email: $name, Senha: $pwd");

    /////////////////////////////////////////
    // Send a GET  request to your PHP API for authentication
    /////////////////////////////////////////

    dynamic tar;
    dynamic response = await http.get(Uri.parse(
        'http://api.gfserver.pt/appBarAPI_GET.php?query_param=1&name=$name&pwd=$pwd'));
    if (response.statusCode == 200) {
      setState(() {
        //print(response.body);
        tar = json.decode(response.body);
      });
      //print(tar[0]['iduser']);
    }
    /*final response = await http.post(
          Uri.parse('https://services.interagit.com/API/api_Calendar_Post.php'),
          body: {
            'query_param': '1',
          },
        );
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      //print(tar[0]['iduser']);
    }*/
    if (tar != 'false') {
      // Authentication successful, navigate to the next screen or perform actions
      //print("Resposta da API: $responseData");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('permissao', tar[0]['Permissao'].toString());
      await prefs.setString('username', tar[0]['Email'].toString());
      await prefs.setString('idUser', tar[0]['IdUser'].toString());
    } else if (tar == 'false') {
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          errorMessage = 'Credenciais Inválidas',
          style: const TextStyle(
            fontSize: 16, // Customize font size
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
        backgroundColor: Colors.red, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
    setState(() {});
  }

  double opacityLevel = 1.0;
  /////////////////////////////////////////
  /////////////////////////////////////////
  /////////////////////////////////////////

  Widget build(BuildContext context) {
    verifylogin(context);
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
            color: const Color.fromARGB(255, 130, 201, 189),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: const Color.fromARGB(255, 130, 201, 189),
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
              Container(
                width: 350,
                height: 150,
                color: Color.fromARGB(255, 130, 201, 189),
                child: Image.asset(
                  'lib/assets/barapp.png',
                  width: 350,
                  height: 150,
                ),
              ),
              const SizedBox(
            height: 20,
          ),
              SizedBox(
                width: 350,
                child: Container(
                  color: Colors.white,
                  child: TextField(
                    controller: NameController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(
                          255, 130, 201, 189)), // Change border color here
                ),
                      prefixIcon: Icon(Icons.email), // User icon
                    ),
                  ),
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              SizedBox(
                width: 350,
                child: Container(
                  color: Colors.white,
                child: TextField(
                  controller: PwdController,
                  obscureText: _obscureText,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(
                            255, 130, 201, 189), // Change border color here
                      ),
                    ),
                    prefixIcon: Icon(Icons.lock), // User icon
                    suffixIcon: IconButton(
                      icon: _obscureText
                          ? Icon(Icons.visibility)
                          : Icon(Icons.visibility_off),
                      onPressed: _togglePasswordVisibility,
                    ),
                  ),
                ),
              ),),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  login();
                },
                style: ElevatedButton.styleFrom(
                  // ignore: deprecated_member_use
                  backgroundColor:
                      Color.fromARGB(255, 246, 141, 45), // Button color
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
      backgroundColor: Color.fromARGB(255, 255, 255, 255),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Center(
            child: Hero(
              tag: 'Logo',
              child: Image.asset(
                'lib/assets/barapp.png',
                width: 100,
              ),
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          SizedBox(
            width: 350,
            child: TextField(
              controller: NameController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Color.fromARGB(
                          255, 130, 201, 189)), // Change border color here
                ),
                prefixIcon: Icon(Icons.email), // User icon
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
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromARGB(
                        255, 130, 201, 189), // Change border color here
                  ),
                ),
                prefixIcon: Icon(Icons.lock), // User icon
                suffixIcon: IconButton(
                  icon: _obscureText
                      ? Icon(Icons.visibility)
                      : Icon(Icons.visibility_off),
                  onPressed: _togglePasswordVisibility,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all<Color>(
                Color.fromARGB(255, 246, 141, 45), // Button color
              ),
            ),
            onPressed: () {
              login();
            },
            child: Text('Login'), // Add a child widget to the button
          ),
        ],
      ),
    );
  }
}

void verifylogin(context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var id = prefs.getString("username");
  var idUser = prefs.getString("idUser");
  var type = prefs.getString("permissao");
  //print(id);
  //print(type);
  if (id != null) //já arrancou a app
  {
    if (type == "Administrador") //é adm
    {
      print("Administrador");
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => HomeAlunoMain()));
    } 
    else if (type == "Professor") {
      //é user
      print("Professor");
      /*Navigator.push(
          context, MaterialPageRoute(builder: (context) => DashboardUsers()));*/
    }
     else if (type == "Funcionária") {
      //é user
      print("Funcionária");
      /*Navigator.push(
          context, MaterialPageRoute(builder: (context) => DashboardUsers()));*/
    }
    else if (type == "Utilizador") {
      //é user
      print("User");
      /*Navigator.push(
          context, MaterialPageRoute(builder: (context) => DashboardUsers()));*/
    }
  } else //é a primeira vez
  {}
}