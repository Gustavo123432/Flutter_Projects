import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Bar/drawerBar.dart';
import 'package:my_flutter_project/Bar/produtoPageBar.dart';
import 'package:my_flutter_project/login.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseOrder {
  final String number;
  final String requester;
  final String group;
  final String description;
  final String total;
  final String troco;
  final String status;
  final String userPermission;
  final String imagem;

  PurchaseOrder({
    required this.number,
    required this.requester,
    required this.group,
    required this.description,
    required this.total,
    required this.troco,
    required this.status,
    required this.userPermission,
    required this.imagem,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      number: json['NPedido']?.toString() ?? 'N/A',
      requester: json['QPediu'] ?? 'Desconhecido',
      group: json['Turma'] ?? 'Sem turma',
      description: (json['Descricao'] is List)
          ? (json['Descricao'] as List)
              .join(', ') // Join list items with a comma
          : json['Descricao']?.toString() ?? 'Sem descrição',
      total: json['Total']?.toString() ?? '0.00',
      troco: json['Troco']?.toString() ?? '0.00',
      status: json['Estado']?.toString() ?? '0',
      imagem: json['Imagem'] ?? '',
      userPermission: json['Permissao'] ?? 'Sem permissão',
    );
  }
}

class BarPagePedidos extends StatefulWidget {
  @override
  _BarPagePedidosState createState() => _BarPagePedidosState();
}

class _BarPagePedidosState extends State<BarPagePedidos> {
  late Stream<List<PurchaseOrder>> purchaseOrderStream;
  final StreamController<List<PurchaseOrder>> purchaseOrderController =
      StreamController.broadcast();
  List<PurchaseOrder> currentOrders = [];
  int cont = 0;

  @override
  void initState() {
    super.initState();
    purchaseOrderStream = getPurchaseOrdersStream();
    _fetchInitialPurchaseOrders();
  }

  // Fetch orders from API and filter only those with concluido = 0
  Future<void> _fetchInitialPurchaseOrders() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=10'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<PurchaseOrder> orders =
            data.map((json) => PurchaseOrder.fromJson(json)).toList();

        currentOrders = orders;
        purchaseOrderController.add(currentOrders);

        _connectToWebSocket(); // Connect to WebSocket after initial fetch
      } else {
        throw Exception('Erro ao carregar pedidos. Verifique a Internet.');
      }
    } catch (e) {
      print('Erro ao buscar pedidos: $e');
    }
  }

  // WebSocket connection and message handling
  List<PurchaseOrder> processedOrders =
      []; // Track processed orders to avoid duplication

  void _connectToWebSocket() {
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.25.94:2536'), // Your WebSocket server address
    );

    channel.stream.listen(
      (message) {
        if (message != null && message.isNotEmpty) {
          try {
            Map<String, dynamic> data = jsonDecode(message);
            PurchaseOrder order = PurchaseOrder.fromJson(data);

            // Check if the order has already been processed (based on NPedido)
            if (order.status == '0' &&
                !processedOrders.any((processedOrder) =>
                    processedOrder.number == order.number)) {
              setState(() {
                currentOrders.add(order); // Add the new order to the list
                purchaseOrderController.add(currentOrders);
                processedOrders.add(order); // Mark this order as processed
              });
            } else {
              print(
                  'Duplicate order detected: ${order.number}'); // Optionally log the duplicate order
            }
          } catch (e) {
            print('Erro ao processar a mensagem: $e');
          }
        }
      },
      onError: (error) => print('Erro WebSocket: $error'),
      onDone: () => channel.sink.close(),
    );
  }

  Stream<List<PurchaseOrder>> getPurchaseOrdersStream() {
    return purchaseOrderController.stream;
  }

  Uint8List safeBase64Decode(String base64String) {
    try {
      // Ensure correct padding
      while (base64String.length % 4 != 0) {
        base64String += '=';
      }
      return base64Decode(base64String);
    } catch (e) {
      print("Base64 decoding error: $e");
      return Uint8List(0); // Return empty Uint8List if there's an error
    }
  }

  String cleanBase64(String input) {
    return input.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
  }

