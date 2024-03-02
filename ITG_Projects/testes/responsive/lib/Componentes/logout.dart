import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Paginas/Desktop/loginD.dart';
import '../Paginas/Mobile/loginM.dart';
import '../Paginas/tablet/loginT.dart';

class LogoutDialog {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Pretende fazer Log Out?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove('id');
                
                // Consulte o tipo de login armazenado nas preferências compartilhadas
                String loginType = prefs.getString('loginType') ?? '';

                // Redirecione o usuário para a página de login apropriada com base no tipo de login
                switch (loginType) {
                  case 'desktop':
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (BuildContext ctx) => const LoginFormD()),
                    );
                    break;
                  case 'tablet':
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (BuildContext ctx) => const LoginFormT()),
                    );
                    break;
                  case 'mobile':
                  default:
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (BuildContext ctx) => const LoginFormM()),
                    );
                    break;
                }
              },
            ),
          ],
        );
      },
    );
  }
}
