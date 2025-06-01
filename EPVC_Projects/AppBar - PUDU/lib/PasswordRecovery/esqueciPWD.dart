import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/PasswordRecovery/inserirCodePWD.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_flutter_project/login.dart';

class EmailRequestPage extends StatefulWidget {
  final int tentativa;
  final String email;

  const EmailRequestPage({super.key, required this.tentativa, required this.email});

  @override
  _EmailRequestPageState createState() => _EmailRequestPageState();
}


class _EmailRequestPageState extends State<EmailRequestPage> {
  final TextEditingController emailController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    emailController.text = widget.email;
    // Não é necessário chamar SystemNavigator.pop aqui, pode causar problemas
  }

  Future<void> sendCodePWD() async {
    var email = emailController.text.trim();

    if (!email.isEmpty) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      var tentativa = widget.tentativa;

      var response = await http.get(Uri.parse(
                    'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=14&email=$email&tentativa=$tentativa'));
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
    return WillPopScope(
      // Interceptar quando o usuário pressiona o botão voltar
      onWillPop: () async {
        // Navegar para a tela de login
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => LoginForm())
        );
        // Retornar false para não usar o comportamento padrão do botão voltar
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Recuperar Password'),
          backgroundColor: Color.fromARGB(255, 246, 141, 45),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              // Navegar para a tela de login quando o botão voltar for pressionado
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => LoginForm())
              );
            },
          ),
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
      ),
    );
  }
}
