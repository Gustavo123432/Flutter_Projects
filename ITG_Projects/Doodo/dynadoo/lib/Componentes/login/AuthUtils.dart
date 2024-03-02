import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../Paginas/Desktop/Principais/projetos.dart';
import '../../Paginas/Mobile/Principais/projetos.dart';
import '../../Paginas/tablet/Principais/projetos.dart';

class AuthUtils {
  
  static Future<void> login(
    BuildContext context,
    String name,
    String pwd,
    String loginType,
  ) async {
    dynamic tar;
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=1&name=$name&pwd=$pwd'));
    if (response.statusCode == 200) {
      tar = json.decode(response.body);
      if (tar != 'false') {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', tar[0]['iduser'].toString());
        await prefs.setString('type', tar[0]['type'].toString());
        await prefs.setString('loginType', loginType);

        // Determinar o tipo de dispositivo
        Widget projetosPage;
        if (kIsWeb) {
          projetosPage = ProjetosDPage();
        } else if (MediaQuery.of(context).size.width > 600) {
          projetosPage = ProjetosTPage();
        } else {
          projetosPage = ProjetosMPage();
        }

        // Navegar para a página de projetos correspondente
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => projetosPage),
        );
      } else {
        showSnackBar(context, 'Credenciais Inválidas');
      }
    }
  }

  static Future<void> verifyLogin(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var id = prefs.getString("id");
    var type = prefs.getString("type");

    if (id != null) {
      // Determinar o tipo de dispositivo
      Widget projetosPage;
      if (kIsWeb) {
        projetosPage = ProjetosDPage();
      } else if (MediaQuery.of(context).size.width > 600) {
        projetosPage = ProjetosTPage();
      } else {
        projetosPage = ProjetosMPage();
      }

      // Navegar para a página de projetos correspondente
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => projetosPage),
      );
    }
  }

  static void showSnackBar(BuildContext context, String message) {
    final snackBar = SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(
        message,
        style: const TextStyle(
          fontSize: 16,
        ),
      ),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () {
          // Some code to undo the change.
        },
      ),
      backgroundColor: Colors.red,
      elevation: 6.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
