import 'package:flutter/material.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class CreateEmpresasPage extends StatefulWidget {
  @override
  _CreateEmpresasPageState createState() => _CreateEmpresasPageState();
}

class _CreateEmpresasPageState extends State<CreateEmpresasPage> {
  TextEditingController _nomeEmpresaController = TextEditingController();
  TextEditingController _colorEmpresaController = TextEditingController();

  //Equipa de HelpDesk Responsável
  TextEditingController _equipaRespController = TextEditingController();
  //Pessoa Responsável por parte do cliente
  TextEditingController _mailRespController = TextEditingController();
  TextEditingController _nomeRespController = TextEditingController();
  TextEditingController _contRespController = TextEditingController();
  dynamic type;

  Color _color = Colors.blue;
  bool _isPasswordVisible = false;
  List<String> order = <String>['User', 'Admin'];
  dynamic orderv = 'User';
  dynamic numberint;
  List<Color> colors = [
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
    Colors.black,
  ];

  CreateEmpresa(String nomeEmpresa, String equipaResp, String mailResp,
      String nomeResp, String contResp) async {
    dynamic response = await http.get(Uri.parse(
        //  'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=15&name=$name&pwd=$pwd&log=$log&cont=$cont&mail=$mail&type=$type'//atualizar
        ''));
    if (response.statusCode == 200) {
      setState(() {
        //Users = jsonDecode(response.body) as List;
      });
    }
  }

  void _openBlockPicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecione uma cor'),
          content: BlockPicker(
            pickerColor: currentColor,
            onColorChanged: (color) {
              setState(() => currentColor = color);
            },
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fechar o diálogo
              },
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  Color currentColor = Colors.amber;

  String initialCountry = 'PT';
  PhoneNumber number = PhoneNumber(isoCode: 'PT');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: <Widget>[
            Card(
              elevation: 3,
              child: Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    TextField(
                      controller: _nomeEmpresaController,
                      decoration: const InputDecoration(
                        labelText: 'Nome Empresa',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButton<String>(
                      value: orderv,
                      hint: Text(orderv),
                      icon: const Icon(Icons.expand_more),
                      elevation: 16,
                      style: const TextStyle(color: Colors.black),
                      underline: Container(
                        height: 2,
                        color: Colors.blue,
                      ),
                      items:
                          order.map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          orderv = value.toString();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Cor Selecionada:',
                      style: TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      width: 50,
                      height: 50,
                      color: currentColor,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _openBlockPicker,
                      child: Text('Selecionar Cor'),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _mailRespController,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        labelText: 'Coloque o Email',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nomeRespController,
                      decoration: InputDecoration(
                        labelText: 'Nome Responsável',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InternationalPhoneNumberInput(
                      onInputChanged: (PhoneNumber number) {
                        numberint = number.phoneNumber;
                      },
                      onInputValidated: (bool value) {},
                      selectorConfig: SelectorConfig(
                        selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                        showFlags: true,
                      ),
                      ignoreBlank: false,
                      autoValidateMode: AutovalidateMode.disabled,
                      selectorTextStyle: TextStyle(color: Colors.black),
                      initialValue: number,
                      textFieldController: _contRespController,
                      formatInput: false,
                      keyboardType: TextInputType.numberWithOptions(
                          signed: true, decimal: true),
                      inputBorder: OutlineInputBorder(),
                      onSaved: (PhoneNumber number) {
                        print(number);
                      },
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Ação do botão...
                      },
                      child: const Text('Criar Usuário'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /*void _emptyFields() async {
    final nomeEmpresa = _nomeEmpresaController.text;
    final equipaResponsavel = _equipaRespController.text;
//Pessoa Responsável
    final nomeResp = _nomeRespController.text;
    final emailResp = _mailRespController.text;
    final contResp = _contRespController.text;

    if (nomeEmpresa.isEmpty ||
        nomeResp.isEmpty ||
        emailResp.isEmpty ||
        contResp.isEmpty) {
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'Preencha todos os campos',
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
        backgroundColor: Colors.red, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } else if (Conf_Pass != pass) {
    } else {
      if (orderv == "User") {
        type = "0";
      } else {
        type = "1";
      }

      CreateEmpresa(name, _passController.text, _logController.text, numberint,
          _mailController.text, type);
      //Adicionar função de criar o user tal e qual ao createTar();

      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: Text(
          'User criado',
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
  }*/
}
