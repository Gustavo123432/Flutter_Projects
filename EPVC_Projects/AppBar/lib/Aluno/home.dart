import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Aluno/drawerHome.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:intl/intl.dart';
import 'package:diacritic/diacritic.dart'; // Import the diacritic package
import 'package:my_flutter_project/SIBS/sibs_service.dart';
import '../SIBS/mbway_waiting_page.dart';
import '../SIBS/order_confirmation_page.dart';
import '../SIBS/mbway_phone_page.dart';

void main() {
  runApp(HomeAlunoMain());
}

List<Map<String, dynamic>> cartItems =
    []; // Lista global para armazenar os itens no carrinho
List<Map<String, dynamic>> recentBuysMapped = [];
List<Map<String, dynamic>> data = [];
TextEditingController _searchController = TextEditingController();
List<Map<String, dynamic>> allProducts =
    []; // Lista para armazenar todos os produtos
List<Map<String, dynamic>> filteredProducts = [];

class HomeAlunoMain extends StatelessWidget {
  final String? message; // Mensagem opcional

  HomeAlunoMain({this.message});
  @override
  Widget build(BuildContext context) {
    // Exibe a mensagem, se existir
    if (message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message!)),
        );
      });
    }

    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blueGrey, // Define o tema da aplicação
      ),
      home: Scaffold(
        body: HomeAluno(), // Substitua pelo widget que desejar
      ),
    );
  }
}

class HomeAluno extends StatefulWidget {
  @override
  _HomeAlunoState createState() => _HomeAlunoState();
}

class _HomeAlunoState extends State<HomeAluno> {
  List<dynamic> recentBuys = [];
  dynamic checkquantidade;
  var contador = 1;
  bool _isSearching = false;
  dynamic users;

