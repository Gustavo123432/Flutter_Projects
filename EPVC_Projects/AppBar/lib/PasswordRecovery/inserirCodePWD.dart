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
  bool _isLoading = false;
  int contador = 30; // Defina o contador inicial para 30 segundos
  http.Client? _client;

  @override
  void initState() {
    super.initState();
    _digitController.addListener(_onTextChanged);

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

  @override
  void dispose() {
    _digitController.removeListener(_onTextChanged);
    _digitController.dispose();
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

  Future<void> resendEmail() async {
    if (!_isResendingEmail) return;

    setState(() {
      _isLoading = true;
      _client = http.Client();
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var email = prefs.getString("email");
      
      var response = await _client!.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=14&email=$email&tentativa=1'));
      
      if (!mounted) return;

      var responseData = json.decode(response.body);

      if (responseData != null && responseData.containsKey("emailSent")) {
        var emailSent = responseData["emailSent"];
        if (emailSent == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email Reenviado com Sucesso.\n Volte a Introduzir o Código.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
          setState(() {
            contador = 30;
            _isResendingEmail = false;
          });
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

  Future<void> checkCode() async {
    if (_digitController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Campo Vazio.\nPreencha o Campo'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _client = http.Client();
    });

    try {
      var code = _digitController.text.toString();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var email = prefs.getString("email");
      
      if (email != null) {
        var response = await _client!.get(Uri.parse(
            'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=15&code=$code&email=$email'));

        if (!mounted) return;

        if (response.statusCode == 200) {
          var responseData = json.decode(response.body);
          var success = responseData["success"];
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Código Correto.'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                margin: EdgeInsets.all(8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            Navigator.push(context,
                MaterialPageRoute(builder: (context) => ReenserirPassword()));
            _digitController.clear();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Introduza um Código Válido.'),
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
              content: Text('Erro ao conectar-se à API.'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $error'),
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
                onTap: _isResendingEmail && !_isLoading ? resendEmail : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Reenviar Email? ',
                      style: TextStyle(
                        color: _isResendingEmail && !_isLoading
                            ? Colors.blue
                            : Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    if (!_isResendingEmail)
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
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all<Color>(
                      _isLoading ? Colors.grey : Color.fromARGB(255, 246, 141, 45),
                    ),
                  ),
                  onPressed: _isLoading ? null : checkCode,
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
                    : Text('Enviar'),
                ),
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
