import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import '../../mobile/secondScreen.dart';

class AuthService {
  static String errorMessage = '';

  static void login(BuildContext context, String name, String pwd) async {
    dynamic tar;
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=1&name=$name&pwd=$pwd'));
    if (response.statusCode == 200) {
      tar = json.decode(response.body);
    }
    if (tar != 'false') {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('id', tar[0]['iduser'].toString());
      await prefs.setString('type', tar[0]['type'].toString());
      // Navegue para a próxima tela após o login bem-sucedido
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SecondScreen()),
      );
    } else if (tar == 'false') {
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          errorMessage = 'Credenciais Inválidas',
          style: const TextStyle(
            fontSize: 16, // Customize font size
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Algum código para desfazer a alteração.
          },
        ),
        backgroundColor: Colors.red, // Customize background color
        elevation: 6.0, // Adicione elevação
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  static void verifylogin(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("id");
    var type = prefs.getString("type");

  if (id != null) //já arrancou a app
  {
    if (type == "1") //é adm
    {
      if (kIsWeb == true) //abrir web
      {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SecondScreen()));
      } else {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SecondScreen()));
      }
    } else if (type == "0") {
      //é userç
      if (kIsWeb == true) //não deixa
      {
        Navigator.push(
            context, MaterialPageRoute(builder: (context) => SecondScreen()));
      } else {
               Navigator.push(
            context, MaterialPageRoute(builder: (context) => SecondScreen()));
      }
    }
  } else //é a primeira vezçç
  {

  }
  }
}
