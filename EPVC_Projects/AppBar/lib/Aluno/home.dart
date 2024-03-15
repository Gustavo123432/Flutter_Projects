import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
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
      Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
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
        'http://api.gfserver.pt/appBarAPI_GET.php?query_param=8&nome=$productNamee'));

    if (response.statusCode == 200) {
      setState(() {
        // Cast the decoded JSON objects to List<Map<String, dynamic>>
        data = json.decode(response.body).cast<Map<String, dynamic>>();
        print(data);
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
            Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
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
      Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
      body: {
        'query_param': '4',
      },
    );
    if (response.statusCode == 200) {
        allProducts = json.decode(response.body);
       print(response.body);
    } else {
      throw Exception('Failed to load products');
    }
  }

void _filterProducts(String query) {
  setState(() {
    if (query.isNotEmpty) {
      _isSearching = true;
      // Filtra a lista de produtos com base na pesquisa
      filteredProducts = allProducts.where((product) =>
        product['Nome']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase())).toList();
    } else {
      _isSearching = false;
      filteredProducts = List.from(allProducts);
    }
  });
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /*appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 255, 255, 255),
        title: Text(
          '',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],*/
       appBar: AppBar(
      title: _isSearching ? TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: _filterProducts, // Chama _filterProducts quando o texto muda
        decoration: InputDecoration(
          hintText: 'Pesquisar produtos...',
          border: InputBorder.none,
          hintStyle: TextStyle(color: Colors.white),
        ),
      ) : Text('Produtos'), // Texto padrão quando não estiver pesquisando
      actions: [
        _isSearching ? IconButton(
          icon: Icon(Icons.cancel),
          onPressed: () {
            setState(() {
              _isSearching = false;
              _searchController.clear();
              filteredProducts = List.from(allProducts);
            });
          },
        ) : IconButton(
          icon: Icon(Icons.search),
          onPressed: () {
            setState(() {
              _isSearching = true;
            });
          },
        ),
      ],
    ),
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: filteredProducts.length, // Usa filteredProducts para exibir os resultados da pesquisa
            itemBuilder: (context, index) {
              var product = filteredProducts[index];
              var title = product['Descricao']; // Use o campo correto para o título do produto
              var price = product['Preco'].toString();
              // Você pode exibir os detalhes do produto aqui
              return ListTile(
                title: Text(title),
                subtitle: Text(price),
              );
            },
          ),
        ),
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
              top: 16.0, /* bottom: 16.0*/
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
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height:
            60, // Define o tamanho desejado para a barra de navegação inferior
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
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
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
            ],
          ),
        ),
      ),
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
    Timer.periodic(Duration(seconds: 30), (timer) {
      CheckQuantidade(title.replaceAll('"', ''));
    });
    return GestureDetector(
      onTap: () async {
        contador = 1;
        CheckQuantidade(title.replaceAll(
            '"', '')); // Adiciona essa chamada para inicializar checkquantidade
        var quantidadeDisponivel = data[0]['Qtd'];
        print(quantidadeDisponivel);

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
              color: Colors.grey.withOpacity(0.2),
              spreadRadius: 1.0,
              blurRadius: 2.0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.memory(
                base64.decode(imagePath),
                height: 40.0,
              ),
              Text(
                title.replaceAll('"', ''),
                style: TextStyle(
                  fontSize: 12.0,
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

  @override
  void initState() {
    super.initState();
    fetchData(widget.title);
    Timer.periodic(Duration(seconds: 1), (timer) {
      fetchData(widget.title);
    });
  }

  Future<void> fetchData(String categoria) async {
    try {
      final response = await http.post(
        Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
        body: {
          'query_param': '5',
          'categoria': '$categoria',
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
        if (responseData is List<dynamic>) {
          setState(() {
            items = responseData.cast<Map<String, dynamic>>();
          });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final double preco = double.parse(item['Preco']);

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
                items[index]['Qtd'] == "1"
                    ? "Disponível - ${preco.toStringAsFixed(2).replaceAll('.', ',')}€"
                    : "Indisponível",
              ),
              trailing: Visibility(
                visible: items[index]['Qtd'] == "1",
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      cartItems.add(item);
                    });
                  },
                  child: Text('Comprar'),
                ),
              ),
            ),
          );
        },
      ),
      /*bottomNavigationBar: BottomAppBar(
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
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
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
            ),
          ],
        ),
      ),*/
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
      Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
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
        'http://api.gfserver.pt/appBarAPI_GET.php?query_param=5&nome=$nome&apelido=$apelido&orderNumber=$orderNumber&turma=$turma&permissao=$permissao&descricao=$itemNames&total=$total',
      ));

      if (response.statusCode == 200) {
        // If the request is successful, show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedido enviado com sucesso para a API'),
          ),
        );
      } else {
        // If there's an error, show an error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao enviar o pedido para a API'),
          ),
        );
      }
    } catch (e) {
      print('Erro ao fazer a requisição GET: $e');
      // Show error message if request fails
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao enviar o pedido para a API'),
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
    String formattedDate = DateFormat('yyyy-MM-dd').format(now);
    return formattedDate;
  }

  Future<void> sendRecentOrderToApi(
      List<Map<String, dynamic>> recentOrders) async {
    try {
      // Obter informações do usuário do primeiro usuário na lista de usuários
      var nome = users[0]['Nome'];
      var apelido = users[0]['Apelido'];
      print(recentOrders);

      for (var order in recentOrders) {
        // Concatenar informações do usuário para formar o identificador do usuário
        var user = nome + " " + apelido;
        var localData = getLocalDate();

        // Extrair a imagem se não for nula, caso contrário, use uma string vazia
        var imagem = order['Imagem'] ?? '';
        var preco = order['Preco'] ?? '';

        // Enviar solicitação POST para a API para cada pedido
        var response = await http.post(
          Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
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

  Future<double> checkQuantidade(String productName) async {
    // Remove double quotes from the product name
    String productNamee = productName.replaceAll('"', '');

    var response = await http.get(Uri.parse(
        'http://api.gfserver.pt/appBarAPI_GET.php?query_param=8&nome=$productNamee'));

    if (response.statusCode == 200) {
      // Decode the response body into a list of maps
      List<Map<String, dynamic>> data =
          json.decode(response.body).cast<Map<String, dynamic>>();

      if (data.isNotEmpty) {
        // Retrieve the quantity of the product
        double quantidade = data[0]['Qtd'];
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

  void checkAvailabilityBeforeOrder(double total) {
    bool allAvailable = true;
    List<String> unavailableItems = [];

    for (var item in cartItems) {
      var itemName = item['Nome'];
      var quantity = checkQuantidade(
          itemName); // Adicione um campo 'Quantidade' aos itens do carrinho

      if (quantity == 0) {
        allAvailable = false;
        unavailableItems.add(itemName);
        print(quantity);
      }
    }
    if (cartItems != null) {
      if (allAvailable) {
        // Se todos os itens estiverem disponíveis, faça o pedido
        sendOrderToApi(cartItems, total.toString());
        sendRecentOrderToApi(cartItems);
        setState(() {
          cartItems.clear();
          updateItemCountMap();
        });
      } else {
        // Se houver itens indisponíveis, informe ao usuário
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
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    double total = calculateTotal();
    return Scaffold(
      appBar: AppBar(
        title: Text('Carrinho de Compras'),
      ),
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
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Confirmação de Pedido com Sucesso'),
                                    ),
                                  );
                                  checkAvailabilityBeforeOrder(total);
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
      bottomNavigationBar: Container(
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
                icon: Icon(Icons.notifications, color: Colors.white),
                onPressed: () {},
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
            ],
          ),
        ),
      ),
    );
  }
}