  @override
  void initState() {
    super.initState();
    UserInfo();
    _getAllProducts();
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
        viewRecent(users);
      });
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

  void CheckQuantidade(String productName) async {
    // Remove double quotes from the product name
    String productNamee = productName.replaceAll('"', '');

    var response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=8&nome=$productNamee'));

    if (response.statusCode == 200) {
      setState(() {
        // Cast the decoded JSON objects to List<Map<String, dynamic>>
        data = json.decode(response.body).cast<Map<String, dynamic>>();
        //print(json.decode(response.body));
        if (data.isNotEmpty) {
          //print(quantidadeDisponivel);
        } else {
          print('Data is empty');
        }
      });
    }
  }

  Future<void> viewRecent(dynamic userr) async {
    try {
      if (userr != null) {
        for (var userData in userr) {
          var user = userData['Email'];
          var response = await http.post(
            Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
            body: {
              'query_param': '7',
              'user': user,
            },
          );

          if (response.statusCode == 200) {
            setState(() {
              recentBuys = json.decode(response.body);
              recentBuysMapped = recentBuys.map((productString) {
                return productString as Map<String, dynamic>;
              }).toList();
            });
          } else {
            throw Exception(
                'Erro ao enviar pedido para a API: ${response.statusCode}');
          }
        }
      } else {
        print('Usuários não carregados ainda');
      }
    } catch (e) {
      print('Erro ao enviar pedidos para a API');
    }
  }

  void _getAllProducts() async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '4',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);

        // Explicitly cast each item to Map<String, dynamic>
        allProducts =
            jsonData.map((item) => item as Map<String, dynamic>).toList();

        setState(() {}); // Trigger UI update
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print("Erro ao enviar pedidos para a API: $e");
    }
  }

  void _filterProducts(String query) {
    setState(() {
      if (query.isNotEmpty) {
        _isSearching = true;
        // Filtra a lista de produtos com base na pesquisa
        filteredProducts = allProducts
            .where((product) => product['Nome']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      } else {
        _isSearching = false;
        filteredProducts = List.from(allProducts);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: MaterialApp(
            home: Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShoppingCartPage(),
                    ),
                  );
                },
                icon: Icon(Icons.shopping_cart),
              ),
            ],
          ),
          drawer: DrawerHome(),
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 20),
              Container(
                margin: EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
                child: Text(
                  "Comprados Recentemente",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.symmetric(vertical: 5.0),
                height: 100.0,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: recentBuysMapped.length,
                  itemBuilder: (context, index) {
                    var product = recentBuysMapped[index];
                    var title = product['Descricao'];
                    var price = product['Preco'].toString();
                    var imageBase64 = product['Imagem'];

                    return buildProductSection(
                      imagePath: imageBase64,
                      title: title,
                      price: price,
                    );
                  },
                ),
              ),
              Container(
                margin: EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 16.0,
                ),
                child: Text(
                  "Categorias",
                  style: TextStyle(
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[900],
                  ),
                ),
              ),
              SizedBox(height: 15),
              Expanded(
                child: Container(
                  child: GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, // Number of cards per row
                      childAspectRatio: 1, // Adjust the aspect ratio as needed
                      crossAxisSpacing: 10, // Space between columns
                      mainAxisSpacing: 10, // Space between rows
                    ),
                    itemCount: 6, // Total number of items
                    itemBuilder: (context, index) {
                      switch (index) {
                        case 0:
                          return buildCategoryCard(
                            title: 'Bebidas',
                            backgroundImagePath: 'lib/assets/bebida.png',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryPage(
                                    title: 'Bebidas',
                                  ),
                                ),
                              );
                            },
                          );
                        case 1:
                          return buildCategoryCard(
                            title: 'Quentes',
                            backgroundImagePath: 'lib/assets/cafe.JPG',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryPage(
                                    title: 'Quentes',
                                  ),
                                ),
                              );
                            },
                          );
                        case 2:
                          return buildCategoryCard(
                            title: 'Comidas',
                            backgroundImagePath: 'lib/assets/comida.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryPage(
                                    title: 'Comidas',
                                  ),
                                ),
                              );
                            },
                          );
                        case 3:
                          return buildCategoryCard(
                            title: 'Snacks',
                            backgroundImagePath: 'lib/assets/snacks.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryPage(
                                    title: 'Snacks',
                                  ),
                                ),
                              );
                            },
                          );
                        case 4:
                          return buildCategoryCard(
                            title: 'Doces',
                            backgroundImagePath: 'lib/assets/doces.jpg',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryPage(
                                    title: 'Doces',
                                  ),
                                ),
                              );
                            },
                          );
                        case 5:
                          return buildCategoryCard(
                            title: 'Restaurante',
                            backgroundImagePath:
                                'lib/assets/monteRestaurante.jpg',
                            isAvailable: false, // Add this parameter
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Em Desenvolvimento'),
                                  content: Text(
                                      'O Restaurante não está disponível no momento.'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        default:
                          return Container(); // Fallback for safety
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        )));
  }

  Widget buildProductSection({
    required String imagePath,
    required String title,
    required String price,
  }) {
    if (contador == 1) {
      CheckQuantidade(title.replaceAll('"', ''));
      contador = 0;
    }
    return GestureDetector(
      onTap: () async {
        contador = 1;
        CheckQuantidade(title.replaceAll(
            '"', '')); // Adiciona essa chamada para inicializar checkquantidade
        var quantidadeDisponivel = data[0]['Qtd'];

        if (quantidadeDisponivel == 1) {
          addToCart(imagePath, title, price);
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Produto Indisponível'),
              content: Text('Desculpe, este produto está indisponível.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fechar o diálogo
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        }
      },
      child: Container(
        width: MediaQuery.of(context).size.width / 2,
        margin: EdgeInsets.symmetric(horizontal: 2.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1.0,
              blurRadius: 2.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.memory(
                base64.decode(imagePath),
                height: 45.0,
              ),
              Text(
                title.replaceAll('"', ''),
                style: TextStyle(
                  fontSize: 11.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Preço:',
                    style: TextStyle(fontSize: 8.0),
                  ),
                  Text(
                    "${double.parse(price).toStringAsFixed(2).replaceAll('.', ',')}€",
                    style: TextStyle(fontSize: 10.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addToCart(String imagePath, String title, String price) {
    // Verifica se os parâmetros necessários não são nulos
    if (imagePath != null && title != null && price != null) {
      // Cria um mapa representando o item a ser adicionado ao carrinho
      Map<String, dynamic> item = {
        'Imagem': imagePath,
        'Nome': title.replaceAll('"', ''),
        'Preco': price,
      };

      // Atualiza a interface do usuário e adiciona o item ao carrinho
      setState(() {
        cartItems.add(item);
      });

      // Exibe um snackbar para informar ao usuário que o item foi adicionado ao carrinho
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Item adicionado ao carrinho com sucesso!'),
        ),
      );
    } else {
      // Exibe uma mensagem de erro se algum dos parâmetros for nulo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: Não foi possível adicionar o item ao carrinho.'),
        ),
      );
    }
  }

  Widget buildCategoryCard({
    required String title,
    required String backgroundImagePath,
    required VoidCallback onTap,
    bool isAvailable = true,
    bool showImage = true, // Add this new parameter
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150.0,
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Colors.grey[300], // Always gray background when not available
        ),
        child: Stack(
          children: [
            // Only show image if available AND showImage is true
            if (isAvailable && showImage)
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: AssetImage(backgroundImagePath),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            // Panel to highlight the text
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 29, 29, 29).withOpacity(0.5),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(20.0)),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // "Not Available" indicator
            if (!isAvailable)
              Stack(
                children: [
                  // Background image with gray overlay
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color.fromARGB(33, 49, 49, 49),
                      image: DecorationImage(
                        image: AssetImage(backgroundImagePath),
                        fit: BoxFit.cover,
                        colorFilter: ColorFilter.mode(
                          const Color.fromARGB(255, 36, 36, 36)
                              .withOpacity(0.7), // Gray overlay on image
                          BlendMode.darken,
                        ),
                      ),
                    ),
                  ),
                  // "EM DESENVOLVIMENTO" text
                  Center(
                    child: Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.construction,
                            size: 30,
                            color: Colors.white,
                          ),
                          SizedBox(height: 8),
                          Container(
                            width:
                                200, // Set a specific width to control wrapping
                            child: Text(
                              'EM DESENVOLVIMENTO',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    blurRadius: 10,
                                    color: Colors.black,
                                    offset: Offset(2, 2),
                                  ),
                                ],
                              ),
                              textAlign:
                                  TextAlign.center, // Optional: Center the text
                              maxLines:
                                  1, // Optional: Limit the number of lines
                              overflow: TextOverflow
                                  .ellipsis, // Optional: Handle overflow
                            ),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
// Panel to highlight the text
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(20.0)),
                  border: Border.all(color: Colors.white, width: 1),
                ),
                padding: EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24.0,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryPage extends StatefulWidget {
  final String title;

  const CategoryPage({Key? key, required this.title}) : super(key: key);

  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  List<dynamic> items = [];
  List<dynamic> filteredItems = [];
  late StreamController<List<dynamic>> _streamController;
  final TextEditingController _searchController = TextEditingController();
  String? selectedSortOption;
  double? minPrice;
  double? maxPrice;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<dynamic>>();
    fetchData(widget.title);
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _streamController.close();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> fetchData(String categoria) async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '5',
          'categoria': '$categoria',
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List<dynamic>) {
          items = responseData.cast<Map<String, dynamic>>();
          filteredItems = items; // Initialize filteredItems
          _streamController.add(filteredItems);
        } else {
          throw Exception('Response data is not a List<dynamic>');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Erro ao carregar data: $e');
    }
  }

  void _filterItems() {
    final query = removeDiacritics(
        _searchController.text.toLowerCase()); // Normalize query
    print('Search Query: $query'); // Debugging line

    setState(() {
      // Check if items are loaded
      if (items.isEmpty) {
        print('No items to search through.'); // Debugging line
        filteredItems = [];
        return;
      }

      // Filter items based on the search query
      filteredItems = items.where((item) {
        // Ensure 'Nome' exists and is a string
        if (item['Nome'] != null && item['Nome'] is String) {
          // Normalize 'Nome' for comparison
          final normalizedNome = removeDiacritics(item['Nome'].toLowerCase());
          return normalizedNome.contains(query);
        }
        return false; // Exclude items without a valid 'Nome'
      }).toList();

      _streamController.add(filteredItems);
    });
  }

  void addToCart(Map<String, dynamic> item) {
    setState(() {
      cartItems.add(item);
    });
  }

  void removeFromCart(Map<String, dynamic> item) {
    setState(() {
      cartItems.remove(item);
    });
  }

  Future<void> _onRefresh() async {
    // Call fetchData to refresh the data
    await fetchData(widget.title);
  }

  Future<bool> _onWillPop() async {
    // Navigate to home page
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) =>
              HomeAluno()), // Replace with your Home page widget
      (Route<dynamic> route) => false,
    );
    return false; // Prevent default back navigation
  }

  void _sortItems() {
    setState(() {
      if (selectedSortOption == 'asc') {
        filteredItems.sort((a, b) =>
            double.parse(a['Preco']).compareTo(double.parse(b['Preco'])));
      } else {
        filteredItems.sort((a, b) =>
            double.parse(b['Preco']).compareTo(double.parse(a['Preco'])));
      }
      _streamController.add(filteredItems);
    });
  }

  void _filterByPrice() {
    setState(() {
      filteredItems = items.where((item) {
        double price = double.parse(item['Preco']);
        return (minPrice == null || price >= minPrice!) &&
            (maxPrice == null || price <= maxPrice!);
      }).toList();
      _streamController.add(filteredItems);
    });
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Filtro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  value: selectedSortOption, // This can be null
                  hint: Text(
                      'Selecione uma opção'), // Hint text when no value is selected
                  items: [
                    DropdownMenuItem(
                      value: 'asc', // Value for ascending
                      child: Row(
                        children: [
                          Icon(Icons.arrow_upward), // Icon for ascending
                          SizedBox(width: 8),
                          Text('Ascendente'),
                        ],
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'desc', // Value for descending
                      child: Row(
                        children: [
                          Icon(Icons.arrow_downward), // Icon for descending
                          SizedBox(width: 8),
                          Text('Descendente'),
                        ],
                      ),
                    ),
                  ],
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedSortOption = newValue; // Update the selection
                        _sortItems(); // Call the sorting function
                        Navigator.pop(context); // Close the dialog
                      });
                    }
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Mínimo',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    minPrice = value.isNotEmpty ? double.tryParse(value) : null;
                    _filterByPrice();
                  },
                ),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Preço Máximo',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    maxPrice = value.isNotEmpty ? double.tryParse(value) : null;
                    _filterByPrice();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Fechar'),
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
        title: Text(widget.title),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShoppingCartPage(),
                ),
              );
            },
            icon: Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: Column(
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
                      _filterItems(); // Call filter on text change
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
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: StreamBuilder<List<dynamic>>(
                stream: _streamController.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<dynamic> items = snapshot.data!;
                    return ListView.builder(
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final double preco = double.parse(item['Preco']);
                        return Card(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                leading: Image.memory(
                                  base64.decode(item['Imagem']),
                                  fit: BoxFit.cover,
                                  height: 50,
                                  width: 50,
                                ),
                                title: Text(item['Nome']),
                                subtitle: Text(
                                  item['Qtd'] == "1"
                                      ? "Disponível - ${preco.toStringAsFixed(2).replaceAll('.', ',')}€"
                                      : "Indisponível",
                                ),
                                trailing: cartItems.any((cartItem) =>
                                        cartItem['Nome'] == item['Nome'])
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              removeFromCart(item);
                                            },
                                            icon: Icon(Icons.remove),
                                          ),
                                          Text(
                                            cartItems
                                                .where((element) =>
                                                    element['Nome'] ==
                                                    item['Nome'])
                                                .length
                                                .toString(),
                                            style: TextStyle(fontSize: 15.0),
                                          ),
                                          IconButton(
                                            onPressed: () {
                                              addToCart(item);
                                            },
                                            icon: Icon(Icons.add),
                                          ),
                                        ],
                                      )
                                    : Visibility(
                                        visible: item['Qtd'] == "1",
                                        child: ElevatedButton(
                                          onPressed: () {
                                            addToCart(item);
                                          },
                                          child: Text('Comprar'),
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  }
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
//Monte

class CategoryPageMonte extends StatefulWidget {
  final String title;

  const CategoryPageMonte({Key? key, required this.title}) : super(key: key);

  @override
  _CategoryPageMonteState createState() => _CategoryPageMonteState();
}

class _CategoryPageMonteState extends State<CategoryPageMonte> {
  List<dynamic> items = [];
  List<dynamic> filteredItems = [];
  late StreamController<List<dynamic>> _streamController;
  final TextEditingController _searchController = TextEditingController();

  // Reservation fields
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _timeController = TextEditingController();
  String? _selectedTime;

  dynamic users;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<dynamic>>();
    fetchData(widget.title);
    _searchController.addListener(_filterItems);
    UserInfo();
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    }
  }

  @override
  void dispose() {
    _streamController.close();
    _searchController.dispose();
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }

  Future<void> fetchData(String categoria) async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': '2',
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List<dynamic>) {
          items = responseData.cast<Map<String, dynamic>>();
          filteredItems = items; // Initialize filteredItems
          _streamController.add(filteredItems);
        } else {
          throw Exception(
              'Error 03 - NOT IS DYNAMIC LIST. Contacte o Administrador');
        }
      } else {
        throw Exception('Erro ao carregar dados');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredItems = items.where((item) {
        return item['nome'].toLowerCase().contains(query);
      }).toList();
      _streamController.add(filteredItems);
    });
  }

  Future<void> _makeReservation(
      Map<String, dynamic> item, DateTime date, TimeOfDay time) async {
    // Get the selected time
    var selectedTime =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    // Validate inputs
    if (selectedTime.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor, selecione as horas.')),
      );
      return;
    }

    // Get the current time
    TimeOfDay currentTime = TimeOfDay.now();
    TimeOfDay cutoffTime = TimeOfDay(hour: 11, minute: 0); // 11:00 AM

    // Determine if the current time is after 11:00 AM
    bool isAfterCutoffTime = (currentTime.hour > cutoffTime.hour) ||
        (currentTime.hour == cutoffTime.hour &&
            currentTime.minute > cutoffTime.minute);

    // Set the reservation date based on the current time
    DateTime reservationDate = date;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('A Reservar...')),
    );

    try {
      final response = await http.post(
        Uri.parse(
            'https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'), // Replace with your API endpoint
        body: {
          'query_param': '1', // Ensure this is a string
          'name': users[0]['Nome'].toString(),
          'hora': selectedTime, // Use the selected time directly
          'people': '1', // Convert to string
          'aluno': users[0]['Email'].toString(),
          'food':
              item['nome'].toString(), // Include item name in the reservation
          'date': reservationDate
              .toIso8601String()
              .split('T')[0], // Add the reservation date
        },
      );

      print(response.body);

      if (response.statusCode == 200) {
        // Handle successful reservation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reservado com sucesso!')),
        );
      } else {
        // Handle server error
        final errorMessage = response.body.isNotEmpty
            ? response.body
            : 'Erro ao fazer a reserva';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      print('Erro ao fazer a reserva: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fazer a reserva: $e')),
      );
    }
  }

  void _showReservationDialog(Map<String, dynamic> item) {
    DateTime? selectedDate; // Variable to hold the selected date

    // Get the current time
    TimeOfDay currentTime = TimeOfDay.now();
    TimeOfDay cutoffTime = TimeOfDay(hour: 11, minute: 0); // 11:00 AM

    // Check if the current time is after 11:00 AM
    bool isAfterCutoffTime = (currentTime.hour > cutoffTime.hour) ||
        (currentTime.hour == cutoffTime.hour &&
            currentTime.minute > cutoffTime.minute);

    // Set the reservation date based on the current time
    DateTime reservationDate =
        DateTime.now().add(Duration(days: isAfterCutoffTime ? 1 : 0));

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reservar ${item['nome']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Button to select the time
              TextFormField(
                controller: _timeController,
                decoration: InputDecoration(
                  labelText: 'Hora (HH:MM)',
                ),
                readOnly: true,
                onTap: () {
                  _showTimePicker();
                },
              ),
              SizedBox(height: 20),
              // Display the selected time
              if (_selectedTime != null)
                Text('Horas Selecionadas: $_selectedTime'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_selectedTime != null) {
                  // Convert selected time string to TimeOfDay
                  List<String> timeParts =
                      _selectedTime!.split(':'); // Use null check here
                  TimeOfDay selectedTime = TimeOfDay(
                    hour: int.parse(timeParts[0]),
                    minute: int.parse(timeParts[1]),
                  );

                  // Show confirmation dialog
                  _showConfirmationDialog(item, reservationDate, selectedTime);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please select a time')),
                  );
                }
              },
              child: Text('Reservar'),
            ),
          ],
        );
      },
    );
  }

  void _showConfirmationDialog(
      Map<String, dynamic> item, DateTime date, TimeOfDay time) {
    // Check if the selected time is after 14:00
    if (time.hour >= 14) {
      date = date.add(Duration(days: 1)); // Move reservation to the next day
    }

    // Create the reservation summary with bold date
    String formattedDate = DateFormat('yyyy-MM-dd').format(date);
    String formattedTime = time.format(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Reserva'),
          content: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Reservas-te ${item['nome']} para o dia ',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                TextSpan(
                  text: DateFormat('dd/MM/yyyy').format(date), // Bold date
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                TextSpan(
                  text: ' às ',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                TextSpan(
                  text: '$formattedTime.',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                _makeReservation(item, date,
                    time); // Call the reservation method with three arguments
                Navigator.of(context).pop(); // Close the confirmation dialog
                Navigator.of(context).pop();
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void _showTimePicker() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Selecione as Horas'),
          content: DropdownButton<String>(
            isExpanded: true,
            hint: Text('Selecione as Horas'),
            value: _selectedTime,
            items: _getValidTimes().map((String time) {
              return DropdownMenuItem<String>(
                value: time,
                child: Text(time),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedTime = newValue;
                _timeController.text = newValue ?? '';
              });
              Navigator.of(context).pop(); // Close the dialog
            },
          ),
        );
      },
    );
  }

  List<String> _getValidTimes() {
    List<String> validTimes = [];
    // Generate valid times between 11:30 and 14:00
    for (int hour = 11; hour <= 14; hour++) {
      for (int minute = 0; minute < 60; minute += 10) {
        if (hour == 11 && minute < 30) continue; // Skip times before 11:30
        if (hour == 14 && minute > 0) continue; // Skip times after 14:00
        validTimes.add(
            '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }
    return validTimes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Procurar...',
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<dynamic>>(
        stream: _streamController.stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Pratos não Encontrados'));
          }

          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                          leading: Image.memory(
                            base64.decode(item['imagem']),
                            fit: BoxFit.cover,
                            height: 50,
                            width: 50,
                          ),
                          title: Text(item['nome']),
                          trailing: Visibility(
                            visible: item['estado'] == "1",
                            child: ElevatedButton(
                              onPressed: () {
                                _showReservationDialog(item);
                              },
                              child: Text('Reservar'),
                            ),
                          ))
                    ]),
              );
            },
          );
        },
      ),
    );
  }
}

