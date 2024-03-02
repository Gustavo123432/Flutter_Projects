// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, annotate_overrides
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:help_center_itgdoodo/fornewupdate/detailsEmpresa.dart';
import 'package:help_center_itgdoodo/fornewupdate/empresaD.dart';
import 'package:help_center_itgdoodo/fornewupdate/empresas.dart';
import 'package:help_center_itgdoodo/ticket.dart';
import 'package:help_center_itgdoodo/usersTickets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

String errorMessage = '';

void main() {
  runApp(const LoginApp());
}

class LoginApp extends StatelessWidget {
  const LoginApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: SplashScreen(),
      ),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    verifylogin(context);
    return const Scaffold();
  }
}

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
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=1&name=$name&pwd=$pwd'));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      //print(tar);
    }
    if (tar != 'false') {
      // Authentication successful, navigate to the next screen or perform actions
      //print("Resposta da API: $responseData");
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('id', tar[0]['iduser'].toString());
      await prefs.setString('type', tar[0]['type'].toString());
      verifylogin(context);
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
                'assets/images/logodoodo.jpg',
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
              const SizedBox(height: 10),
              Text(
                errorMessage,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 16,
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
  var id = prefs.getString("id");
  var type = prefs.getString("type");
  //print(id);
  //print(type);
  if (id != null) //já arrancou a app
  {
    if (type == "1") //é adm
    {
      if (kIsWeb == true) //abrir web
      {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => empresadPage(),
            ));
      } else //abrir app
      {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SecondPage(),
            ));
      }
    } else if (type == "0") {
      if (kIsWeb == true) //não deixa
      {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UsersTicketsPage(),
            ));
      } else //abrir app
      {
        Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SecondPage(),
            ));
      }
    }
  } else //é a primeira vez
  {
    Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const LoginForm(),
        ));
  }
}

class SecondPage extends StatefulWidget {
  @override
  _SecondPageState createState() => _SecondPageState();
}

class _SecondPageState extends State<SecondPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Page 2'),
      ),
      body: Center(
        child: Text('Page 2 Content'),
      ),
    );
  }
}
