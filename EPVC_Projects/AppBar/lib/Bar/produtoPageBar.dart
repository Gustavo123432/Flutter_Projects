import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Bar/drawerBar.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Product> filteredProducts = []; // Assuming this is where filtered products will be stored

class Product {
  String id;
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
}

class ProdutoPageBar extends StatefulWidget {
  @override
  _ProdutoPageBarState createState() => _ProdutoPageBarState();
}

class _ProdutoPageBarState extends State<ProdutoPageBar> {
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final response = await http.post(
      Uri.parse('http://appbar.epvc.pt/API/appBarAPI_Post.php'),
      body: {
        'query_param': '4',
      },
    );
    if (response.statusCode == 200) {
      List<dynamic> responseBody = json.decode(response.body);
      List<Product> fetchedProducts = [];
      responseBody.forEach((productData) {
        fetchedProducts.add(Product(
          id: productData['Id'],
          name: productData['Nome'],
          description: productData['Nome'],
          price: double.parse(productData['Preco'].toString()),
          quantity: int.parse(productData['Qtd']),
          available: int.parse(productData['Qtd']) == 1 ? true : false,
          category: productData['Categoria'],
          base64Image: productData['Imagem'],
        ));
      });
      setState(() {
        products = fetchedProducts;
        isLoading = false;
      });
    } else {
      throw Exception('Erro ao Obter Produtos');
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
                  // Update state to reflect the filtering
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
                  // If "Mostrar Todos" is pressed, we display all products again
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
      Uri.parse('http://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=18&id=$id&qtd=$availableValue'),
    );
    if (response.statusCode == 200) {
      //print('Product updated successfully');
      // Atualize a lista de produtos após a atualização bem-sucedida, se necessário
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
          : ListView.builder(
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                return ProductCard(
                  product: filteredProducts[index],
                  onUpdate: (newAvailability) {
                    updateProduct(filteredProducts[index].id, newAvailability);
                  },
                );
              },
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
              Text('Estado: ${product.available ? 'Disponível' : 'Indisponível'}'),
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


