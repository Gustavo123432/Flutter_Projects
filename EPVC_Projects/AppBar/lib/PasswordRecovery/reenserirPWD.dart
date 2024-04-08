import 'package:flutter/material.dart';
import 'package:appBar/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

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
  var email;

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
    SharedPreferences prefs = await SharedPreferences.getInstance();
    email = prefs.getString("email");

    var pwd = passwordController.text;

    var response = await http.get(Uri.parse(
        'http://appbar.epvc.pt//appBarAPI_GET.php?query_param=16&password=$pwd&email=$email'));

    if (response.statusCode == 200) {
      setState(() {
       Navigator.push(
            context, MaterialPageRoute(builder: (context) => LoginForm()));
        passwordController.clear();
        confirmPasswordController.clear();
      });
    } 
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navegue para a tela de login (LoginForm) quando o botão voltar for pressionado
        Navigator.of(context).pushReplacement(MaterialPageRoute(
          builder: (context) => LoginForm(),
        ));
        return true; // Indica que a ação de voltar foi tratada
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Recuperar Password'),
          backgroundColor: Color.fromARGB(255, 246, 141, 45),
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
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Color.fromARGB(255, 246, 141, 45),
                  ),
                ),
                onPressed: () {
                  // Validate password fields
                  String password = passwordController.text;
                  String confirmPassword = confirmPasswordController.text;

                  if (password.isEmpty || confirmPassword.isEmpty) {
                    // Show error if any field is empty
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Por Favor, Preencha todos os campos.'),
                      ),
                    );
                    return;
                  } else if (password != confirmPassword) {
                    // Show error if passwords don't match
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Passwords não coincidem.'),
                      ),
                    );
                    return;
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
