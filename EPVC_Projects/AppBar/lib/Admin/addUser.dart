import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appbar_epvc/Admin/users.dart';
import 'package:appbar_epvc/Drawer/drawer.dart';

class AddUserDialog extends StatefulWidget {
  @override
  _AddUserDialogState createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
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
  List<String> _turmas = []; // List to store fetched turmas

  @override
  void initState() {
    super.initState();
    _loadTurmas();
  }

  Future<void> _loadTurmas() async {
    try {
      List<String> turmas = await _fetchTurmasFromAPI();
      setState(() {
        _turmas = turmas;
      });
    } catch (e) {
      print('Error loading turmas: $e');
      // Here you can display an error message to the user or take other appropriate action.
    }
  }

  Future<List<String>> _fetchTurmasFromAPI() async {
    try {
      final response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=20'));
      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        List<String> turmas =
            responseData.map((data) => data['Turma'] as String).toList();
        return turmas;
      } else {
        throw Exception('Failed to load turmas from API');
      }
    } catch (e) {
      throw Exception('Error fetching turmas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      content: SingleChildScrollView(
        child: Container(
          width: 600,
          child: Padding(
            padding: EdgeInsets.all(1.0),
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
                    decoration:
                        InputDecoration(labelText: 'Confirmar Password'),
                    obscureText: true,
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Confirme a Password';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20),
                  Text("\nTurma\n"),
                  DropdownButton<String>(
                    value: _turma,
                    items: _turmas.map((String value) {
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
                  Row(children: [
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
                    SizedBox(
                      width: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context); // Closes the dialog
                        },
                        child: Text('Cancel'),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
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
    if (base64Image != null) {
      try {
        var response = await http.post(
            Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
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
                content:
                    Text('Utilizador criado com sucesso no base de dados!'),
              ),
            );
          }
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AdminDrawer(currentPage: UserTable(), numero: 1)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar utilizador na base de dados'),
            ),
          );
        }
      } catch (e) {
        print('Erro ao fazer a requisição POST: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar utilizador na base de dados'),
          ),
        );
      }
    } else if (base64Image == null) {
      try {
        var response = await http.post(
            Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
            body: {
              'query_param': '2.1',
              'nome': nome,
              'apelido': apelido,
              'user': username,
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
                content:
                    Text('Utilizador criado com sucesso na base de dados!'),
              ),
            );
          }
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) =>
                    AdminDrawer(currentPage: UserTable(), numero: 1)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar utilizador na base de dados'),
            ),
          );
        }
      } catch (e) {
        print('Erro ao fazer a requisição POST: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar utilizador na base de dados'),
          ),
        );
      }
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

void showAddUserDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AddUserDialog();
    },
  );
}
