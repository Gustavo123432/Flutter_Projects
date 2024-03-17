import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/PasswordRecovery/inserirCodePWD.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailRequestPage extends StatefulWidget {
  @override
  _EmailRequestPageState createState() => _EmailRequestPageState();
}

class _EmailRequestPageState extends State<EmailRequestPage> {
  final TextEditingController emailController = TextEditingController();

  Future<void> sendCodePWD() async {
    var email = emailController.text.trim();

    if (!email.isEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);

      var response = await http.get(Uri.parse(
          'http://api.gfserver.pt/appBarAPI_GET.php?query_param=14&email=$email&tentativa=0'));
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);

        // Check if responseData is not null and contains the key "emailSent"
        if (responseData != null && responseData.containsKey("emailSent")) {
          var emailSent = responseData["emailSent"];
          print(emailSent);
          if (emailSent == "true") {
            // Check for boolean value, not string "true"
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Código de redefinição de senha enviado com sucesso!'),
              ),
            );
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => InserirCodePWD()));
            emailController.clear();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Email não se encontra registado.\nVerifique e tente novamente.'),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resposta inválida do servidor.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar ao servidor.'),
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Campo Vazio.\nPreencha o Campo'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recuperar Password'),
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Color.fromARGB(255, 246, 141, 45), // Button color
                  ),
                ),
                onPressed: () {
                  // Handle Next button press
                  String email = emailController.text;
                  sendCodePWD();
                  print('Email submitted: $email');
                },
                child: Text('Seguinte'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