class ShoppingCartPage extends StatefulWidget {
  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  Map<String, int> itemCountMap = {};
  dynamic users;
  double dinheiroAtual = 0;
  SibsService? _sibsService;
  int orderNumber = 0;

  @override
  void initState() {
    super.initState();
    updateItemCountMap();
    UserInfo();
    _initializeSibsService();
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    }
  }

  Future<void> _initializeSibsService() async {
    try {
      _sibsService = SibsService(
        accessToken:
            '0267adfae94c224be1b374be2ce7b298f0.eyJlIjoiMjA1NzkzODk3NTc1MSIsInJvbGVzIjoiTUFOQUdFUiIsInRva2VuQXBwRGF0YSI6IntcIm1jXCI6XCI1MDYzNTBcIixcInRjXCI6XCI4MjE0NFwifSIsImkiOiIxNzQyNDA2MTc1NzUxIiwiaXMiOiJodHRwczovL3FseS5zaXRlMS5zc28uc3lzLnNpYnMucHQvYXV0aC9yZWFsbXMvREVWLlNCTy1JTlQuUE9SVDEiLCJ0eXAiOiJCZWFyZXIiLCJpZCI6IjVXcjN5WkZCSERmNzE4MDgxMGYxYjA0YTg2OTE4OTEwZDBjYzM2ZTRiMSJ9.6a6179e2d76dbe03f41f8252510dcb8a7056d9132a034c26174a6cf5c2ce75b3b5052d85f38fdd8b8765b7dfeb42e2d8aae898dfea1893b217856ef0794ee2f1',
        merchantId: '506350',
        merchantName: 'AppBar',
      );
      print('Serviço SIBS inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar serviço SIBS: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao inicializar serviço de pagamento')),
      );
    }
  }

  Future<bool> _showPrencadoConfirmationDialog(List<Map<String, dynamic>> prencadoProducts) async {
    Map<String, bool> selectedProducts = {};
    
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmação de Preparação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: prencadoProducts.map((product) {
                String prencado = product['Prencado'] ?? '0';
                String preparationType = prencado == '1' ? 'Prençado' : 'Aquecido';
                selectedProducts[product['Nome']] = false;
                
                return StatefulBuilder(
                  builder: (context, setState) {
                    return CheckboxListTile(
                      title: Text(product['Nome']),
                      subtitle: Text('Deseja $preparationType?'),
                      value: selectedProducts[product['Nome']],
                      onChanged: (bool? value) {
                        setState(() {
                          selectedProducts[product['Nome']] = value ?? false;
                          product['PrepararPrencado'] = value ?? false;
                        });
                      },
                    );
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                // Update cartItems with selected preferences
                for (var product in prencadoProducts) {
                  int index = cartItems.indexWhere((item) => item['Nome'] == product['Nome']);
                  if (index != -1) {
                    cartItems[index]['PrepararPrencado'] = selectedProducts[product['Nome']];
                  }
                }
                Navigator.of(context).pop(true);
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<bool> _showOrderConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmar Pedido'),
          content: Text('Deseja confirmar o pedido?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    ) ?? false;
  }

  Future<void> sendOrderToApi() async {
    if (itemCountMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O carrinho está vazio')),
      );
      return;
    }

    // First confirmation dialog
    bool confirmOrder = await _showOrderConfirmationDialog();
    if (!confirmOrder) return;

    // Check for products with Prencado != 0
    List<Map<String, dynamic>> prencadoProducts = cartItems.where((item) {
      String prencado = item['Prencado'] ?? '0';
      return prencado != '0';
    }).toList();

    // If there are products with Prencado != 0, show the confirmation dialog
    if (prencadoProducts.isNotEmpty) {
      bool confirmPrencado = await _showPrencadoConfirmationDialog(prencadoProducts);
      if (!confirmPrencado) return;
    }

    // Mostrar diálogo de seleção de método de pagamento
    final paymentMethod = await _showPaymentMethodDialog();
    if (paymentMethod == null) return;

    try {
      // Create the description string with proper formatting
      List<String> formattedNames = cartItems.map((item) {
        String name = item['Nome'] as String;
        bool prepararPrencado = item['PrepararPrencado'] ?? false;
        String prencado = item['Prencado'] ?? '0';
        
        if (prepararPrencado && prencado != '0') {
          if (prencado == '1') {
            return '$name - Prençado';
          } else if (prencado == '2') {
            return '$name - Aquecido';
          }
        }
        return name;
      }).toList();

      String descricao = formattedNames.join(', ');

      // Extract user information
      var turma = users[0]['Turma'] ?? '';
      var nome = users[0]['Nome'] ?? '';
      var apelido = users[0]['Apelido'] ?? '';
      var permissao = users[0]['Permissao'] ?? '';
      var imagem = users[0]['Imagem'] ?? '';
      double total = calculateTotal();

      if (paymentMethod == 'mbway') {
        // Preparar os dados do pedido
        Map<String, dynamic> orderData = {
          'nome': nome,
          'apelido': apelido,
          'turma': turma,
          'descricao': descricao,
          'permissao': permissao,
          'imagem': imagem,
          'total': total.toString(),
          'payment_method': paymentMethod,
        };
        
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MBWayPhoneNumberPage(
              amount: total,
              orderData: orderData,
              sibsService: _sibsService!,
              onResult: (success, newOrderNumber) {
                if (success) {
                  setState(() {
                    cartItems.clear();
                    updateItemCountMap();
                    orderNumber = newOrderNumber;
                  });
                }
              },
              onCancel: () {
                Navigator.pop(context);
              },
            ),
          ),
        );
      } else if (paymentMethod == 'dinheiro') {
        // Se for dinheiro, perguntar sobre o troco
        bool needsChange = await _showNeedsChangeDialog();

        if (needsChange) {
          dinheiroAtual = await _showMoneyAmountDialog(total) ?? total;
        } else {
          dinheiroAtual = total;
        }

        // Criar o pedido com as informações de pagamento em dinheiro
        final response = await http.post(
          Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php'),
          body: {
            'query_param': '5',
            'nome': nome,
            'apelido': apelido,
            'orderNumber': '0',
            'turma': turma,
            'descricao': descricao,
            'permissao': permissao,
            'total': total.toString(),
            'valor': dinheiroAtual.toString(),
            'imagem': imagem,
            'payment_method': paymentMethod,
          },
        );

        print(response);
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        if (response.statusCode == 200) {
          if (response.body.isEmpty) {
            throw Exception('Empty response from server');
          }

          try {
            final data = json.decode(response.body);

            if (data['status'] == 'success') {
              orderNumber = int.parse(data['orderNumber'].toString());
              await sendOrderToWebSocket(cartItems, total.toString());

              setState(() {
                cartItems.clear();
                updateItemCountMap();
              });

              double change = dinheiroAtual - total;
              String changeMsg = change > 0
                  ? ' Troco: ${change.toStringAsFixed(2).replaceAll('.', ',')}€'
                  : '';

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Pedido enviado com sucesso! Pedido Nº $orderNumber.$changeMsg')),
              );

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderConfirmationPage(
                    orderNumber: orderNumber,
                    amount: total,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Erro ao criar pedido: ${data['message'] ?? "Erro desconhecido"}')),
              );
            }
          } catch (e) {
            print('JSON decode error: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao processar resposta do servidor')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro HTTP ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      print('Erro ao enviar pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar pedido: ${e.toString()}')),
      );
    }
  }

  Future<String?> _showPaymentMethodDialog() async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Método de Pagamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, 'dinheiro');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // width, height
                backgroundColor: Colors.green[700],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.attach_money, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Dinheiro',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ),
            SizedBox(height: 15),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, 'mbway');
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50), // width, height
                backgroundColor: Colors.red[800],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.phone_android, color: Colors.white),
                  SizedBox(width: 10),
                  Text('MBWay',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showNeedsChangeDialog() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Troco'),
            content: Text('Precisa de troco?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Não'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sim'),
              ),
            ],
          ),
        ) ??
        false; // Se o usuário fechar o diálogo sem escolher, assume false
  }

  Future<double?> _showMoneyAmountDialog(double total) async {
    final moneyController = TextEditingController();
    return showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Valor Entregue'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Total a pagar: ${total.toStringAsFixed(2).replaceAll('.', ',')}€'),
            SizedBox(height: 10),
            TextField(
              controller: moneyController,
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'Digite o valor que será entregue',
                suffixText: '€',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              double? amount =
                  double.tryParse(moneyController.text.replaceAll(',', '.'));
              if (amount != null && amount >= total) {
                Navigator.pop(context, amount);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Valor inválido ou menor que o total')),
                );
              }
            },
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> sendOrderToWebSocket(
      List<Map<String, dynamic>> cartItems, String total) async {
    try {
      // Format item names with preparation preferences
      List<String> formattedNames = cartItems.map((item) {
        String name = item['Nome'] as String;
        bool prepararPrencado = item['PrepararPrencado'] ?? false;
        String prencado = item['Prencado'] ?? '0';
        
        if (prepararPrencado && prencado != '0') {
          if (prencado == '1') {
            return '$name - Prençado';
          } else if (prencado == '2') {
            return '$name - Aquecido';
          }
        }
        return name;
      }).toList();
      
      String descricao = formattedNames.join(', ');

      var turma = users[0]['Turma'];
      var nome = users[0]['Nome'];
      var permissao = users[0]['Permissao'];
      var imagem = users[0]['Imagem'];

      final channel = WebSocketChannel.connect(
        Uri.parse('ws://websocket.appbar.epvc.pt'),
      );

      // Send order data
      Map<String, dynamic> orderData = {
        'QPediu': nome,
        'NPedido': orderNumber,
        'Troco': dinheiroAtual,
        'Turma': turma,
        'Permissao': permissao,
        'Estado': 0,
        'Descricao': descricao,
        'Total': total,
        'Imagem': imagem,
      };

      channel.sink.add(json.encode(orderData));

      channel.stream.listen(
        (message) {
          var serverResponse = json.decode(message);
          if (serverResponse['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text('Pedido enviado com sucesso! Pedido Nº $orderNumber'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Erro ao enviar o pedido. Contacte o Administrador! Error 02'),
              ),
            );
          }
          channel.sink.close();
        },
        onError: (error) {
          print('Erro ao fazer a requisição WebSocket: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Erro ao enviar o pedido. Contacte o Administrador! Error 01'),
            ),
          );
        },
      );
    } catch (e) {
      print('Erro ao estabelecer conexão WebSocket: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erro ao enviar o pedido. Contacte o Administrador! Error 01'),
        ),
      );
    }
  }

  void updateItemCountMap() {
    itemCountMap.clear();
    for (var item in cartItems) {
      final itemName = item['Nome'];
      // Verifica se o itemName não é nulo antes de tentar incrementar o contador
      if (itemName != null) {
        // Se o itemName já estiver no mapa, incrementa o contador; senão, define o contador como 1
        itemCountMap[itemName] = (itemCountMap[itemName] ?? 0) + 1;
      }
    }
  }

  double calculateTotal() {
    double total = 0.0;
    for (var item in cartItems) {
      double preco = double.parse(item['Preco']);
      total += preco;
    }
    return total;
  }

  String getLocalDate() {
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd').format(now);
    return formattedDateTime;
  }

  Future<void> sendRecentOrderToApi(
      List<Map<String, dynamic>> recentOrders) async {
    try {
      for (var order in recentOrders) {
        // Concatenar informações do usuário para formar o identificador do usuário
        var user = users[0]['Email'];
        var localData = getLocalDate();

        // Extrair a imagem se não for nula, caso contrário, use uma string vazia
        var imagem = order['Imagem'] ?? '';
        var preco = order['Preco'] ?? '';

        // Enviar solicitação POST para a API para cada pedido
        var response = await http.post(
          Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
          body: {
            'query_param': '6',
            'user': user,
            'orderDetails': json.encode(order['Nome']),
            'data': localData.toString(),
            'imagem': imagem,
            'preco': preco,
          },
        );

        if (response.statusCode == 200) {
          // Se a solicitação for bem-sucedida, mostrar uma mensagem de sucesso
          print('Pedido enviado com sucesso para a API');
        } else {
          // Se houver um erro, mostrar uma mensagem de erro
          print('Erro ao enviar pedido para a API');
        }
      }
    } catch (e) {
      print('Erro ao enviar pedidos para a API: $e');
    }
  }

  Future<int> checkQuantidade(String productName) async {
    // Remove double quotes from the product name
    String productNamee = productName.replaceAll('"', '');

    var response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=8&nome=$productNamee'));

    if (response.statusCode == 200) {
      // Decode the response body into a list of maps
      List<Map<String, dynamic>> data =
          json.decode(response.body).cast<Map<String, dynamic>>();

      if (data.isNotEmpty) {
        // Retrieve the quantity of the product
        int quantidade = data[0]['Qtd'];
        return quantidade;
      } else {
        // Return a default value or throw an exception if data is empty
        throw Exception('Data is empty');
      }
    } else {
      // Throw an exception if the request fails
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<void> checkAvailabilityBeforeOrder(double total) async {
    bool allAvailable = true;
    List<String> unavailableItems = [];

    for (var item in cartItems) {
      var itemName = item['Nome'];
      var quantity = await checkQuantidade(itemName);

      if (quantity == 0) {
        allAvailable = false;
        unavailableItems.add(itemName);
      }
    }

    if (cartItems.isNotEmpty) {
      if (allAvailable) {
        // Show payment method selection dialog
        final paymentMethod = await _showPaymentMethodDialog();
        if (paymentMethod == null) return;
        
        if (paymentMethod == 'mbway') {
          await _handleMBWayPayment(total);
        } else if (paymentMethod == 'dinheiro') {
          await _handleCashPayment(total);
        }
      } else {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Itens Indisponíveis'),
              content: Text(
                  'Os seguintes itens não estão disponíveis: ${unavailableItems.join(", ")}'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  // Método para lidar com pagamento MBWay
  Future<void> _handleMBWayPayment(double total) async {
    try {
      // Create the description string with proper formatting
      List<String> formattedNames = cartItems.map((item) {
        String name = item['Nome'] as String;
        bool prepararPrencado = item['PrepararPrencado'] ?? false;
        String prencado = item['Prencado'] ?? '0';
        
        if (prepararPrencado && prencado != '0') {
          if (prencado == '1') {
            return '$name - Prençado';
          } else if (prencado == '2') {
            return '$name - Aquecido';
          }
        }
        return name;
      }).toList();

      String descricao = formattedNames.join(', ');

      // Extract user information
      var turma = users[0]['Turma'] ?? '';
      var nome = users[0]['Nome'] ?? '';
      var apelido = users[0]['Apelido'] ?? '';
      var permissao = users[0]['Permissao'] ?? '';
      var imagem = users[0]['Imagem'] ?? '';

      // Preparar os dados do pedido
      Map<String, dynamic> orderData = {
        'nome': nome,
        'apelido': apelido,
        'turma': turma,
        'descricao': descricao,
        'permissao': permissao,
        'imagem': imagem,
        'total': total.toString(),
        'payment_method': 'mbway',
      };
      
      // Ir para a página de telefone MBWay com a lógica de pagamento
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MBWayPhoneNumberPage(
            amount: total,
            orderData: orderData,
            sibsService: _sibsService!,
            onResult: (success, newOrderNumber) {
              if (success) {
                setState(() {
                  cartItems.clear();
                  updateItemCountMap();
                  orderNumber = newOrderNumber;
                });
              }
            },
            onCancel: () {
              Navigator.pop(context);
            },
          ),
        ),
      );
    } catch (e) {
      print('Erro ao processar pagamento MBWay: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar pagamento: ${e.toString()}')),
      );
    }
  }

  // Método para lidar com pagamento em dinheiro
  Future<void> _handleCashPayment(double total) async {
    try {
      // Create the description string with proper formatting
      List<String> formattedNames = cartItems.map((item) {
        String name = item['Nome'] as String;
        bool prepararPrencado = item['PrepararPrencado'] ?? false;
        String prencado = item['Prencado'] ?? '0';
        
        if (prepararPrencado && prencado != '0') {
          if (prencado == '1') {
            return '$name - Prençado';
          } else if (prencado == '2') {
            return '$name - Aquecido';
          }
        }
        return name;
      }).toList();

      String descricao = formattedNames.join(', ');

      // Extract user information
      var turma = users[0]['Turma'] ?? '';
      var nome = users[0]['Nome'] ?? '';
      var apelido = users[0]['Apelido'] ?? '';
      var permissao = users[0]['Permissao'] ?? '';
      var imagem = users[0]['Imagem'] ?? '';

      // Se for dinheiro, perguntar sobre o troco
      bool needsChange = await _showNeedsChangeDialog();

      if (needsChange) {
        dinheiroAtual = await _showMoneyAmountDialog(total) ?? total;
      } else {
        dinheiroAtual = total;
      }

      // Criar o pedido com as informações de pagamento em dinheiro
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php'),
        body: {
          'query_param': '5',
          'nome': nome,
          'apelido': apelido,
          'orderNumber': '0',
          'turma': turma,
          'descricao': descricao,
          'permissao': permissao,
          'total': total.toString(),
          'valor': dinheiroAtual.toString(),
          'imagem': imagem,
          'payment_method': 'dinheiro',
        },
      );

      print(response);
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        if (response.body.isEmpty) {
          throw Exception('Empty response from server');
        }

        try {
          final data = json.decode(response.body);

          if (data['status'] == 'success') {
            orderNumber = int.parse(data['orderNumber'].toString());
            // Enviar para o WebSocket e limpar o carrinho
            await sendOrderToWebSocket(cartItems, total.toString());

            setState(() {
              cartItems.clear();
              updateItemCountMap();
            });

            double change = dinheiroAtual - total;
            String changeMsg = change > 0
                ? ' Troco: ${change.toStringAsFixed(2).replaceAll('.', ',')}€'
                : '';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Pedido enviado com sucesso! Pedido Nº $orderNumber.$changeMsg')),
              );

            // Navegar para a página de confirmação de pedido
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderConfirmationPage(
                  orderNumber: orderNumber,
                  amount: total,
                ),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Erro ao criar pedido: ${data['message'] ?? "Erro desconhecido"}')),
              );
          }
        } catch (e) {
          print('JSON decode error: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao processar resposta do servidor')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro HTTP ${response.statusCode}')),
        );
      }
    } catch (e) {
      print('Erro ao processar pagamento em dinheiro: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao processar pagamento: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double total = calculateTotal();
    final rootContext = context;
    return Scaffold(
      appBar: AppBar(
        title: Text('Carrinho de Compras'),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeAlunoMain(),
                ),
              );
            },
            icon: Icon(Icons.home),
          ),
        ],
      ),
      drawer: DrawerHome(),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: itemCountMap.length,
              itemBuilder: (context, index) {
                final itemName = itemCountMap.keys.toList()[index];
                final itemCount = itemCountMap[itemName] ?? 0;
                final item = cartItems.firstWhere(
                  (element) => element['Nome'] == itemName,
                );
                final image =
                    item != null ? base64.decode(item['Imagem']) : null;
                return Card(
                  child: ListTile(
                    leading: image != null
                        ? Image.memory(
                            image,
                            fit: BoxFit.cover,
                            height: 50,
                            width: 50,
                          )
                        : SizedBox.shrink(),
                    title: Text('$itemName'),
                    subtitle: Text('Quantidade: $itemCount'),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle),
                      onPressed: () {
                        setState(() {
                          for (int i = 0; i < cartItems.length; i++) {
                            if (cartItems[i]['Nome'] == itemName) {
                              cartItems.removeAt(i);
                              break;
                            }
                          }
                          updateItemCountMap();
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Item removido do carrinho')),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            margin: EdgeInsets.only(bottom: 16.0),
            child: Column(
              children: [
                Text(
                  'Total: ${total.toStringAsFixed(2).replaceAll('.', ',')}€',
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (cartItems.isEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Carrinho Vazio'),
                            content: Text(
                                'Carrinho Vazio.\nPara continuar adicione produtos.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      // First, check for products with Prencado != 0
                      List<Map<String, dynamic>> prencadoProducts = cartItems.where((item) {
                        String prencado = item['Prencado'] ?? '0';
                        return prencado != '0';
                      }).toList();

                      // If there are products that can be prepared, show the dialog
                      if (prencadoProducts.isNotEmpty) {
                        bool confirmPrencado = await _showPrencadoConfirmationDialog(prencadoProducts);
                        if (!confirmPrencado) return;
                      }

                      // After preparation options, proceed with availability check and payment
                      checkAvailabilityBeforeOrder(total);
                    }
                  },
                  child: Text('Confirmar Pedido'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
