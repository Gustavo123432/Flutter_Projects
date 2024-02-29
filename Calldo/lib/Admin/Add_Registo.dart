import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:Calldo/Admin/registo.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RegisterCallForm extends StatefulWidget {
  @override
  _RegisterCallFormState createState() => _RegisterCallFormState();
}

class _RegisterCallFormState extends State<RegisterCallForm> {
  dynamic users;
  // Define controllers for text fields
  DateTime? _selectedDate;
  final TextEditingController _dataController = TextEditingController();
  final TextEditingController _horaInicioController = TextEditingController();
  final TextEditingController _horaFimController = TextEditingController();
  final TextEditingController _descricaoController = TextEditingController();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2022),
      lastDate: DateTime(2025),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dataController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}"; // Define o valor do controlador de texto com a data selecionada no formato desejado
      });
    }
  }

  // Variables to store the selected values from dropdowns
  String _selectedPerfil = '';
  String _selectedLocal = '';
  List<dynamic> tableUsers = [];
  String _selectedCentroCusto = '';
  List<dynamic> perfil = [''];
  List<String> _perfil = [''];
  List<String> _local = [];
  List<dynamic> local = [];
  List<String> _ccp = [];
  List<dynamic> ccp = [];
  List<dynamic> tecnico = [];

  @override
  void initState() {
    super.initState();
    getCCP();
    getLocal();
    getPerfil();
    UserInfo();
    UserInfo();
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://services.interagit.com/registarCallAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    }
  }

  // Function to fetch data from database
  void createRegisto() async {
    String data = _dataController.text;
    String horaInicio = _horaInicioController.text;
    String horaFIm = _horaFimController.text;
    String descricao = _descricaoController.text;
    String ccp = _selectedCentroCusto;
    String local = _selectedLocal;
    String perfil = _selectedPerfil;
    String tecnico = users[0]['IdUser'];

    for (int i = 0; i < _perfil.length; i++) {
      if (perfil == _perfil[i]) {
        int teste = i + 1;
        perfil = teste.toString();
        break;
      }
    }
    for (int i = 0; i < _ccp.length; i++) {
      if (ccp == _ccp[i]) {
        int teste = i + 1;
        ccp = teste.toString();
        break;
      }
    }
    for (int i = 0; i < _local.length; i++) {
      if (local == _local[i]) {
        int teste = i + 1;
        local = teste.toString();
        break;
      }
    }
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=7&data=$data&horaI=$horaInicio&horaF=$horaFIm&tecnico=$tecnico&perfil=$perfil&local=$local&ccp=$ccp&descricao=$descricao '));

    if (response.statusCode == 200) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registo Registado com Sucesso'),
          ),
        );
        // Navega para outra tela após exibir a SnackBar
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  Registo()), // Substitua MinhaNovaTela pelo nome da sua nova tela
        );
      });
    }
  }

  void getPerfil() async {
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=10'));

    if (response.statusCode == 200) {
      setState(() {
        perfil = json.decode(response.body);
        _perfil = perfil.map((item) => item.toString()).toSet().toList();
        _selectedPerfil = _perfil.isNotEmpty
            ? _perfil[0]
            : ''; // Definir o valor inicial do dropdown
      });
    }
  }

  void getCCP() async {
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=13'));

    if (response.statusCode == 200) {
      setState(() {
        ccp = json.decode(response.body);
        _ccp = ccp.map((item) => item.toString()).toSet().toList();
        _selectedCentroCusto = _ccp.isNotEmpty
            ? _ccp[0]
            : ''; // Definir o valor inicial do dropdown
      });
    }
  }

  void getLocal() async {
    var response = await http.get(Uri.parse(
        'https://services.interagit.com/registarCallAPI_GET.php?query_param=11'));

    if (response.statusCode == 200) {
      setState(() {
        local = json.decode(response.body);
        _local = local.map((item) => item.toString()).toSet().toList();
        _selectedLocal = _local.isNotEmpty
            ? _local[0]
            : ''; // Definir o valor inicial do dropdown
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registar Chamada'),
        titleTextStyle: TextStyle(color: Colors.white, fontSize: 24),
        backgroundColor: Colors.red,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              readOnly: true, // Impede que o usuário digite manualmente
              controller: _dataController,
              onTap: () => _selectDate(
                  context), // Abre o calendário quando o campo de texto é clicado
              decoration: InputDecoration(labelText: 'Data: 2024-03-12'),
            ),
            TextField(
              controller: _horaInicioController,
              decoration: InputDecoration(labelText: 'Hora Início'),
            ),
            TextField(
              controller: _horaFimController,
              decoration: InputDecoration(labelText: 'Hora Fim'),
            ),
            TextField(
              controller: _descricaoController,
              decoration: InputDecoration(labelText: 'Descrição'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedPerfil,
              onChanged: (value) {
                setState(() {
                  _selectedPerfil = value!;
                });
              },
              items: _perfil.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Perfil'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedCentroCusto,
              onChanged: (value) {
                setState(() {
                  _selectedCentroCusto = value!;
                });
              },
              items: _ccp.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Centro Custo'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedLocal,
              onChanged: (value) {
                setState(() {
                  _selectedLocal = value!;
                });
              },
              items: _local.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              decoration: InputDecoration(labelText: 'Local'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                createRegisto();
              },
              child: Text('Register'),
            ),
          ],
        ),
      ),
    );
  }
}
