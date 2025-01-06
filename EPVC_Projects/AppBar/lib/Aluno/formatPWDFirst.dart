import 'package:flutter/material.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class FirstLogin extends StatefulWidget {
  @override
  _FirstLoginState createState() => _FirstLoginState();
}

class _FirstLoginState extends State<FirstLogin> {
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  bool _obscureText = true;
  bool _obscureText1 = true;
  bool _isLoading = false;

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _togglePasswordConfirmVisibility() {
    setState(() {
      _obscureText1 = !_obscureText1;
    });
  }

  Future<void> changePWD() async {
    setState(() {
      _isLoading = true;
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final email = prefs.getString("username");
    final pwd = passwordController.text;

    try {
      final response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=16&password=$pwd&email=$email'));

      if (response.statusCode == 200) {
        // Delay navigation for 1 second to show the login screen briefly
        await Future.delayed(Duration(seconds: 1));

        // Navigate back to the previous screen

        passwordController.clear();
        confirmPasswordController.clear();
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginForm()));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erro ao alterar a password. Por favor, tente novamente.'),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erro de conexão. Por favor, verifique sua conexão com a internet.'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => LoginForm()));
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Inserir Password'),
          backgroundColor: Color.fromARGB(255, 246, 141, 45),
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Padding(
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
                            color: Color.fromARGB(255, 130, 201, 189),
                          ),
                        ),
                        prefixIcon: Icon(Icons.lock),
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
                            color: Color.fromARGB(255, 130, 201, 189),
                          ),
                        ),
                        prefixIcon: Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: _obscureText1
                              ? Icon(Icons.visibility)
                              : Icon(Icons.visibility_off),
                          onPressed: _togglePasswordConfirmVisibility,
                        ),
                      ),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all<Color>(
                          Color.fromARGB(255, 246, 141, 45),
                        ),
                      ),
                      onPressed: () {
                        String password = passwordController.text;
                        String confirmPassword = confirmPasswordController.text;

                        if (password.isEmpty || confirmPassword.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Por Favor, Preencha todos os campos.'),
                            ),
                          );
                        } else if (password != confirmPassword) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Passwords não coincidem.'),
                            ),
                          );
                        } else {
                          changePWD();
                        }
                      },
                      child: Text('Mudar Password'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
