// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, annotate_overrides
import 'dart:async';
import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:my_flutter_project/Admin/dashboard.dart';
import 'package:my_flutter_project/Admin/users.dart';
import 'package:my_flutter_project/Aluno/formatPWDFirst.dart';
import 'package:my_flutter_project/Aluno/home.dart';
import 'package:my_flutter_project/Bar/barPage.dart';
import 'package:my_flutter_project/Drawer/drawer.dart';
import 'package:my_flutter_project/PasswordRecovery/esqueciPWD.dart';
import 'package:my_flutter_project/PasswordRecovery/reenserirPWD.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

String errorMessage = '';

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  // ignore: library_private_types_in_public_api

  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController NameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

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
    final name = NameController.text;
    final pwd = PwdController.text;

    // Verificar se a senha é 'epvc' - Prioridade máxima
    if (pwd.trim().toLowerCase() == 'epvc') {
      PwdController.clear();
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => EmailRequestPage(tentativa: 2)));
      return;
    }

    try {
      dynamic response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=1&name=$name&pwd=$pwd'));

      if (response.statusCode == 200) {
        dynamic tar = json.decode(response.body);

        if (tar == 'false') {
          // Show error message for invalid credentials
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text(
                'Falha no Login. Verifique o email e a password.',
                style: TextStyle(fontSize: 16),
              ),
              backgroundColor: Colors.red,
              elevation: 6.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
            ),
          );
          return;
        }

        // Authentication successful
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('permissao', tar[0]['Permissao'].toString());
        await prefs.setString('username', tar[0]['Email'].toString());
        await prefs.setString('idUser', tar[0]['IdUser'].toString());

        String tipo = tar[0]['Permissao'].toString();
        PwdController.clear();

        if (tipo == "Administrador") {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => AdminDrawer(
                currentPage: DashboardPage(),
                numero: 0,
              ),
            ),
          );
        } else if (tipo == "Professor" ||
            tipo == "Funcionária" ||
            tipo == "Aluno") {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => HomeAlunoMain()));
        } else if (tipo == "Bar") {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => BarPagePedidos()));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Login Inválido. Verifique o Email e a Password e tente novamente!',
            style: TextStyle(fontSize: 16),
          ),
          backgroundColor: Colors.red,
          elevation: 6.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
      );
    }

    setState(() {});
  }

  double opacityLevel = 1.0;
  /////////////////////////////////////////
  /////////////////////////////////////////
  /////////////////////////////////////////

  Widget build(BuildContext context) {
    // Verificar login apenas quando não estiver processando uma autenticação atual
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
        body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Center(
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
                child: Form(
                  key: _formKey,
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
                          child: TextFormField(
                            controller: NameController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color.fromARGB(255, 130, 201,
                                        189)), // Change border color here
                              ),
                              prefixIcon: Icon(Icons.email), // User icon
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) {
                              if (_formKey.currentState!.validate()) {
                                login();
                              }
                            },
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
                          child: TextFormField(
                            controller: PwdController,
                            obscureText: _obscureText,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderSide: BorderSide(
                                  color: Color.fromARGB(255, 130, 201,
                                      189), // Change border color here
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
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text.rich(
                        TextSpan(
                          text: 'Esqueceu-se da Password? ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          children: <TextSpan>[
                            TextSpan(
                              text: 'Clique Aqui',
                              style: TextStyle(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  // Lógica para lidar com o clique no texto
                                  print('Esqueceu-se da Password? Clique Aqui');
                                  // Adicione aqui a lógica para lidar com a recuperação da senha
                                },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            login();
                          }
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
            )));
  }

  Widget mobileScreenLayout() {
    return Scaffold(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        body: Form(
          key: _formKey,
          child: Column(
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
              Text.rich(
                TextSpan(
                  text: 'Esqueceu-se da Password? ',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 12,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: 'Clique Aqui',
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Lógica para lidar com o clique no texto
                          print('Esqueceu-se da Password? Clique Aqui');

                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => EmailRequestPage(
                                        tentativa: 0,
                                      )));

                          // Adicione aqui a lógica para lidar com a recuperação da senha
                        },
                    ),
                  ],
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
                  if (_formKey.currentState!.validate()) {
                    login();
                  }
                },
                child: Text('Login'), // Add a child widget to the button
              ),
            ],
          ),
        ));
  }
}

void verifylogin(context) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("username");
    var type = prefs.getString("permissao");
    var pwd = prefs.getString("pwd");

    // Verificar se há um usuário logado
    if (id == null) {
      // Não há usuário logado, apenas retornar
      return;
    }

    // Verificar se a senha é 'epvc' - tem prioridade sobre qualquer outra verificação
    if (pwd != null && pwd.trim().toLowerCase() == "epvc") {
      // Remover a senha para evitar loops
      await prefs.remove("pwd");

      // Navegar para EmailRequestPage com tentativa 2
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => EmailRequestPage(tentativa: 2)));
      return;
    }

    // Processar navegação normal baseada no tipo de usuário
    if (type == "Administrador") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => AdminDrawer(
            currentPage: DashboardPage(),
            numero: 0,
          ),
        ),
      );
    } else if (type == "Professor") {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeAlunoMain()));
    } else if (type == "Funcionária") {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeAlunoMain()));
    } else if (type == "Bar") {
      Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => BarPagePedidos()));
    } else if (type == "Aluno") {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Bem-vindo, Aluno!")));

      Future.delayed(Duration(seconds: 1), () {
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => HomeAlunoMain()));
        }
      });
    }
  } catch (e) {
    print("Erro na Verificação");
  }
}
