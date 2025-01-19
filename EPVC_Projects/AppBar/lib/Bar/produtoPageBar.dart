import 'dart:async';
import 'dart:convert';
import 'package:diacritic/diacritic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Bar/drawerBar.dart';
import 'package:my_flutter_project/login.dart';
import 'package:my_flutter_project/models/product.dart';
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
          return Product(
            id: productData['Id'] ?? 0,
            name: productData['Nome'] ?? '',
            description: productData['Nome'] ?? '',
            price:
                double.tryParse(productData['Preco']?.toString() ?? '0') ?? 0.0,
            quantity: int.tryParse(productData['Qtd']?.toString() ?? '0') ?? 0,
            available: productData['Qtd'] != null &&
                int.tryParse(productData['Qtd']) == 1,
            category: productData['Categoria'] ?? '',
            base64Image: productData['Imagem'] ?? '',
          );
        }).toList();

        setState(() {
          products = fetchedProducts;
          filteredProducts = List.from(products); // Initialize filteredProducts
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
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
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Filtrar'),
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
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=18&id=$id&qtd=$availableValue'),
    );
    if (response.statusCode == 200) {
      setState(() {
        var index = products.indexWhere((product) => product.id == id);
        if (index != -1) {
          products[index].available = newAvailability;
        }
      });
    } else {
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
                      icon: Icon(Icons.filter_list),
                      onPressed: _showFilterDialog,
                    ),
                  ],
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      return ProductCard(
                        product: filteredProducts[index],
                        onUpdate: (newAvailability) {
                          updateProduct(
                              filteredProducts[index].id, newAvailability);
                        },
                      );
                    },
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

class ProductCard extends StatelessWidget {
  final Product product;
  final Function(bool) onUpdate;

  ProductCard({required this.product, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(product.id),
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
              title: Text("Estado do Produto"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text("Disponível"),
                    onTap: () {
                      onUpdate(true);
                      Navigator.of(context).pop(false);
                    },
                  ),
                  ListTile(
                    title: Text("Indisponível"),
                    onTap: () {
                      onUpdate(false);
                      Navigator.of(context).pop(false);
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
      child: Card(
        margin: EdgeInsets.all(8.0),
        child: ListTile(
          leading: Image.memory(
            base64Decode(product.base64Image),
            width: 50,
            height: 50,
            fit: BoxFit.cover,
          ),
          title: Text(product.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Preço: ${product.price.toStringAsFixed(2).replaceAll('.', ',')}€'),
              Text(
                  'Estado: ${product.available ? 'Disponível' : 'Indisponível'}'),
              Text('Categoria: ${product.category}'),
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
