import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Admin/addProduto.dart';
import 'package:appbar_epvc/Admin/drawerAdmin.dart';
import 'package:appbar_epvc/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

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
      available: int.parse(json['Qtd']) >= 1 ? true : false,
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
  List<Product> filteredProducts = []; // List for filtered products
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch data when the widget initializes
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('à', 'a')
        .replaceAll('ã', 'a')
        .replaceAll('â', 'a')
        .replaceAll('é', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('õ', 'o')
        .replaceAll('ô', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('Á', 'a')
        .replaceAll('À', 'a')
        .replaceAll('Ã', 'a')
        .replaceAll('Â', 'a')
        .replaceAll('É', 'e')
        .replaceAll('Ê', 'e')
        .replaceAll('Í', 'i')
        .replaceAll('Ó', 'o')
        .replaceAll('Õ', 'o')
        .replaceAll('Ô', 'o')
        .replaceAll('Ú', 'u')
        .replaceAll('Ü', 'u')
        .replaceAll('Ç', 'c');
  }

  void filterProducts(String query) {
    setState(() {
      final normalizedQuery = normalizeText(query);
      filteredProducts = products.where((product) {
        final normalizedName = normalizeText(product.name);
        return normalizedName.contains(normalizedQuery);
      }).toList();
    });
  }

  Future<void> fetchData() async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_Post.php'),
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
        filteredProducts = fetchedProducts; // Initialize filtered products
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
          '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=6&id=$id&nome=$nome&preco=$preco&available=$qtd&categoria=$categoria'),
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
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('lib/assets/epvc.png'),
              ),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Color.fromARGB(255, 255, 255, 255).withOpacity(0.80),
                    ),
                  ),
                ),
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 2,
                              blurRadius: 5,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Pesquisar produto...',
                            prefixIcon: Icon(Icons.search, color: Color.fromARGB(255, 130, 201, 189)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 15),
                          ),
                          onChanged: filterProducts,
                        ),
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? Center(child: CircularProgressIndicator())
                          : ListView.builder(
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                return ProductCard(
                                  product: filteredProducts[index],
                                  onUpdate: (updatedId, updatedProduct) {
                                    updateProduct(updatedId, updatedProduct);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.more_horiz,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 130, 201, 189),
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            onTap: () async {
              final result = await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AddProdutoPage();
                },
              );
              if (result == true) {
                // Refresh the product list
                fetchData();
              }
            },
          ),
        ],
      ),
    );
  }
}

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
  String _categoryValue = '';
  bool _isEditing = false;
  final List<String> _categories = ['Bebidas', 'Café', 'Comidas', 'Snacks', 'Doces', 'Quentes'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _categoryValue = _categories.contains(widget.product.category) ? widget.product.category : 'Comidas';
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
    bool isAvailable = widget.product.quantity >= 1;
    Color statusColor = isAvailable ? Colors.green : Colors.orange;
    String statusText = isAvailable ? 'Disponível' : 'Indisponível';
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
            _isEditing
                ? TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Nome'),
                  )
                : Text(
                    widget.product.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
            SizedBox(height: 4),
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
                ? TextFormField(
                    controller: _quantityController,
                    decoration: InputDecoration(labelText: 'Quantidade'),
                    keyboardType: TextInputType.number,
                  )
                : Row(
                    children: [
                      Icon(Icons.inventory_2, size: 18, color: Colors.blueGrey),
                      SizedBox(width: 6),
                      Text('Quantidade: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(widget.product.quantity.toString(), style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
            SizedBox(height: 4),
            Row(
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
                    items: _categories
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
                        widget.product.quantity = int.parse(_quantityController.text);
                        widget.product.available = widget.product.quantity >= 1;
                        widget.product.category = _categoryValue;
                        widget.onUpdate(widget.product.id, widget.product);
                        _nameController.text = widget.product.name;
                        _priceController.text = widget.product.price.toString();
                        _quantityController.text = widget.product.quantity.toString();
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
    Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=7&id=$id'),
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
