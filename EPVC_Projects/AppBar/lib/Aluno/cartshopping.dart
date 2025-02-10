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
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

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
    var rng = Random();
    return min + rng.nextInt(max - min + 1);
  }

  Future<void> loadCartItems() async {
    final fetchedCartItems = await dbHelper.fetchCartItems();
    setState(() {
      cartItems = fetchedCartItems;
      updateItemCountMap();
    });
  }

  void showSnackBar(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<bool> sendOrderToApi(List<CartItem> cartItems, String total) async {
    int orderNumber = generateRandomNumber(1000, 9999);

    try {
      List<String> itemNames = cartItems.map((item) => item.name).toList();

      var turma = users[0]['Turma'];
      var nome = users[0]['Nome'];
      var apelido = users[0]['Apelido'];
      var permissao = users[0]['Permissao'];

      var response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=5&nome=$nome&apelido=$apelido&orderNumber=$orderNumber&valor=$dinheiroAtual&turma=$turma&permissao=$permissao&descricao=$itemNames&total=$total',
      ));

      if (response.statusCode == 200) {
        showSnackBar(
            'Pedido enviado com sucesso! Pedido Nº' + orderNumber.toString());
        return true; // Order sent successfully
      } else {
        showSnackBar('Erro ao enviar o pedido. Contacte o Administrador!');
        return false; // Order not sent
      }
    } catch (e) {
      print('Erro ao fazer a requisição GET: $e');
      showSnackBar(
          'Erro ao enviar o pedido. Contacte o Administrador! Error 01');
      return false; // Order not sent
    }
  }

  void sendOrderToWebSocket(List<CartItem> cartItems, String total) async {
    int orderNumber = generateRandomNumber(1000, 9999);

    try {
      List<String> itemNames = cartItems.map((item) => item.name).toList();
      var turma = users[0]['Turma'];
      var nome = users[0]['Nome'];
      var apelido = users[0]['Apelido'];
      var permissao = users[0]['Permissao'];

      final channel = WebSocketChannel.connect(
        Uri.parse('ws://websocket.appbar.epvc.pt'),
      );

      Map<String, dynamic> orderData = {
        'QPediu': nome,
        'NPedido': orderNumber,
        'Troco': dinheiroAtual,
        'Turma': turma,
        'Permissao': permissao,
        'Descricao': itemNames,
        'Total': total,
      };

      print('Sending over WebSocket: ${json.encode(orderData)}');

      channel.sink.add(json.encode(orderData));

      channel.stream.listen(
        (message) {
          var serverResponse = json.decode(message);
          if (serverResponse['status'] == 'success') {
            showSnackBar('Pedido enviado com sucesso! Pedido Nº' +
                orderNumber.toString());
          } else {
            showSnackBar(
                'Erro ao enviar o pedido. Contacte o Administrador! Error 02');
          }
          channel.sink.close(status.normalClosure);
        },
        onError: (error) {
          print('Erro ao fazer a requisição WebSocket: $error');
          showSnackBar(
              'Erro ao enviar o pedido. Contacte o Administrador! Error 01');
        },
      );
    } catch (e) {
      print('Erro ao estabelecer conexão WebSocket: $e');
      showSnackBar(
          'Erro ao enviar o pedido. Contacte o Administrador! Error 01');
    }
  }

  void updateItemCountMap() {
    itemCountMap.clear();
    for (var item in cartItems) {
      final itemName = item.name;
      if (itemName != null) {
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
    for (var order in recentOrders) {
      // Ensure data is not null and handle it explicitly
      var user = users.isNotEmpty ? users[0]['Email'] : ''; // Check if users list is not empty
      var localData = getLocalDate().toString(); // Convert local date to string explicitly
      var imagem = order.image ?? ''; // Use empty string if image is null
      var preco = order.price?.toString() ?? ''; // Ensure price is a string

      // Debugging: print out the data to be sent
      print('Sending order: $user, $localData, $imagem, $preco');

      var response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '6',
          'user': user,
          'orderDetails': order.name, // Send directly if it's a string
          'data': localData,
          'imagem': imagem,
          'preco': preco,
        },
      );

      // Debugging: print the response status code and body for more insight
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Pedido enviado com sucesso para a API');
      } else {
        print('Erro ao enviar pedido para a API');
      }
    }
  } catch (e) {
    print('Erro ao enviar pedidos para a API: $e');
  }
}


  Future<int> checkQuantidade(String productName) async {
    String productNamee = productName.replaceAll('"', '');

    var response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=8&nome=$productNamee'));

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> data =
          json.decode(response.body).cast<Map<String, dynamic>>();

      if (data.isNotEmpty) {
        int quantidade = data[0]['Qtd'];
        return quantidade;
      } else {
        throw Exception('Data is empty');
      }
    } else {
      throw Exception(
          'Failed to fetch data. Status code: ${response.statusCode}');
    }
  }

  Future<void> checkAvailabilityBeforeOrder(double total) async {
    bool allAvailable = true;
    List<String> unavailableItems = [];

    for (var item in cartItems) {
      var itemName = item.name;
      var quantity = await checkQuantidade(itemName);

      if (quantity == 0) {
        allAvailable = false;
        unavailableItems.add(itemName);
      }
    }

    if (cartItems.isNotEmpty) {
      if (allAvailable) {
                sendRecentOrderToApi(cartItems);

        sendOrderToApi(cartItems, total.toString());

        sendOrderToWebSocket(cartItems, total.toString());

        // Remove items from SQLite after successful order
        for (var item in cartItems) {
          await dbHelper.removeCartItem(item.id!);
        }

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
    showSnackBar('Item removido do carrinho');
  }

  @override
  Widget build(BuildContext context) {
    double total = calculateTotal();
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
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
                    (element) => element.name == itemName,
                  );

                  if (item == null) {
                    return SizedBox.shrink();
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
                      title: Text(item.name),
                      subtitle: Text('Quantidade: $itemCount'),
                      trailing: IconButton(
                        icon: Icon(Icons.remove_circle),
                        onPressed: () {
                          removeFromCart(item);
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
                    style:
                        TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
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
                                          content: Text(
                                              "Você tem o dinheiro (" +
                                                  total
                                                      .toStringAsFixed(2)
                                                      .replaceAll('.', ',') +
                                                  "€) EXATO ?"),
                                          actions: [
                                            TextButton(
                                              onPressed: () {
                                                showSnackBar(
                                                    'Confirmação de Pedido com Sucesso');
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
                                                            TextInputType
                                                                .number,
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
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            showSnackBar(
                                                                'Confirmação de Pedido com Sucesso');
                                                            checkAvailabilityBeforeOrder(
                                                                total);
                                                            Navigator.of(
                                                                    context)
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
      ),
    );
  }
}
