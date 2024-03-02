// ignore_for_file: must_be_immutable

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:todo_itg/login.dart';

class changePassDialogPage extends StatefulWidget {
  @override
  dynamic id;

  changePassDialogPage({super.key, 
  
    required this.id,
  });

  @override
  _changePassDialogPage createState() => _changePassDialogPage();
}

class _changePassDialogPage extends State<changePassDialogPage> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confPassController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Alterar Palavra-Pass"),
          Container(
            color: Colors.black,
            width: 375,
            height: 1,
          ),
        ],
      ),
      content: SizedBox(
        width: 375,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              TextField(
                controller: _passController,
                decoration: const InputDecoration(
                  labelText: 'Introduza uma nova Palavra-Pass',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confPassController,
                decoration: const InputDecoration(
                  labelText: 'Repetida a nova Palavra-Pass',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          onPressed: () {
            _emptyFields();
          },
          child: const Text("Confirmar"),
        ),
      ],
    );
  }

  void _emptyFields() async {
    final pass = _passController.text;
    final confPass = _confPassController.text;

    if (pass.isEmpty || confPass.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Campos Vazios"),
            content: const Text("Preencha todos os campos antes de continuar."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else if (pass != confPass) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text("Palavra-Pass Diferentes"),
            content: const Text("As Palavras-Pass introduzidas não coincidem."),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK"),
              ),
            ],
          );
        },
      );
    } else {
      AlterarPass(widget.id);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginForm()),
      );

      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text(
          'Palavra-Pass alterada',
          style: TextStyle(
            fontSize: 16, // Customize font size
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
        backgroundColor: Colors.green, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    }
  }

  AlterarPass(int id) async {
    String pwd = _passController.text;
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=21&id=$id&pwd=$pwd'));
  }
}
