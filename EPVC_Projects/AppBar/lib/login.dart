// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, annotate_overrides
import 'dart:async';
import 'dart:convert';
import 'package:appbar_epvc/Monitor/barPedidosPage.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:appbar_epvc/Admin/dashboard.dart';
import 'package:appbar_epvc/Admin/users.dart';
import 'package:appbar_epvc/Aluno/formatPWDFirst.dart';
import 'package:appbar_epvc/Aluno/home.dart';
import 'package:appbar_epvc/Bar/barPage.dart';
import 'package:appbar_epvc/Drawer/drawer.dart';
import 'package:appbar_epvc/PasswordRecovery/esqueciPWD.dart';
import 'package:appbar_epvc/PasswordRecovery/reenserirPWD.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';

String errorMessage = '';

// Utility function to generate MD5 hash
String generateMD5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class LoginForm extends StatefulWidget {
  const LoginForm({super.key});

  @override
  _LoginFormState createState() => _LoginFormState();
}

class _LoginFormState extends State<LoginForm> {
  final TextEditingController NameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final TextEditingController PwdController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          message,
          style: const TextStyle(fontSize: 16),
        ),
        backgroundColor: Colors.red,
        elevation: 6.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0),
        ),
      ),
    );
  }

  Future<void> login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final name = NameController.text.trim();
    final pwd = PwdController.text.trim();

    if (name.isEmpty || pwd.isEmpty) {
      _showErrorSnackBar('Por favor, preencha todos os campos.');
      setState(() {
        _isLoading = false;
      });
      return;
    }

    // Encrypt password with MD5
    final encryptedPwd = generateMD5(pwd);

    try {
      final response = await http.get(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=1&name=$name&pwd=$encryptedPwd'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data == 'false') {
          _showErrorSnackBar('Falha no Login. Verifique o email e a password.');
          return;
        }

        // Check if user needs to reset password (only if defaultPWD is 1)
        if (data[0]['defaultPWD'] == '1') {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => EmailRequestPage(
                tentativa: 2,
                email: data[0]['Email'].toString(),
              ),
            ),
          );
          return;
        }

        // Store preferences
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('permissao', data[0]['Permissao'].toString());
        await prefs.setString('username', data[0]['Email'].toString());
        await prefs.setString('idUser', data[0]['IdUser'].toString());

        String tipo = data[0]['Permissao'].toString();
        PwdController.clear();

        if (!mounted) return;

        switch (tipo) {
          case "Administrador":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => AdminDrawer(
                  currentPage: DashboardPage(),
                  numero: 0,
                ),
              ),
            );
            break;
          case "Professor":
          case "Funcionária":
          case "Aluno":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => HomeAlunoMain()),
            );
            break;
          case "Bar":
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => BarPagePedidos()),
            );
            break;
          default:
            _showErrorSnackBar('Tipo de usuário não reconhecido.');
        }
      } else {
        _showErrorSnackBar('Erro no servidor. Tente novamente mais tarde.');
      }
    } catch (e) {
      _showErrorSnackBar('Erro de conexão. Verifique sua internet e tente novamente.');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  double opacityLevel = 1.0;
  /////////////////////////////////////////
  /////////////////////////////////////////
  /////////////////////////////////////////

  @override
  void initState() {
    super.initState();
    verifylogin(context);
  }

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
                        color: const Color.fromARGB(255, 130, 201, 189),
                        child: Image.asset(
                          'lib/assets/barapp.png',
                          width: 350,
                          height: 150,
                          errorBuilder: (context, error, stackTrace) {
                            print('Error loading image: $error');
                            return const Icon(
                              Icons.school,
                              size: 120,
                              color: Colors.white,
                            );
                          },
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
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.orange, width: 2.0),
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
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                    color: Colors.orange, width: 2.0),
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
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.orange, width: 2.0),
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
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: Colors.orange, width: 2.0),
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
                                        email: "",
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

    // Verificar se há um usuário logado
    if (id == null) {
      // Não há usuário logado, apenas retornar
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
    } else if (type == "Professor" || type == "Funcionária" || type == "Aluno") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeAlunoMain()),
      );
    } else if (type == "Bar") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => BarPagePedidos()),
      );
    }
     else if (type == "Monitor") {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => BarRequests()),
      );
    }
  } catch (e) {
    print('Erro ao verificar login: $e');
  }
}
