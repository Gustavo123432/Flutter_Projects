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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Bar EPVC',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: HomeAluno(),
    );
  }
}

class HomeAluno extends StatefulWidget {
  @override
  _HomeAlunoState createState() => _HomeAlunoState();
}

class _HomeAlunoState extends State<HomeAluno> {
  dynamic users;
  List<dynamic> recentBuys = [];
  dynamic checkquantidade;
  var contador = 1;
  bool _isSearching = false;

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
          var nome = userData['Nome'];
          var apelido = userData['Apelido'];
          var user = nome + " " + apelido;
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
    return Scaffold(
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
        /*title: Text('Search App'),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  // Ação ao clicar no ícone de pesquisa
                },
                child: Icon(
                  Icons.search,
                  size: 26.0,
                ),
              ),
            ),
          ],
          flexibleSpace: Padding(
            padding: EdgeInsets.only(right: 50.0, left: 10.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
              ),
            ),
          ),*/
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
              child: ListView(
                children: [
                  buildCategoryCard(
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
                  ),
                  buildCategoryCard(
                    title: 'Café',
                    backgroundImagePath: 'lib/assets/cafe.JPG',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CategoryPage(
                            title: 'Café',
                          ),
                        ),
                      );
                    },
                  ),
                  buildCategoryCard(
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
                  ),
                  buildCategoryCard(
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
                  ),
                  buildCategoryCard(
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
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      /* bottomNavigationBar: Container(
        height: 60,
        child: BottomAppBar(
          color: Color.fromARGB(255, 246, 141, 45),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HomeAlunoMain(),
                    ),
                  );
                },
                iconSize: 25,
              ),
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ShoppingCartPage(),
                    ),
                  );
                },
                iconSize: 25,
              ),
              IconButton(
                icon: Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  // Replace `DrawerHome()` with proper navigation to your drawer widget
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DrawerHome(),
                    ),
                  );
                },
                iconSize: 25,
              ),
            ],
          ),
        ),
      ),*/
    );
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
    /*
    Timer.periodic(Duration(seconds: 30), (timer) {
      CheckQuantidade(title.replaceAll('"', ''));
    });*/
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 150.0,
        margin: EdgeInsets.symmetric(vertical: 8.0),
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundImagePath),
            fit: BoxFit.cover,
          ),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 32.0,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
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
  late StreamController<List<dynamic>> _streamController;

  @override
  void initState() {
    super.initState();
    _streamController = StreamController<List<dynamic>>();
    fetchData(widget.title);
  }

  @override
  void dispose() {
    _streamController.close();
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
          _streamController.add(responseData.cast<Map<String, dynamic>>());
        } else {
          throw Exception('Response data is not a List<dynamic>');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
    }

    // Chamar novamente a função fetchData após um pequeno atraso para verificar atualizações
    /*Future.delayed(Duration(seconds: 5), () {
      fetchData(categoria);
    });*/
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
      body: StreamBuilder<List<dynamic>>(
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
                        trailing: cartItems.any(
                                (cartItem) => cartItem['Nome'] == item['Nome'])
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  /*IconButton(
                                    onPressed: () {
                                      removeFromCart(item);
                                    },
                                    icon: Icon(Icons.remove),
                                  ),*/
                                  Text(
                                    cartItems
                                        .where((element) =>
                                            element['Nome'] == item['Nome'])
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

  @override
  void initState() {
    super.initState();
    updateItemCountMap();
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

  int generateRandomNumber(int min, int max) {
    // Initialize the random number generator
    var rng = Random();

    // Generate a random number between min and max (inclusive)
    return min + rng.nextInt(max - min + 1);
  }

  void sendOrderToApi(
      List<Map<String, dynamic>> cartItems, String total) async {
    // Generate a random order number
    int orderNumber = generateRandomNumber(1000, 9999);

    try {
      // Extracting names from cart items
      List<String> itemNames =
          cartItems.map((item) => item['Nome'] as String).toList();

      // Extract user information
      var turma = users[0]['Turma'];
      var nome = users[0]['Nome'];
      var apelido = users[0]['Apelido'];
      var permissao = users[0]['Permissao'];

      // Encode cartItems to JSON string
      String cartItemsJson = json.encode(cartItems);

      // Send GET request to API
      var response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=5&nome=$nome&apelido=$apelido&orderNumber=$orderNumber&valor=$dinheiroAtual&turma=$turma&permissao=$permissao&descricao=$itemNames&total=$total',
      ));

      if (response.statusCode == 200) {
        // If the request is successful, show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido enviado com sucesso! Pedido Nº' +
                orderNumber.toString()),
          ),
        );
      } else {
        // If there's an error, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar o pedido. Contacte o Administrador!'),
          ),
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição GET: $e');
      // Show error message if request fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erro ao enviar o pedido. Contacte o Administrador! Error 01'),
        ),
      );
    }
  }

  void sendOrderToWebSocket(
      List<Map<String, dynamic>> cartItems, String total) async {
    int orderNumber = generateRandomNumber(1000, 9999);

    try {
      // Check if cartItems is not empty
      print('Cart items: $cartItems'); // Debugging

      // Extract item names or any other needed data
      List<String> itemNames =
          cartItems.map((item) => item['Nome'] as String).toList();
      print('Item names: $itemNames'); // Debugging

      var turma = users[0]['Turma'];
      var nome = users[0]['Nome'];
      var apelido = users[0]['Apelido'];
      var permissao = users[0]['Permissao'];

      final channel = WebSocketChannel.connect(
        Uri.parse('ws://websocket.appbar.epvc.pt'),
      );

      // Send all necessary cart data
      Map<String, dynamic> orderData = {
        'QPediu': nome,
        'NPedido': orderNumber,
        'Troco': dinheiroAtual,
        'Turma': turma,
        'Permissao': permissao,
        'Descricao': itemNames, // Cart item names
        'Total': total,
      };

      print('Sending over WebSocket: ${json.encode(orderData)}'); // Debugging

      channel.sink.add(json.encode(orderData));

      channel.stream.listen(
        (message) {
          var serverResponse = json.decode(message);
          if (serverResponse['status'] == 'success') {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Pedido enviado com sucesso! Pedido Nº' +
                    orderNumber.toString()),
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
          channel.sink.close(status.normalClosure);
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
      // Obter informações do usuário do primeiro usuário na lista de usuários
      var nome = users[0]['Nome'];
      var apelido = users[0]['Apelido'];

      for (var order in recentOrders) {
        // Concatenar informações do usuário para formar o identificador do usuário
        var user = nome + " " + apelido;
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
      var quantity = await checkQuantidade(itemName); // Await here

      if (quantity == 0) {
        allAvailable = false;
        unavailableItems.add(itemName);
      }
    }

    if (cartItems.isNotEmpty) {
      if (allAvailable) {
        sendOrderToApi(cartItems, total.toString());
        sendRecentOrderToApi(cartItems);
        sendOrderToWebSocket(cartItems, total.toString());

        setState(() {
          cartItems.clear();
          updateItemCountMap();
        });
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

  @override
  Widget build(BuildContext context) {
    double total = calculateTotal();
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
                  onPressed: () {
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
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Confirmação do Pedido'),
                            content: Text('Deseja confirmar o pedido?'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text("Confirmação de Pedido"),
                                        content: Text("Você tem o dinheiro (" +
                                            total
                                                .toStringAsFixed(2)
                                                .replaceAll('.', ',') +
                                            "€) EXATO ?"),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                      'Confirmação de Pedido com Sucesso'),
                                                ),
                                              );
                                              checkAvailabilityBeforeOrder(
                                                  total);

                                              Navigator.of(context).pop();
                                            },
                                            child: Text('Sim'),
                                          ),
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(context).pop();
                                              showDialog(
                                                context: context,
                                                builder:
                                                    (BuildContext context) {
                                                  dinheiroAtual =
                                                      0.0; // Valor padrão
                                                  return AlertDialog(
                                                    title: Text(
                                                        "Insira a quantidade de dinheiro irá entregar:"),
                                                    content: TextField(
                                                      keyboardType:
                                                          TextInputType.number,
                                                      onChanged: (value) {
                                                        dinheiroAtual =
                                                            double.tryParse(
                                                                    value) ??
                                                                0.0;
                                                      },
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () {
                                                          Navigator.of(context)
                                                              .pop();
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  'Confirmação de Pedido com Sucesso'),
                                                            ),
                                                          );
                                                          // Aqui você pode chamar a função para verificar a disponibilidade antes do pedido
                                                          checkAvailabilityBeforeOrder(
                                                              total);
                                                          Navigator.of(context)
                                                              .pop();
                                                        },
                                                        child:
                                                            Text('Confirmar'),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              );
                                            },
                                            child: Text('Não'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                                child: Text('Confirmar'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('Cancelar'),
                              ),
                            ],
                          );
                        },
                      );
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
