import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Bar/drawerBar.dart';
import 'package:my_flutter_project/Bar/produtoPageBar.dart';
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
        Uri.parse('http://appbar.epvc.pt//appBarAPI_GET.php?query_param=10'),
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
      Uri.parse('ws://snipeit.gfserver.pt:8080'),
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

  void checkPedido(String orderNumber, String orderRequester) async {
    final response = await http.get(Uri.parse(
        'http://appbar.epvc.pt//appBarAPI_GET.php?query_param=17&nome=$orderRequester&npedido=$orderNumber'));
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
        'http://appbar.epvc.pt//appBarAPI_GET.php?query_param=24&nome=$orderRequester&ids=$orderNumber'));
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

          // Ordenar a lista de pedidos, colocando os pedidos de professor no topo
          data.sort((a, b) {
            if (a.userPermission == 'Professor' &&
                b.userPermission != 'Professor') {
              return -1;
            } else if (a.userPermission != 'Professor' &&
                b.userPermission == 'Professor') {
              return 1;
            }
            return 0;
          });

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              PurchaseOrder order = data[index];
              String formattedTotal = double.parse(order.total)
                  .toStringAsFixed(2)
                  .replaceAll('.', ',');

              return Dismissible(
                key: Key(order.number
                    .replaceAll("[", "")
                    .replaceAll("]", "")), // Unique key
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Color.fromARGB(255, 130, 201, 189),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Icon(
                    Icons.check,
                    color: Colors.white,
                  ),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirmar Conclusão'),
                        content:
                            Text('Deseja marcar este pedido como concluído?'),
                        actions: [
                          TextButton(
                            child: Text('Cancelar'),
                            onPressed: () {
                              Navigator.of(context).pop(false);
                            },
                          ),
                          TextButton(
                            child: Text('Confirmar'),
                            onPressed: () {
                              checkPedido(order.number, order.requester);
                              Navigator.of(context)
                                  .pop(true); // Dismiss the dialog
                            },
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) {
                  setState(() {
                    // Remove the order from the list after confirmation
                    data.removeWhere((item) =>
                        item.number == order.number); // Update the list
                  });

                  // Show a snackbar or some feedback if needed
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text("Pedido ${order.number} foi concluído.")),
                  );
                },
                child: Card(
                  margin:
                      EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
                  color: Color.fromARGB(255, 228, 225, 223),
                  elevation: 4.0,
                  child: ListTile(
                    title: Text(
                      'Pedido ${order.number} - ${order.requester}',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18,),
                    ),
                    subtitle: Text(
                      '${order.group}\n${order.description.replaceAll("[", "").replaceAll("]", "")}',style: TextStyle(fontSize: 16),
                    ),
                    trailing: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('Total: $formattedTotal€'),
                        Text('Troco: ${order.troco}€'),
                      ],
                    ),
                    onTap: () {
                      // Código para exibir detalhes do pedido
                      showDialog(
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
                      );
                    },
                  ),
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
