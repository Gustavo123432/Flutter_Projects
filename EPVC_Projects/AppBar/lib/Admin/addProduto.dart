import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appbar_epvc/Admin/produtoPage.dart';
import 'package:flutter/services.dart';
import '../config/app_config.dart';

class AddProdutoPage extends StatefulWidget {
  @override
  _AddProdutoPageState createState() => _AddProdutoPageState();
}

class _AddProdutoPageState extends State<AddProdutoPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _precoController = TextEditingController();
  final _quantidadeController = TextEditingController();
  String _categoryValue = 'Comidas';
  dynamic _selectedImage;
  File? _image;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Text(
                    "Adicionar Produto",
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
                                      Icons.add_photo_alternate,
                                      size: 47,
                                      color: Color.fromARGB(255, 246, 141, 45),
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
                    labelText: 'Nome do Produto',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.label, color: Color.fromARGB(255, 130, 201, 189)),
                  ),
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Insira o nome do produto.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _precoController,
                  decoration: InputDecoration(
                    labelText: 'Preço',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.euro, color: Color.fromARGB(255, 130, 201, 189)),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*[,|\.]?\d*')),
                  ],
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Insira o preço.';
                    }
                    String normalized = value.replaceAll(',', '.');
                    if (double.tryParse(normalized) == null) {
                      return 'Insira um preço válido.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                TextFormField(
                  controller: _quantidadeController,
                  decoration: InputDecoration(
                    labelText: 'Quantidade',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    prefixIcon: Icon(Icons.inventory_2, color: Color.fromARGB(255, 130, 201, 189)),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value!.isEmpty) {
                      return 'Insira a quantidade.';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 15),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: DropdownButton<String>(
                    value: _categoryValue,
                    isExpanded: true,
                    underline: SizedBox(),
                    items: ['Bebidas', 'Café', 'Comidas', 'Snacks', 'Doces', 'Quentes']
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
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
                        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
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
    );
  }

  Future<void> _getImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImage = bytes;
      });
    }
  }

  void _submitForm() async {
    String nome = _nomeController.text;
    String preco = _precoController.text;
    String quantidade = _quantidadeController.text;
    String categoria = _categoryValue;

    String? base64Image;
    if (_selectedImage != null) {
      base64Image = base64Encode(_selectedImage);
    }

    try {
      var response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_Post.php'),
        body: {
          'query_param': '5',
          'nome': nome,
          'preco': preco,
          'qtd': quantidade,
          'categoria': categoria,
          'imagem': base64Image ?? '',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Produto adicionado com sucesso!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate success
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao adicionar produto'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao adicionar produto: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
