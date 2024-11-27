import 'package:flutter/material.dart';
import 'package:my_flutter_project/Admin/users.dart';
import 'package:my_flutter_project/Bar/produtoPageBar.dart';
import 'package:my_flutter_project/Drawer/drawer.dart';
import 'package:my_flutter_project/login.dart';

import 'package:shared_preferences/shared_preferences.dart';

class LogoutDialog extends StatefulWidget {
  @override
  _LogoutDialogState createState() => _LogoutDialogState();
}

class _LogoutDialogState extends State<LogoutDialog> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Trigger logout after dependencies are ready
    Future.microtask(() => logout(context));
  }

 void logout(BuildContext context) {
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
              Navigator.of(context).pop(); // Close the dialog
              Future.microtask(() {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext ctx) =>
                        AdminDrawer(currentPage: UserTable(), numero: 1),
                  ),
                );
              });
            },
          ),
          TextButton(
            child: const Text('Confirmar'),
            onPressed: () async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.clear();
              Navigator.of(context).pop(); // Close the dialog
             
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => LoginForm(),
                  ),
                );
              
            },
          ),
        ],
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return const SizedBox(); // Return an empty widget
  }
}
