// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, annotate_overrides
import 'dart:async';
import 'dart:convert';
import 'package:Calldo/Admin/Dashboard/Dashboard.dart';
import 'package:Calldo/Admin/registo.dart';
import 'package:Calldo/Admin/tabela_Users.dart';
import 'package:Calldo/User/DashboardUsers.dart';
import 'package:Calldo/User/resgistarUsers.dart';
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
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=1&name=$name&pwd=$pwd'));
    if (response.statusCode == 200) {
      setState(() {
        print(response.body);
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
      await prefs.setString('username', tar[0]['User'].toString());
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
                'lib/assets/calldo.png',
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
              login();
            },
            child: const Text('Login'),
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
          context, MaterialPageRoute(builder: (context) => Dashboard()));
    } else if (type == "Utilizador") {
      //é user
      print("User");
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => DashboardUsers()));
    }
  } else //é a primeira vez
  {}
}
