import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Admin/addProduto.dart';
import 'package:appbar_epvc/Admin/drawerAdmin.dart';
import 'package:appbar_epvc/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Product {
  String id; // Assuming your API returns an ID for each product
  String name;
  String description;
  double price;
  int quantity;
  bool available;
  String category;
  String base64Image;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.quantity,
    required this.available,
    required this.category,
    required this.base64Image,
  });

  factory Product.fromJson(dynamic json) {
    return Product(
      id: json['Id'],
      name: json['Nome'],
      description: json['Nome'],
      price: double.parse(json['Preco'].toString()),
      quantity: int.parse(json['Qtd']),
      available: int.parse(json['Qtd']) == 1 ? true : false,
      category: json['Categoria'],
      base64Image: json['Imagem'],
    );
  }
}

class ProdutoPage extends StatefulWidget {
  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProdutoPage> {
  List<Product> products = []; // Initialize with empty list
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch data when the widget initializes
  }

  Future<void> fetchData() async {
    final response = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
      body: {
        'query_param': '4',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> responseBody = json.decode(response.body);
      List<Product> fetchedProducts = responseBody.map((productData) {
        return Product.fromJson(productData);
      }).toList();
      
      setState(() {
        products = fetchedProducts;
        isLoading = false;
      });
    } else {
      throw Exception('Failed to fetch data from API');
    }
  }

  void updateProduct(String id, Product product) async {
    var nome = product.name;
    var preco = product.price;
    var qtd = product.quantity.toString();
    var categoria = product.category;
    var response = await http.get(
      Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=6&id=$id&nome=$nome&preco=$preco&available=$qtd&categoria=$categoria'),
    );
    print(response);
    if (response.statusCode == 200) {
      // Product updated successfully
      print('Product updated successfully');
    } else {
      // Failed to update product
      print('Failed to update product');
    }
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
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();

                // ignore: use_build_context_synchronously
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext ctx) => const LoginForm()));
                ModalRoute.withName('/');
              },
            ),
          ],
        );
      },
    );
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
   /* appBar: AppBar(
      backgroundColor: Color.fromARGB(255, 246, 141, 45),
      title: Text(
        'Produtos',
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () {
            logout(context);
          },
          icon: Icon(
            Icons.logout,
            color: Colors.white, // Definindo a cor como branco
          ),
        ),
      ],
    ),
    drawer: DrawerAdmin(),*/
    body: Stack(
      children: [
       Container(
        width: double.infinity, // Usar toda a largura disponível
        height: double.infinity, // Usar toda a altura disponível
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/assets/epvc.png'), // Caminho para a sua imagem de fundo
            // fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Imagem de fundo
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255)
                      .withOpacity(0.80), // Cor preta com opacidade de 40%
                ),
              ),
            ),
        isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  return ProductCard(
                    product: products[index],
                    onUpdate: (updatedId, updatedProduct) {
                      updateProduct(updatedId, updatedProduct);
                    },
                  );
                },
              ),
      ],
  ))]),
    floatingActionButton: SpeedDial(
      icon: Icons.more_horiz,
      iconTheme: IconThemeData(color: Colors.white),
      backgroundColor: Color.fromARGB(255, 130, 201, 189),
      children: [
        SpeedDialChild(
          child: Icon(Icons.add),
          onTap: () async {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddProdutoPage()),
            );
          },
        ),
        /*SpeedDialChild(
          child: Icon(Icons.recycling),
          onTap: () {},
        ),*/
      ],
    ),
  );}}

class ProductCard extends StatefulWidget {
  final Product product;
  final Function(String, Product) onUpdate;

  ProductCard({required this.product, required this.onUpdate});

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _quantityController;
  String _availability = '';
  String _categoryValue = '';
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _availability = widget.product.available ? 'Disponível' : 'Indisponível';
    _categoryValue = widget.product.category;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor = widget.product.available ? Colors.green : Colors.orange;
    String statusText = widget.product.available ? 'Disponível' : 'Indisponível';
    return Card(
      elevation: 4,
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.memory(
                  base64Decode(widget.product.base64Image),
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _isEditing
                      ? TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(labelText: 'Nome'),
                        )
                      : Row(
                          children: [
                            Icon(Icons.label, size: 18, color: Colors.blueGrey),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(widget.product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                            ),
                          ],
                        ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    border: Border.all(color: statusColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _isEditing ? _availability : statusText,
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            _isEditing
                ? TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(labelText: 'Preço'),
                    keyboardType: TextInputType.number,
                  )
                : Row(
                    children: [
                      Icon(Icons.euro, size: 18, color: Colors.blueGrey),
                      SizedBox(width: 6),
                      Text('Preço: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('${widget.product.price.toStringAsFixed(2).replaceAll('.', ',')}€', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
            SizedBox(height: 4),
            _isEditing
                ? DropdownButtonFormField<String>(
                    value: _availability,
                    items: <String>['Disponível', 'Indisponível']
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? value) {
                      setState(() {
                        _availability = value!;
                      });
                    },
                  )
                : Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: statusColor),
                      SizedBox(width: 6),
                      Text('Estado: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
            SizedBox(height: 4),
            _isEditing
                ? DropdownButtonFormField<String>(
                    value: _categoryValue,
                    items: ['Bebidas', 'Café', 'Comidas', 'Snacks', 'Doces']
                        .map<DropdownMenuItem<String>>((String value) {
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
                  )
                : Row(
                    children: [
                      Icon(Icons.category, size: 18, color: Colors.blueGrey),
                      SizedBox(width: 6),
                      Text('Categoria: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(widget.product.category, style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
            SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(_isEditing ? Colors.green : Color.fromARGB(255, 246, 141, 45)),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    )),
                  ),
                  icon: Icon(_isEditing ? Icons.save : Icons.edit, color: Colors.white),
                  label: Text(_isEditing ? 'Guardar' : 'Editar', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    setState(() {
                      _isEditing = !_isEditing;
                      if (!_isEditing) {
                        widget.product.name = _nameController.text;
                        widget.product.price = double.parse(_priceController.text);
                        widget.product.available = _availability == 'Disponível';
                        widget.product.category = _categoryValue;
                        widget.onUpdate(widget.product.id, widget.product);
                        _nameController.text = widget.product.name;
                        _priceController.text = widget.product.price.toString();
                        _quantityController.text = widget.product.quantity.toString();
                        _availability = widget.product.available ? 'Disponível' : 'Indisponível';
                        _categoryValue = widget.product.category;
                      }
                    });
                  },
                ),
                SizedBox(width: 8),
                ElevatedButton.icon(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.red),
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    )),
                  ),
                  icon: Icon(Icons.delete, color: Colors.white),
                  label: Text('Eliminar', style: TextStyle(color: Colors.white)),
                  onPressed: () {
                    removeProduct(widget.product.id);
                    setState(() {});
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

void removeProduct(String id) async {
  var response = await http.get(
    Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=7&id=$id'),
    //body: jsonEncode(product.toJson()),
  );
  print(response);
  if (response.statusCode == 200) {
    // Product updated successfully
    print('Product Remove Successfully');
  } else {
    // Failed to update product
    print('Failed to Remove product');
  }
}
