import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Aluno/cartshopping.dart';
import 'package:my_flutter_project/Aluno/drawerHome.dart';
import 'package:my_flutter_project/assets/models/cartItem.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:intl/intl.dart';
import 'package:diacritic/diacritic.dart'; // Import the diacritic package
import 'package:my_flutter_project/assets/sqflite/databasehelper.dart';

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
  final DatabaseHelper dbHelper = DatabaseHelper();

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
    final response = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
      body: {
        'query_param': '4',
      },
    );
    if (response.statusCode == 200) {
      allProducts = json.decode(response.body);
    } else {
      throw Exception('Failed to load products');
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
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CategoryPageMonte(
                                    title: 'Restaurante',
                                  ),
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
      // Cria um CartItem a partir dos parâmetros
      final cartItem = CartItem(
        name: title.replaceAll('"', ''), // Remove double quotes from the title
        image: imagePath,
        price: double.parse(price), // Convert price to double
        quantity: "1", // Set the initial quantity to 1
      );

      // Atualiza a interface do usuário e adiciona o item ao carrinho
      setState(() {
        //cartItems.add(cartItem);
        dbHelper.insertCartItem(cartItem); // Insert into SQLite database
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150.0,
        margin: EdgeInsets.symmetric(vertical: 8.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          // No need for overflow property here
        ),
        child: Stack(
          children: [
            // Background image
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
              bottom: 0, // Position the panel at the bottom
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black
                      .withOpacity(0.5), // Semi-transparent black panel
                  borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(20.0)), // Rounded top corners
                  border: Border.all(
                      color: Colors.white, width: 1), // Optional: white border
                ),
                padding: EdgeInsets.all(8.0), // Padding for the text
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24.0, // Adjust font size as needed
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
  List<CartItem> cartItems = [];
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<dynamic>>();
    fetchData(widget.title);
    _searchController.addListener(_filterItems);
    fetchCartItems(); // Fetch cart items when the page is initialized
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
        body: {'query_param': '5', 'categoria': '$categoria'},
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List<dynamic>) {
          items = responseData.cast<Map<String, dynamic>>();
          filteredItems = items;
          _streamController.add(filteredItems);
        } else {
          throw Exception('Response data is not a List<dynamic>');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }
  }

  void fetchCartItems() async {
    final items = await dbHelper.fetchCartItems();
    setState(() {
      cartItems = items;
    });
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredItems = items.where((item) {
        final name = removeDiacritics(item['Nome'].toLowerCase());
        return name.contains(query);
      }).toList();
      _streamController.add(filteredItems);
    });
  }

  void addToCart(Map<String, dynamic> item) {
    final cartItem = CartItem(
      id: int.parse(item['Id']),
      name: item['Nome'],
      image: item['Imagem'],
      price: double.parse(item['Preco']),
      quantity: item['Qtd'].toString(),
    );
    setState(() {
      cartItems.add(cartItem);
      dbHelper.insertCartItem(cartItem);
    });
  }

  void removeFromCart(String itemName) async {
    // Find the CartItem object that matches the item name
    final cartItem = cartItems.firstWhere(
      (item) => item.name == itemName,
    );

    // If the item is found and has a valid ID, remove it from the cart
    if (cartItem != null && cartItem.id != null) {
      setState(() {
        cartItems.remove(cartItem);
      });
      await dbHelper.removeCartItem(cartItem.id!); // Remove from database
    } else {
      print('Cart item not found or has no ID');
    }
  }

  Future<void> _onRefresh() async {
    await fetchData(widget.title);
  }

  void _sortItems(String sortOrder) {
    setState(() {
      if (sortOrder == 'ascending') {
        items.sort((a, b) => a["Preco"].compareTo(b["Preco"]));
      } else if (sortOrder == 'descending') {
        items.sort((a, b) => b["Preco"].compareTo(a["Preco"]));
      }
      filteredItems = List.from(items);
      _streamController.add(filteredItems);
    });
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
                MaterialPageRoute(builder: (context) => ShoppingCartPage()),
              );
            },
            icon: Icon(Icons.shopping_cart),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Procurar...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.filter_list),
                  onSelected: (String value) {
                    _sortItems(value);
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem<String>(
                        value: 'ascending',
                        child: Text('Preço Ascendente'),
                      ),
                      PopupMenuItem<String>(
                        value: 'descending',
                        child: Text('Preço Descendente'),
                      ),
                    ];
                  },
                ),
              ],
            ),
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
                        final isAvailable = item['Qtd'] == "1";
                        return Card(
                          child: ListTile(
                            leading: Image.memory(
                              base64.decode(item['Imagem']),
                              fit: BoxFit.cover,
                              height: 50,
                              width: 50,
                            ),
                            title: Text(item['Nome']),
                            subtitle: Text(
                                "${double.parse(item['Preco'].toString()).toStringAsFixed(2).replaceAll('.', ',')}€"),
                            trailing: isAvailable
                                ? cartItems.any((cartItem) =>
                                        cartItem.name == item['Nome'])
                                    ? Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              removeFromCart(item['Nome']);
                                            },
                                            icon: Icon(Icons.remove),
                                          ),
                                          Text(cartItems
                                              .where((element) =>
                                                  element.name == item['Nome'])
                                              .length
                                              .toString()),
                                          IconButton(
                                            onPressed: () {
                                              addToCart(item);
                                            },
                                            icon: Icon(Icons.add),
                                          ),
                                        ],
                                      )
                                    : ElevatedButton(
                                        onPressed: () {
                                          addToCart(item);
                                        },
                                        child: Text('Comprar'),
                                      )
                                : SizedBox.shrink(),
                          ),
                        );
                      },
                    );
                  }
                  return Center(child: CircularProgressIndicator());
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
          throw Exception('Response data is not a List<dynamic>');
        }
      } else {
        throw Exception('Failed to load data');
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
        SnackBar(content: Text('Please select a time.')),
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
      SnackBar(content: Text('Making reservation...')),
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
              if (_selectedTime != null) Text('Selected Time: $_selectedTime'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancel'),
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
          title: Text('Confirm Reservation'),
          content: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'Reservas-te ${item['nome']} para o dia ',
                  style: TextStyle(fontWeight: FontWeight.normal),
                ),
                TextSpan(
                  text: formattedDate, // Bold date
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(
                  text: ' às $formattedTime.',
                  style: TextStyle(fontWeight: FontWeight.normal),
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
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _makeReservation(item, date,
                    time); // Call the reservation method with three arguments
                Navigator.of(context).pop(); // Close the confirmation dialog
                Navigator.of(context).pop();
              },
              child: Text('Confirm'),
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
          title: Text('Select Time'),
          content: DropdownButton<String>(
            isExpanded: true,
            hint: Text('Select a time'),
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
                hintText: 'Search...',
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
            return Center(child: Text('No items found'));
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
