import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Aluno/drawerHome.dart';
import 'package:my_flutter_project/Aluno/home.dart';
import 'package:my_flutter_project/assets/models/cartItem.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:intl/intl.dart';
import 'package:diacritic/diacritic.dart'; // Import the diacritic package
import 'package:my_flutter_project/assets/sqflite/databasehelper.dart';

class ShoppingCartPage extends StatefulWidget {
  @override
  _ShoppingCartPageState createState() => _ShoppingCartPageState();
}

class _ShoppingCartPageState extends State<ShoppingCartPage> {
  Map<String, int> itemCountMap = {};
  dynamic users;
  double dinheiroAtual = 0;
  List<CartItem> cartItems = [];
  final DatabaseHelper dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    updateItemCountMap();
    UserInfo();
    loadCartItems();
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

  Future<void> loadCartItems() async {
    final dbHelper = DatabaseHelper();
    final fetchedCartItems = await dbHelper.fetchCartItems();
    setState(() {
      cartItems = fetchedCartItems;
      updateItemCountMap();
    });
  }

  void sendOrderToApi(List<CartItem> cartItems, String total) async {
    // Generate a random order number
    int orderNumber = generateRandomNumber(1000, 9999);

    try {
      // Extracting names from cart items
      List<String> itemNames = cartItems.map((item) => item as String).toList();

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

  void sendOrderToWebSocket(List<CartItem> cartItems, String total) async {
    int orderNumber = generateRandomNumber(1000, 9999);

    try {
      // Check if cartItems is not empty
      print('Cart items: $cartItems'); // Debugging

      // Extract item names or any other needed data
      List<String> itemNames = cartItems.map((item) => item as String).toList();
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
      final itemName = item.name;
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
      double preco = double.parse(item.price.toString());
      total += preco;
    }
    return total;
  }

  String getLocalDate() {
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd').format(now);
    return formattedDateTime;
  }

  Future<void> sendRecentOrderToApi(List<CartItem> recentOrders) async {
    try {
      // Obter informações do usuário do primeiro usuário na lista de usuários
      var nome = users[0]['Nome'];
      var apelido = users[0]['Apelido'];

      for (var order in recentOrders) {
        // Concatenar informações do usuário para formar o identificador do usuário
        var user = nome + " " + apelido;
        var localData = getLocalDate();

        // Extrair a imagem se não for nula, caso contrário, use uma string vazia
        var imagem = order.image ?? '';
        var preco = order.price ?? '';

        // Enviar solicitação POST para a API para cada pedido
        var response = await http.post(
          Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
          body: {
            'query_param': '6',
            'user': user,
            'orderDetails': json.encode(order.name),
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
      var itemName = item.name;
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

  void removeFromCart(CartItem cartItem) {
    setState(() {
      cartItems.remove(cartItem);
      dbHelper.removeCartItem(cartItem.id!);

      updateItemCountMap();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Item removido do carrinho')),
    );
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
                // Find the CartItem with the same name
                final item = cartItems.firstWhere(
                  (element) => element.name == itemName,
                );

                if (item == null) {
                  return SizedBox.shrink(); // Skip if item is not found
                }

                final image = base64.decode(item.image);

                return Card(
                  child: ListTile(
                    leading: image.isNotEmpty
                        ? Image.memory(
                            image,
                            fit: BoxFit.cover,
                            height: 50,
                            width: 50,
                          )
                        : SizedBox.shrink(),
                    title: Text(item.name), // Use item.name instead of itemName
                    subtitle: Text('Quantidade: $itemCount'),
                    trailing: IconButton(
                      icon: Icon(Icons.remove_circle),
                      onPressed: () {
                        setState(() {
                          // Remove CartItem from cartItems list
                          removeFromCart(
                              item); // Pass the actual CartItem object
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
