import 'package:flutter/material.dart';
import 'package:appbar_epvc/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'dart:convert';

// Utility function to generate MD5 hash
String generateMD5(String input) {
  return md5.convert(utf8.encode(input)).toString();
}

class ReenserirPassword extends StatefulWidget {
  @override
  _ReenserirPasswordState createState() => _ReenserirPasswordState();
}

class _ReenserirPasswordState extends State<ReenserirPassword> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _obscureText = true;
  bool _obscureText1 = true;
  bool _isLoading = false;
  var email;
  http.Client? _client;

  @override
  void initState() {
    super.initState();
    passwordController.addListener(_onTextChanged);
    confirmPasswordController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    passwordController.removeListener(_onTextChanged);
    confirmPasswordController.removeListener(_onTextChanged);
    passwordController.dispose();
    confirmPasswordController.dispose();
    _client?.close();
    super.dispose();
  }

  void _onTextChanged() {
    if (_isLoading) {
      _client?.close();
      _client = null;
      setState(() {
        _isLoading = false;
      });
    }
  }

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

  void _togglePasswordConfirmVisibility() {
    setState(() {
      _obscureText1 = !_obscureText1;
    });
    Future.delayed(Duration(seconds: 10), () {
      setState(() {
        _obscureText1 = true;
      });
    });
  }

  Future<void> changePWD() async {
    setState(() {
      _isLoading = true;
      _client = http.Client();
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      email = prefs.getString("email");

      var pwd = passwordController.text;
      // Encrypt password with MD5
      var encryptedPwd = generateMD5(pwd);

      var response = await _client!.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=16&password=$encryptedPwd&email=$email'));

      if (!mounted) return;

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password alterada com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );

        await prefs.clear();
        passwordController.clear();
        confirmPasswordController.clear();

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (BuildContext ctx) => const LoginForm()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao alterar a password. Por favor, tente novamente.'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar a solicitação: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _client?.close();
          _client = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginForm()),
        );
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Recuperar Password'),
          backgroundColor: Color.fromARGB(255, 246, 141, 45),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginForm()),
              );
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: passwordController,
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
              SizedBox(height: 20),
              TextField(
                controller: confirmPasswordController,
                obscureText: _obscureText1,
                decoration: InputDecoration(
                  labelText: 'Confirmar Password',
                  border: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(
                          255, 130, 201, 189), // Change border color here
                    ),
                  ),
                  prefixIcon: Icon(Icons.lock), // User icon
                  suffixIcon: IconButton(
                    icon: _obscureText1
                        ? Icon(Icons.visibility)
                        : Icon(Icons.visibility_off),
                    onPressed: _togglePasswordConfirmVisibility,
                  ),
                ),
              ),
              SizedBox(height: 20),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      _isLoading ? Colors.grey : Color.fromARGB(255, 246, 141, 45),
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () {
                          String password = passwordController.text;
                          String confirmPassword = confirmPasswordController.text;

                          if (password.isEmpty || confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Por Favor, Preencha todos os campos.'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.all(8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            return;
                          } else if (password != confirmPassword) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Passwords não coincidem.'),
                                backgroundColor: Colors.red,
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.all(8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                            return;
                          } else {
                            changePWD();
                          }
                        },
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Processando...'),
                          ],
                        )
                      : Text('Mudar Password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