// Usage

  void _prepareOrder(
      PurchaseOrder currentOrder, List<PurchaseOrder> allOrders) {
    // Get the products in the current order
    List<String> currentProducts = currentOrder.description
        .split(',')
        .map((product) => product.trim())
        .toList();

    // Find other orders with the same products
    List<PurchaseOrder> matchingOrders = allOrders.where((order) {
      List<String> orderProducts = order.description
          .split(',')
          .map((product) => product.trim())
          .toList();
      return orderProducts.any((product) => currentProducts.contains(product));
    }).toList();

    // Remove the current order from the matching list (if present)
    matchingOrders.removeWhere((order) => order.number == currentOrder.number);

    // Show a dialog with the matching orders
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Pedidos com Produtos Semelhantes'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Você está preparando o pedido ${currentOrder.number}.'),
              SizedBox(height: 10),
              Text.rich(
                TextSpan(
                  children: currentOrder.description
                      .replaceAll('[', '')
                      .replaceAll(']', '')
                      .split(',')
                      .map((item) => TextSpan(
                            text:
                                '\t\t\t• ${item.trim()}\n', // Adiciona tab antes do marcador
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ))
                      .toList(),
                ),
              ),
              if (matchingOrders.isNotEmpty)
                Text('Os seguintes pedidos contêm produtos semelhantes:'),
              ...matchingOrders.map((order) {
                return ListTile(
                  title: Text('Pedido ${order.number} - ${order.requester}'),
                  subtitle: Text(
                      'Produtos: ${order.description.replaceAll("[", "").replaceAll("]", "")}'),
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Preparar Apenas Este'),
              onPressed: () {
                // Prepare only the current order
                _markOrderAsPrepared(currentOrder);
                Navigator.of(context).pop();
              },
            ),
            if (matchingOrders.isNotEmpty)
              TextButton(
                child: Text('Preparar Todos'),
                onPressed: () {
                  // Prepare all matching orders
                  _markOrderAsPrepared(currentOrder);
                  matchingOrders.forEach((order) {
                    _markOrderAsPrepared(order);
                  });
                  Navigator.of(context).pop();
                },
              ),
          ],
        );
      },
    );
  }

  // Function to mark an order as prepared
  void _markOrderAsPrepared(PurchaseOrder order) async {
    // Call your API to mark the order as prepared
    final response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=17&nome=${order.requester}&npedido=${order.number}&op=1'));

    if (response.statusCode == 200) {
      // Remove the order from the list

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido ${order.number} em preparação.'),
        ),
      );
      setState(() {
        _fetchInitialPurchaseOrders();
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Erro ao colocar o pedido em preparação.\n Contacte o Administrador'),
        ),
      );
    }
  }

  void checkPedido(String orderNumber, String orderRequester) async {
    final response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=17&nome=$orderRequester&npedido=$orderNumber&op=2'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido Concluído'),
        ),
      );
      setState(() {
        _fetchInitialPurchaseOrders();
      });
    } else {
      throw Exception('Erro ao verificar pedido. Verifique a Internet.');
    }
  }

  void apagarpedido(String orderNumber, String orderRequester) async {
    final response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=24&nome=$orderRequester&ids=$orderNumber'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido Eliminado'),
        ),
      );
    } else {
      throw Exception('Erro ao eliminar pedido. Verifique a Internet.');
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
        title: Text('Pedidos'),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      drawer: DrawerBar(),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: StreamBuilder<List<PurchaseOrder>>(
            stream: purchaseOrderStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return Text('Erro ao carregar pedidos');
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Text('Sem Pedidos');
              }

              List<PurchaseOrder> data = snapshot.data!;

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // 4 cards per row
                  crossAxisSpacing: 8, // Horizontal spacing between cards
                  mainAxisSpacing: 8, // Vertical spacing between cards
                  childAspectRatio: 1.0, // Width/height ratio of the cards
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  PurchaseOrder order = data[index];
                  String formattedTotal = double.parse(order.total)
                      .toStringAsFixed(2)
                      .replaceAll('.', ',');
                  print(order.imagem);
                  String base64String = order.imagem.toString();
                  String cleanedBase64 = cleanBase64(base64String);
                  Uint8List decodedBytes = safeBase64Decode(cleanedBase64);

                  // Determine button color based on status
                  Color buttonColor;
                  String? buttonText;
                  switch (int.parse(order.status)) {
                    case 1:
                      buttonColor = const Color.fromARGB(
                          255, 221, 163, 2); // Status 1 - Yellow
                      buttonText = "Concluir";
                      break;

                    default:
                      buttonColor =
                          Color.fromARGB(255, 175, 175, 175); // Default - Gray
                      buttonText = "Preparar";
                  }

                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              'Detalhes do Pedido ${order.number}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Requisitante: ${order.requester}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Turma: ${order.group}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Descrição:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text.rich(
                                    TextSpan(
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                      children: order.description
                                          .replaceAll('[', '')
                                          .replaceAll(']', '')
                                          .split(',')
                                          .map((item) => TextSpan(
                                                text: '• ${item.trim()}\n',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold),
                                              ))
                                          .toList(),
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Total: $formattedTotal€',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Troco: ${order.troco}€',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  // Card para a imagem
                                  Card(
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        decodedBytes,
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) {
                                          return Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.grey[300],
                                            child: Icon(
                                              Icons.error,
                                              color: Colors.red,
                                              size: 40,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: Text(
                                  'Fechar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text(
                                  'Eliminar Pedido',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.red,
                                  ),
                                ),
                                onPressed: () {
                                  apagarpedido(order.number, order.requester);
                                  data.removeWhere(
                                      (item) => item.number == order.number);
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      color: Color.fromARGB(
                          255, 228, 225, 223), // Cor de fundo do Card
                      elevation: 4.0, // Sombra do Card
                      child: Padding(
                        padding: EdgeInsets.all(12.0), // Espaçamento interno
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Linha com os detalhes do pedido e a imagem
                            Row(
                              children: [
                                // Coluna com os detalhes do pedido
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pedido ${order.number}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Nome: ${order.requester}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Turma: ${order.group}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Descrição: ${order.description.replaceAll("[", "").replaceAll("]", "")}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                    width:
                                        12), // Espaçamento entre a coluna de texto e a imagem
                                // Imagem do pedido
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(
                                      8), // Bordas arredondadas na imagem
                                  child: Image.memory(
                                    decodedBytes,
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 100,
                                        height: 100,
                                        color: Colors.grey[300],
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.red,
                                          size: 40,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                height:
                                    12), // Espaçamento entre a linha e a próxima seção
                            // Linha com o total e o troco
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: $formattedTotal€',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'Troco: ${order.troco}€',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(
                                height:
                                    12), // Espaçamento entre o texto e o botão
                            // Botão de ação (Preparar/Concluir)
                            ElevatedButton(
                              onPressed: () {
                                if (buttonText == "Preparar") {
                                  _prepareOrder(order, data);
                                } else if (buttonText == "Concluir") {
                                  checkPedido(order.number, order.requester);
                                }
                              },
                              child: Text(
                                buttonText,
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                minimumSize: Size(
                                    double.infinity, 40), // Altura do botão
                                padding: EdgeInsets.symmetric(horizontal: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    purchaseOrderController
        .close(); // Close the stream controller when widget is disposed
    super.dispose();
  }
}
