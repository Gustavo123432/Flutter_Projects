import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/PasswordRecovery/reenserirPWD.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class InserirCodePWD extends StatefulWidget {
  @override
  _InserirCodePWDState createState() => _InserirCodePWDState();
}

class _InserirCodePWDState extends State<InserirCodePWD> {
  TextEditingController _digitController = TextEditingController();
  String _result = '';
  bool _isResendingEmail = false;
  int contador = 30; // Defina o contador inicial para 30 segundos

  @override
  void initState() {
    super.initState();
    // Ative o timer após a tela ser construída pela primeira vez

    Timer.periodic(Duration(seconds: 1), (timer) {
      if (contador > 0) {
        setState(() {
          contador--;
        });
      } else {
        timer.cancel(); // Pare o timer quando o contador atingir 0
        setState(() {
          _isResendingEmail = true;
        });
      }
    });
  }

  Future<void> resendEmail() async {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var email = prefs.getString("email");
    var response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=14&email=$email&tentativa=1'));
    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);
      print(responseData);

      if (responseData != null && responseData.containsKey("emailSent")) {
        var emailSent = responseData["emailSent"];
        if (emailSent == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Email Reenviado com Sucesso.\n Volte a Introduzir o Código.'),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Email não se encontra registado. \nVerifique e tente novamente.'),
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
  }

 Future<void> checkCode() async {
  var code = _digitController.text.toString();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  var email = prefs.getString("email");
  
  if (!code.isEmpty && email != null) {
    try {
      var response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=15&code=$code&email=$email'));

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        var success = responseData["success"];
        if (success) {
          setState(() {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Código Correto.'),
              ),
            );
          });
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => ReenserirPassword()));
          _digitController.clear();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Introduza um Código Válido.'),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar-se à API.'),
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $error'),
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Introduza o Código de 4 Dígitos:'),
              SizedBox(height: 10),
              Container(
                width: 200,
                child: TextField(
                  controller: _digitController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  maxLength: 4,
                ),
              ),
              Text("Verifique o SPAM do seu email!\n"),
              GestureDetector(
                onTap: _isResendingEmail
                    ? resendEmail
                    : null, // Desative o onTap quando não estiver pronto para reenviar o email
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Reenviar Email? ',
                      style: TextStyle(
                        color: _isResendingEmail
                            ? Colors.blue
                            : Colors
                                .grey, // Altere a cor do texto com base no estado de reenvio do email
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    if (!_isResendingEmail) // Mostrar o contador se não estiver pronto para reenviar o email
                      Text(
                        '($contador s)',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all<Color>(
                    Color.fromARGB(255, 246, 141, 45),
                  ),
                ),
                onPressed: checkCode,
                child: Text('Enviar'),
              ),
              SizedBox(height: 20),
              Text(
                _result,
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
