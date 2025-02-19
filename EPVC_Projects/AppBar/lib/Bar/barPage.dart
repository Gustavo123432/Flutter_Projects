import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
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

  PurchaseOrder({
    required this.number,
    required this.requester,
    required this.group,
    required this.description,
    required this.total,
    required this.troco,
    required this.status,
    required this.userPermission,
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
      status: json['concluido']?.toString() ?? '0',
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

  // Fetch orders from API and filter only those with `concluido = 0`
  Future<void> _fetchInitialPurchaseOrders() async {
    try {
      final response = await http.get(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=10'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<PurchaseOrder> orders = data
            .map((json) => PurchaseOrder.fromJson(json))
            .where((order) => order.status == '0') // Filter where `status` is 0
            .toList();

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
  void _connectToWebSocket() {
    final channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.24.95'),
    );

    channel.stream.listen(
      (message) {
        if (message != null && message.isNotEmpty) {
          try {
            Map<String, dynamic> data = jsonDecode(message);
            PurchaseOrder order = PurchaseOrder.fromJson(data);

            // Add only orders with `concluido = 0`
            if (order.status == '0') {
              setState(() {
                currentOrders.add(order);
                purchaseOrderController.add(currentOrders);
              });
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

  // Function to prepare an order and check for matching products
  void _prepareOrder(PurchaseOrder currentOrder, List<PurchaseOrder> allOrders) {
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
              if (matchingOrders.isNotEmpty)
                Text('Os seguintes pedidos contêm produtos semelhantes:'),
              ...matchingOrders.map((order) {
                return ListTile(
                  title: Text('Pedido ${order.number} - ${order.requester}'),
                  subtitle: Text('Produtos: ${order.description}'),
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
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=17&nome=${order.requester}&npedido=${order.number}'));

    if (response.statusCode == 200) {
      // Remove the order from the list
      setState(() {
        currentOrders.removeWhere((item) => item.number == order.number);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido ${order.number} marcado como preparado.'),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao marcar o pedido como preparado.'),
        ),
      );
    }
  }


  void checkPedido(String orderNumber, String orderRequester) async {
    final response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=17&nome=$orderRequester&npedido=$orderNumber'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Pedido Concluído'),
        ),
      );
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
      body: Center(
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

            return ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                PurchaseOrder order = data[index];
                String formattedTotal = double.parse(order.total)
                    .toStringAsFixed(2)
                    .replaceAll('.', ',');

                 return Card(
                    margin: EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                    color: Color.fromARGB(255, 228, 225, 223),
                    elevation: 4.0,
                    child: ListTile(
                      title: Text(
                        'Pedido ${order.number} - ${order.requester}',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      subtitle: Text(
                        '${order.group}\n${order.description.replaceAll("[", "").replaceAll("]", "")}',
                        style: TextStyle(fontSize: 16),
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Total: $formattedTotal€'),
                          Text('Troco: ${order.troco}€'),
                          SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () {
                              _prepareOrder(order, data); // Call the prepare function
                            },
                            child: Text('Preparar'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    onTap: () {
                                                    _prepareOrder(order, data); // Call the prepare function

                      // Código para exibir detalhes do pedido
                     /* showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Detalhes do Pedido ${order.number}'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Requisitante: ${order.requester}'),
                                Text('Turma: ${order.group}'),
                                Text('Descrição: ${order.description.replaceAll("[", "").replaceAll("]", "")}'),
                                Text('Total: $formattedTotal€'),
                                Text('Troco: ${order.troco}€'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                child: Text('Fechar'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: Text('Eliminar Pedido'),
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
                      );*/
                    },
                  ),
                
              );
            },
          );
        },
      )),
    );
  }

  @override
  void dispose() {
    purchaseOrderController
        .close(); // Close the stream controller when widget is disposed
    super.dispose();
  }
}
