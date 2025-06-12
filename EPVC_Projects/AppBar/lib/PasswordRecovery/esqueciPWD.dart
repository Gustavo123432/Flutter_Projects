import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/PasswordRecovery/inserirCodePWD.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appbar_epvc/login.dart';

class EmailRequestPage extends StatefulWidget {
  final int tentativa;
  final String email;

  const EmailRequestPage({super.key, required this.tentativa, required this.email});

  @override
  _EmailRequestPageState createState() => _EmailRequestPageState();
}

class _EmailRequestPageState extends State<EmailRequestPage> {
  final TextEditingController emailController = TextEditingController();
  bool _isLoading = false;
  http.Client? _client;
  
  @override
  void initState() {
    super.initState();
    emailController.text = widget.email;
    emailController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    emailController.removeListener(_onTextChanged);
    emailController.dispose();
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

  Future<void> sendCodePWD() async {
    if (emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Campo Vazio.\nPreencha o Campo'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _client = http.Client();
    });

    try {
      var email = emailController.text.trim();
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('email', email);
      var tentativa = widget.tentativa;

      var response = await _client!.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=14&email=$email&tentativa=$tentativa'));
      
      if (!mounted) return;
      
      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);

        if (responseData != null && responseData.containsKey("emailSent")) {
          var emailSent = responseData["emailSent"];
          print(emailSent);
          if (emailSent == "true") {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Código de redefinição de senha enviado com sucesso!'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => InserirCodePWD()));
            emailController.clear();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Email não se encontra registado.\nVerifique e tente novamente.'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Resposta inválida do servidor.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao conectar ao servidor.'),
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
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(
                        _isLoading ? Colors.grey : Color.fromARGB(255, 246, 141, 45),
                      ),
                    ),
                    onPressed: _isLoading ? null : () {
                      sendCodePWD();
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
                      : Text('Seguinte'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
