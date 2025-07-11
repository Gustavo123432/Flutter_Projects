import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appbar_epvc/Admin/users.dart';
import 'package:appbar_epvc/Drawer/drawer.dart';
import 'package:crypto/crypto.dart';

// Function to generate random password
String generateRandomPassword() {
  // Use only numbers for easier password
  const String chars = '0123456789';
  final Random random = Random.secure();
  final int length = 8; // Password length of 8 digits

  return List.generate(length, (index) {
    return chars[random.nextInt(chars.length)];
  }).join();
}

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
  final _nifController = TextEditingController();
  String _turma = '_______';
  String _role = 'Administrador'; // Default to 'utilizador'
  File? _image;
  dynamic _selectedImage;
  List<String> _turmas = []; // List to store fetched turmas
  bool _hasSaldo = false; // New variable for Saldo checkbox
  bool _useDefaultPassword = true; // New variable for default password option
  String? _generatedPassword; // Store the generated password

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
        borderRadius: BorderRadius.circular(20),
      ),
      content: SingleChildScrollView(
        child: Container(
          width: 600,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Center(
                    child: Text(
                      "Adicionar Utilizador",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 130, 201, 189),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Center(
                    child: GestureDetector(
                      onTap: _getImage,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Color.fromARGB(255, 246, 141, 45),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50.0,
                              backgroundColor: Colors.white,
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
                                        color:
                                            Color.fromARGB(255, 246, 141, 45),
                                      ),
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Clique para adicionar uma imagem',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  TextFormField(
                    controller: _nomeController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.person,
                          color: Color.fromARGB(255, 130, 201, 189)),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Insira o nome.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _apelidoController,
                    decoration: InputDecoration(
                      labelText: 'Apelido',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.person_outline,
                          color: Color.fromARGB(255, 130, 201, 189)),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Insira o Apelido.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.email,
                          color: Color.fromARGB(255, 130, 201, 189)),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Insira o Email.';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CheckboxListTile(
                      title: Text('Usar Password Default (epvc)'),
                      value: _useDefaultPassword,
                      activeColor: Color.fromARGB(255, 246, 141, 45),
                      onChanged: (bool? value) {
                        setState(() {
                          _useDefaultPassword = value ?? true;
                        });
                      },
                    ),
                  ),
                  if (!_useDefaultPassword) ...[
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.lock,
                            color: Color.fromARGB(255, 130, 201, 189)),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Insira a sua Password.';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 15),
                    TextFormField(
                      controller: _passwordConfirmController,
                      decoration: InputDecoration(
                        labelText: 'Confirmar Password',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        prefixIcon: Icon(Icons.lock_outline,
                            color: Color.fromARGB(255, 130, 201, 189)),
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value!.isEmpty) {
                          return 'Confirme a Password';
                        }
                        if (value != _passwordController.text) {
                          return 'As passwords não coincidem';
                        }
                        return null;
                      },
                    ),
                  ],
                  SizedBox(height: 15),
                  TextFormField(
                    controller: _nifController,
                    decoration: InputDecoration(
                      labelText: 'NIF (Opcional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      prefixIcon: Icon(Icons.badge,
                          color: Color.fromARGB(255, 130, 201, 189)),
                    ),
                  ),
                  SizedBox(height: 15),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CheckboxListTile(
                      title: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Color.fromARGB(255, 246, 141, 45),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Tem Saldo'),
                        ],
                      ),
                      value: _hasSaldo,
                      activeColor: Color.fromARGB(255, 246, 141, 45),
                      onChanged: (bool? value) {
                        setState(() {
                          _hasSaldo = value ?? false;
                        });
                      },
                    ),
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: _turma,
                      isExpanded: true,
                      underline: SizedBox(),
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
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: DropdownButton<String>(
                      value: _role,
                      isExpanded: true,
                      underline: SizedBox(),
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
                  ),
                  SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            _submitForm();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 246, 141, 45),
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Adicionar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 20),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color.fromARGB(255, 130, 201, 189),
                          padding: EdgeInsets.symmetric(
                              horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Cancelar',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
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

    // Generate random password if using default
    if (_useDefaultPassword) {
      _generatedPassword = generateRandomPassword();
    }

    String password =
        _useDefaultPassword ? _generatedPassword! : _passwordController.text;
    // Encrypt password with crypto MD5
    String encryptedPassword = md5.convert(utf8.encode(password)).toString();
    print(password);
    print(encryptedPassword);
    String permissao = _role;
    String turma = _turma;
    String nif = _nifController.text.isEmpty ? '0' : _nifController.text;
    String saldo = _hasSaldo ? '1' : '0';
    String defaultPWD = _useDefaultPassword ? '1' : '0';

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
              'pwd': encryptedPassword,
              'permissao': permissao,
              'turma': turma,
              'nif': nif,
              'saldo': saldo,
              'defaultPWD': defaultPWD,
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
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            await sendEmailUser();
            // Show the generated password in the success message if using default
            String successMessage = _useDefaultPassword
                ? 'Utilizador criado com sucesso na base de dados!\nPassword gerada: $_generatedPassword'
                : 'Utilizador criado com sucesso na base de dados!';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(successMessage),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 5),
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
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Erro ao fazer a requisição POST: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erro ao criar utilizador. Por favor, tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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
              'pwd': encryptedPassword,
              'permissao': permissao,
              'turma': turma,
              'nif': nif,
              'saldo': saldo,
              'defaultPWD': defaultPWD,
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
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
          } else {
            var response = await http.get(
              Uri.parse(
                  'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=14.2&email=$username&pwd=$_generatedPassword'),
            );
            dynamic res = json.decode(response.body);
            if (response.statusCode == 200 && res['success'] == true) {
              String successMessage = _useDefaultPassword
                  ? 'Utilizador criado com sucesso na base de dados!\nPassword gerada: $_generatedPassword'
                  : 'Utilizador criado com sucesso na base de dados!';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(successMessage),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 5),
                ),
              );
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) =>
                      AdminDrawer(currentPage: UserTable(), numero: 1)),
            );
          }

          // Show the generated password in the success message if using default
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao criar utilizador na base de dados'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Erro ao fazer a requisição POST: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Erro ao criar utilizador. Por favor, tente novamente.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
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

  Future<void> sendEmailUser() async {
    try {
      // Get the non-encrypted password
      String password =
          _useDefaultPassword ? _generatedPassword! : _passwordController.text;

      // Call the API to send email with password
      var response = await http.get(
        Uri.parse(
            'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=14.2&email=${_usernameController.text}&pwd=$password'),
      );

      if (response.statusCode == 200) {
        print('Email sent successfully');
      } else {
        print('Failed to send email');
      }
    } catch (e) {
      print('Error sending email: $e');
    }
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
