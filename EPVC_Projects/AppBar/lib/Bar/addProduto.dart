import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_flutter_project/Admin/produtoPage.dart';


class AddProdutoPageBar extends StatefulWidget {
  @override
  _AddProdutoPageBarState createState() => _AddProdutoPageBarState();
}

class _AddProdutoPageBarState extends State<AddProdutoPageBar> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  String? _role = 'Disponível'; // Default to 'utilizador'
  dynamic _selectedImage;
  String _categoryValue = 'Comidas';
  //Uint8List? _selectedImage;
File? _image;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Adicionar Produto'),
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
        Text("\nImagem de Produto\n"),
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
          ),
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: _nomeController,
          decoration: InputDecoration(labelText: 'Nome'),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Insira o Nome do Produto.';
            }
            return null;
          },
        ),
        DropdownButton<String>(
          value: _categoryValue,
          items: ['Bebidas', 'Café', 'Comidas', 'Snacks']
              .map((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
            );
          }).toList(),
          onChanged: (String? value) {
            setState(() {
              _categoryValue = value!;
            });
          },
        ),
        TextFormField(
          controller: _precoController,
          decoration: InputDecoration(labelText: 'Preço (0,70)'),
          validator: (value) {
            if (value!.isEmpty) {
              return 'Insira o Preço ';
            }
            return null;
          },
        ),
        
        ListTile(
          title: Text('Disponível'),
          leading: Radio(
            value: 'Disponível',
            groupValue: _role,
            onChanged: (value) {
              setState(() {
                _role = value as String?;
              });
            },
          ),
        ),
        ListTile(
          title: Text('Indisponível'),
          leading: Radio(
            value: 'Indisponível',
            groupValue: _role,
            onChanged: (value) {
              setState(() {
                _role = value as String?;
              });
            },
          ),
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
),),);
  }


  void _submitForm() async {
    String nome = _nomeController.text;
    String categoria = _categoryValue;
    String preco = _precoController.text;
    String permissao = _role.toString();

    String? base64Image;
    if (_selectedImage != null) {
      List<int> imageBytes = _selectedImage.buffer.asUint8List();
      base64Image = base64Encode(imageBytes);
    }

    try {
      var response = await http.post(
          Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
          body: {
            'query_param': '8',
            'nome': nome,
            'categoria': categoria,
            'qtd': _role,
            'preco': preco.replaceAll(',', '.'),
            'imagem': base64Image,
            'permissao': permissao,
          });

      if (response.statusCode == 200) {
        dynamic res = json.decode(response.body);
        String teste = res[0].toString();
        if (teste == "1") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Produto já existe na base de dados"),
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
          MaterialPageRoute(builder: (context) => ProdutoPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar valor na base de dados'),
          ),
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição POST: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar valor na base de dados'),
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
