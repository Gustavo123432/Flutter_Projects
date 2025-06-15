import 'dart:async';
import 'dart:convert';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Bar/drawerBar.dart';
import 'package:appbar_epvc/login.dart';
import 'package:appbar_epvc/models/product.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Product> filteredProducts =
    []; // Assuming this is where filtered products will be stored

class ProdutoPageBar extends StatefulWidget {
  @override
  _ProdutoPageBarState createState() => _ProdutoPageBarState();
}

class _ProdutoPageBarState extends State<ProdutoPageBar> {
  List<Product> products = [];
  List<Product> filteredProducts = []; // Initialize filteredProducts
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  late StreamController<List<dynamic>> _streamController;

  String selectedSortOption = 'Ascending';
  double? minPrice;
  double? maxPrice;
  String normalize(String input) {
    return removeDiacritics(input)
        .toLowerCase(); // Remove diacritics and convert to lowercase
  }

  @override
  void initState() {
    super.initState();
    _streamController =
        StreamController<List<dynamic>>(); // Initialize StreamController
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {'query_param': '4'},
      );

      if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);
        List<Product> fetchedProducts = responseBody.map((productData) {
          return Product.fromJson(productData);
        }).toList();

        setState(() {
          products = fetchedProducts;
          filteredProducts = List.from(products);
          isLoading = false;
        });
      } else {
        throw Exception(
            'Erro ao carregar o produto\nPor favor contacte o responsável!');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print('Error: $e');
    }
  }

  void _showFilterDialog() {
    String? selectedCategory;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtrar por Categoria'),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return DropdownButtonFormField<String>(
                value: selectedCategory,
                onChanged: (newValue) {
                  setState(() {
                    selectedCategory = newValue;
                  });
                },
                items: products
                    .map((product) => product.category)
                    .toSet()
                    .toList()
                    .map((category) {
                  return DropdownMenuItem<String>(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
              );
            },
          ),
          actions: [
            TextButton(
              child: Text('Cancelar'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Filtrar'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                setState(() {
                  filteredProducts.clear();
                  products.forEach((product) {
                    if (product.category == selectedCategory) {
                      filteredProducts.add(product);
                    }
                  });
                });
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Mostrar Todos'),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              onPressed: () {
                setState(() {
                  filteredProducts = List.from(products);
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void updateProduct(String id, bool newAvailability) async {
    var availableValue = newAvailability ? "1" : "0";
    var response = await http.get(
      Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=18&op=1&id=$id&qtd=$availableValue'),
    );
    if (response.statusCode == 200) {
      setState(() {
        var index = products.indexWhere((product) => product.id == id);
        if (index != -1) {
          products[index].available = newAvailability;
        }
      });
    } else {
      print('Erro ao atualizar o produto\nPor favor contacte o responsável!');
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
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (BuildContext ctx) => LoginForm(),
                  ),
                );
                ModalRoute.withName('/');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    await fetchData();
  }

  void _filterItemsSearch() {
    final query = normalize(_searchController.text);
    setState(() {
      filteredProducts = products.where((item) {
        return normalize(item.name).contains(query);
      }).toList();
    });
  }

  void updateProductQuantity(String id, int quantity) async {
    var response = await http.get(
      Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=18&id=$id&qtd=$quantity'),
    );
    if (response.statusCode == 200) {
      setState(() {
        var index = products.indexWhere((product) => product.id == id);
        if (index != -1) {
          products[index].quantity = quantity;
          products[index].available = quantity >= 1;
        }
      });
    } else {
      print('Erro ao atualizar a quantidade do produto\nPor favor contacte o responsável!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
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
              color: Colors.white,
            ),
          ),
        ],
      ),
      drawer: DrawerBar(),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            labelText: 'Procurar...',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            _filterItemsSearch(); // Call filter on text change
                          },
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.filter_list, color: Colors.orange),
                      onPressed: _showFilterDialog,
                    ),
                  ],
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: ListView.builder(
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        return ProductCard(
                          product: filteredProducts[index],
                          onUpdate: (newAvailability) {
                            updateProduct(
                                filteredProducts[index].id, newAvailability);
                          },
                          onQuantityChange: (id, quantity) {
                            updateProductQuantity(id, quantity);
                          },
                        );
                      },
                    ),
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
            child: Icon(Icons.filter_list),
            onTap: () async {
              _showFilterDialog();
            },
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Product product;
  final Function(bool) onUpdate;
  final Function(String, int) onQuantityChange;

  ProductCard({
    required this.product,
    required this.onUpdate,
    required this.onQuantityChange,
  });

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  late TextEditingController _quantityController;
  late TextEditingController _slideQuantityController;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController(text: widget.product.quantity.toString());
    _slideQuantityController = TextEditingController(text: widget.product.quantity.toString());
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _slideQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Update availability based on quantity
    bool isAvailable = widget.product.quantity >= 1;
    
    return Dismissible(
      key: Key(widget.product.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Color.fromARGB(255, 130, 201, 189),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.0),
        child: Icon(
          Icons.swap_horizontal_circle_outlined,
          color: Colors.white,
        ),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Atualizar Quantidade"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _slideQuantityController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Nova Quantidade',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        child: Text("Cancelar"),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      ElevatedButton(
                        child: Text("Guardar"),
                        onPressed: () {
                          int? newQuantity = int.tryParse(_slideQuantityController.text);
                          if (newQuantity != null && newQuantity >= 0) {
                            widget.onQuantityChange(widget.product.id, newQuantity);
                            Navigator.of(context).pop(false);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Por favor, insira uma quantidade válida'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Card(
        margin: EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.memory(
                    base64Decode(widget.product.base64Image),
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Preço: ${widget.product.price.toStringAsFixed(2).replaceAll('.', ',')}€',
                          style: TextStyle(fontSize: 14),
                        ),
                        Text(
                          'Estado: ${isAvailable ? 'Disponível' : 'Indisponível'}',
                          style: TextStyle(
                            fontSize: 14,
                            color: isAvailable ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          'Categoria: ${widget.product.category}',
                          style: TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Quantidade:',
                    style: TextStyle(fontSize: 14),
                  ),
                  SizedBox(width: 8),
                  Container(
                    width: 60,
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      onChanged: (value) {
                        int? quantity = int.tryParse(value);
                        if (quantity != null && quantity >= 0) {
                          widget.onQuantityChange(widget.product.id, quantity);
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: isAvailable ? () {
                      // Show purchase dialog
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Confirmar Compra'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Produto: ${widget.product.name}'),
                                SizedBox(height: 8),
                                Text('Preço: ${widget.product.price.toStringAsFixed(2).replaceAll('.', ',')}€'),
                                SizedBox(height: 8),
                                Text('Quantidade: ${widget.product.quantity}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  // Here you would implement the purchase logic
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Produto adicionado ao carrinho'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color.fromARGB(255, 246, 141, 45),
                                  foregroundColor: Colors.white,
                                ),
                                child: Text('Confirmar'),
                              ),
                            ],
                          );
                        },
                      );
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAvailable ? Color.fromARGB(255, 246, 141, 45) : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('Comprar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: ProdutoPageBar(),
  ));
}

class AddProdutoPageBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Implement your add product page UI here
    return Container();
  }
}
