import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_flutter_project/Admin/users.dart';

class AddUserPage extends StatefulWidget {
  @override
  _AddUserPageState createState() => _AddUserPageState();
}

class _AddUserPageState extends State<AddUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _apelidoController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  String _turma = '_______';
  String _role = 'Administrador'; // Default to 'utilizador'
  File? _image;
  dynamic _selectedImage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Utilizador'),
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: 20),
              Text("\nImagem de Perfil\n"),
              GestureDetector(
                  onTap: _getImage,
                  child: CircleAvatar(
                    radius: 50.0,
                    backgroundColor: Color.fromARGB(255, 246, 141, 45),
                    child: ClipOval(
                      child: (_selectedImage != null)
                          ? Image.memory(
                              _selectedImage,
                              fit: BoxFit.cover,
                              height: 100,
                              width: 100,
                            )
                          : Icon(
                              // If users list is null or empty, display a default icon
                              Icons.person,
                              size: 47,
                              color: Colors.white,
                            ),
                    ),
                  )),
              SizedBox(height: 20),
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(labelText: 'Nome'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Insira o nome.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _apelidoController,
                decoration: InputDecoration(labelText: 'Apelido'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Insira o Apelido.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Email'),
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Insira o Email.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Insira a sua Password.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 20),
              TextFormField(
                controller: _passwordConfirmController,
                decoration: InputDecoration(labelText: 'Confirmar Password'),
                obscureText: true,
                validator: (value) {
                  if (value!.isEmpty) {
                    return 'Confirme a Password';
                  }
                  /*if (value != null && value != _passwordController) {
                    return 'Password não coicide';
                  }*/
                  return null;
                },
              ),
              SizedBox(height: 20),
              Text("\nTurma\n"),
              DropdownButton<String>(
                value: _turma,
                items: [
                  '_______',
                  'ANIM23_26',
                  'ANIM22_25',
                  'ANIM21_24',
                  'ELE23_26',
                  'ELE22_25',
                  'ELE21_24',
                  'OPT21_24',
                  'TUR23_26',
                  'TUR22_25',
                  'INF23_26',
                  'INF22_25',
                  'INF21_24',
                  'COM.DIG23_26',
                  'COM.DIG22_25',
                  'COM.DIG21_24',
                  'DESP23_26'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _turma = value!;
                  });
                },
              ),

              SizedBox(height: 20),
              Text("\nPermissão\n"),
              DropdownButton<String>(
                value: _role,
                items: [
                  'Administrador',
                  'Professor',
                  'Funcionária',
                  'Bar',
                  'Aluno'
                ].map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? value) {
                  setState(() {
                    _role = value!;
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      _submitForm();
                    }
                  },
                  child: Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submitForm() async {
    String nome = _nomeController.text;
    String apelido = _apelidoController.text;
    String username = _usernameController.text;
    String password = _passwordController.text;
    String permissao = _role;
    String turma = _turma;

    String? base64Image;
    if (_selectedImage != null) {
      List<int> imageBytes = _selectedImage.buffer.asUint8List();
      base64Image = base64Encode(imageBytes);
    }

    try {
      var response = await http.post(
          Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
          body: {
            'query_param': '2',
            'nome': nome,
            'apelido': apelido,
            'user': username,
            'imagem': base64Image,
            'pwd': password,
            'permissao': permissao,
            'turma': turma,
          });

      if (response.statusCode == 200) {
        dynamic res = json.decode(response.body);
        print(res);
        String teste = res[0].toString();
        print(teste);
        if (teste == "1") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Utilizador já existe na base de dados"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Valor atualizado com sucesso no banco de dados!'),
            ),
          );
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => UserTable()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar valor no banco de dados'),
          ),
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição POST: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar valor no banco de dados'),
        ),
      );
    }
  }

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    dynamic imagefile = await pickedFile!.readAsBytes();

    setState(() {
      _selectedImage = imagefile;
    });
  }
}