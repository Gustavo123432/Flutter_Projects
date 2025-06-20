import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appbar_epvc/Bar/drawerBar.dart';
import 'package:appbar_epvc/login.dart';

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
  final String paymentMethod;

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
    required this.paymentMethod,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      number: json['NPedido']?.toString() ?? 'N/A',
      requester: json['QPediu'] ?? 'Desconhecido',
      group: json['Turma'] ?? 'Sem turma',
      description: (json['Descricao'] is List)
          ? (json['Descricao'] as List).join(', ')
          : json['Descricao']?.toString() ?? 'Sem descrição',
      total: json['Total']?.toString() ?? '0.00',
      troco: json['Troco']?.toString() ?? '0.00',
      status: json['Estado']?.toString() ?? '0',
      imagem: json['Imagem'] ?? '',
      userPermission: json['Permissao'] ?? 'Sem permissão',
      paymentMethod: json['payment_method'] ?? json['MetodoDePagamento'] ?? 'dinheiro',
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
  WebSocketChannel? _channel;

  @override
  void initState() {
    super.initState();
    purchaseOrderStream = getPurchaseOrdersStream();
    _fetchInitialPurchaseOrders();
    _connectToWebSocket();
  }

  Future<void> _fetchInitialPurchaseOrders() async {
    try {
      final response = await http.get(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=10'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<PurchaseOrder> orders =
            data.map((json) => PurchaseOrder.fromJson(json)).toList();
        

        setState(() {
          currentOrders = orders.where((order) => order.status != '2').toList();
          purchaseOrderController.add(currentOrders);
        });
      } else {
        throw Exception('Erro ao carregar pedidos. Verifique a Internet.');
      }
    } catch (e) {
      print('Erro ao buscar pedidos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pedidos: ${e.toString()}')),
      );
    }
  }

  void _connectToWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.25.94:2536'),
      );

      _channel!.stream.listen(
        (message) {
          if (message != null && message.isNotEmpty) {
            try {
              Map<String, dynamic> data = jsonDecode(message);
              PurchaseOrder order = PurchaseOrder.fromJson(data);

              setState(() {
                // Remove completed orders (status 2)
                if (order.status == '2') {
                  currentOrders.removeWhere((o) => o.number == order.number);
                } 
                // Update existing orders
                else {
                  int index = currentOrders.indexWhere((o) => o.number == order.number);
                  if (index >= 0) {
                    currentOrders[index] = order;
                  } else if (order.status == '0') {
                    currentOrders.add(order);
                  }
                }
                purchaseOrderController.add(currentOrders);
              });
            } catch (e) {
              print('Erro ao processar a mensagem: $e');
            }
          }
        },
        onError: (error) {
          print('Erro WebSocket: $error');
          // Tentar reconectar após um erro
          Future.delayed(Duration(seconds: 5), () {
            if (mounted) {
              _connectToWebSocket();
            }
          });
        },
        onDone: () {
          print('Conexão WebSocket fechada');
          // Tentar reconectar quando a conexão for fechada
          Future.delayed(Duration(seconds: 5), () {
            if (mounted) {
              _connectToWebSocket();
            }
          });
        },
        cancelOnError: false, // Não cancelar a inscrição em caso de erro
      );
    } catch (e) {
      print('Erro ao estabelecer conexão WebSocket: $e');
      // Tentar reconectar em caso de erro na conexão inicial
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          _connectToWebSocket();
        }
      });
    }
  }

  Stream<List<PurchaseOrder>> getPurchaseOrdersStream() {
    return purchaseOrderController.stream.distinct();
  }

  Uint8List safeBase64Decode(String base64String) {
    try {
      String cleaned = base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
      while (cleaned.length % 4 != 0) {
        cleaned += '=';
      }
      return base64Decode(cleaned);
    } catch (e) {
      return Uint8List(0);
    }
  }

  String cleanBase64(String input) {
    return input.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
  }

  // Função auxiliar para processar a descrição e agrupar itens iguais
  Map<String, int> processDescription(String description) {
    Map<String, int> items = {};
    
    // Primeiro, substituir vírgulas em números decimais por ponto
    String processedDesc = description.replaceAllMapped(
      RegExp(r'(\d+),(\d+)'),
      (match) => '${match.group(1)}.${match.group(2)}'
    );
    
    // Agora dividir por vírgulas, mas apenas as que não estão dentro de números
    List<String> products = processedDesc
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((product) => product.trim())
        .where((product) => product.isNotEmpty)
        .toList();

    for (String product in products) {
      // Extrair quantidade e nome do produto
      RegExp regex = RegExp(r'(\d+)\s*x\s*(.*)');
      Match? match = regex.firstMatch(product);
      
      if (match != null) {
        int quantity = int.parse(match.group(1)!);
        String itemName = match.group(2)!.trim();
        // Substituir ponto de volta por vírgula para exibição
        itemName = itemName.replaceAll('.', ',');
        items[itemName] = (items[itemName] ?? 0) + quantity;
      } else {
        // Se não encontrar o padrão de quantidade, assume 1
        // Substituir ponto de volta por vírgula para exibição
        String itemName = product.replaceAll('.', ',');
        items[itemName] = (items[itemName] ?? 0) + 1;
      }
    }
    return items;
  }

  void _prepareOrder(PurchaseOrder currentOrder, List<PurchaseOrder> allOrders) {
    // Processar produtos do pedido atual
    Map<String, int> currentProducts = processDescription(currentOrder.description);

    // Encontrar pedidos com produtos semelhantes
    List<PurchaseOrder> matchingOrders = allOrders.where((order) {
      Map<String, int> orderProducts = processDescription(order.description);
      return orderProducts.keys.any((product) => currentProducts.containsKey(product));
    }).toList();

    matchingOrders.removeWhere((order) => order.number == currentOrder.number);
    matchingOrders.removeWhere((order) => int.parse(order.status) != 0);

    // Agregar produtos de todos os pedidos relevantes
    Map<String, int> productCounts = Map.from(currentProducts);
    
    // Adicionar produtos dos pedidos correspondentes
    for (PurchaseOrder order in matchingOrders) {
      Map<String, int> orderProducts = processDescription(order.description);
      orderProducts.forEach((product, quantity) {
        productCounts[product] = (productCounts[product] ?? 0) + quantity;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: AlertDialog(
            title: Text('Pedidos com Produtos Semelhantes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Está a preparar o pedido ${currentOrder.number}.'),
                SizedBox(height: 10),
                
                // Display aggregated product counts
                Text('Total de produtos a preparar:'),
                SizedBox(height: 5),
                ...productCounts.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Text(
                      '• ${entry.value}x ${entry.key}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),
                
                SizedBox(height: 15),
                Text('Produtos no pedido atual:'),
                Text.rich(
                  TextSpan(
                    children: currentProducts.entries.map((entry) {
                      return TextSpan(
                        text: '\t\t\t• ${entry.value}x ${entry.key}\n',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ),
                
                if (matchingOrders.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Text('Os seguintes pedidos contêm produtos semelhantes:'),
                  ...matchingOrders.map((order) {
                    Map<String, int> orderProducts = processDescription(order.description);
                    return ListTile(
                      title: Text('Pedido ${order.number} - ${order.requester}'),
                      subtitle: Text(
                        'Produtos: ${orderProducts.entries.map((e) => '${e.value}x ${e.key}').join(', ')}'
                      ),
                    );
                  }).toList(),
                ],
              ],
            ),
            actions: [
              TextButton(
                child: Text('Preparar Apenas Este'),
                onPressed: () {
                  _markOrderAsPrepared(currentOrder);
                  Navigator.of(context).pop();
                },
              ),
              if (matchingOrders.isNotEmpty)
                TextButton(
                  child: Text('Preparar Todos'),
                  onPressed: () {
                    _markOrderAsPrepared(currentOrder);
                    matchingOrders.forEach((order) {
                      _markOrderAsPrepared(order);
                    });
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markOrderAsPrepared(PurchaseOrder order) async {
    try {
      final response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=17&nome=${order.requester}&npedido=${order.number}&op=1'));

      if (response.statusCode == 200) {
        setState(() {
          int index = currentOrders.indexWhere((o) => o.number == order.number);
          if (index >= 0) {
            currentOrders[index] = PurchaseOrder(
              number: order.number,
              requester: order.requester,
              group: order.group,
              description: order.description,
              total: order.total,
              troco: order.troco,
              status: '1', // Set status to 1 (Preparar)
              userPermission: order.userPermission,
              imagem: order.imagem,
              paymentMethod: order.paymentMethod,
            );
            purchaseOrderController.add(currentOrders);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao preparar pedido. Código: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao preparar pedido: ${e.toString()}')),
      );
    }
  }
  

  Future<void> _markOrderAsCompleted(PurchaseOrder order) async {
    try {
      final response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=17&nome=${order.requester}&npedido=${order.number}&op=2'));

      if (response.statusCode == 200) {
        setState(() {
          currentOrders.removeWhere((o) => o.number == order.number);
          purchaseOrderController.add(currentOrders);
        });

        // Mostrar diálogo em vez do SnackBar
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                title: Text(
                  'Pedido Concluído',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                content: Text(
                  'O pedido ${order.number} foi concluído com sucesso!',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: Color.fromARGB(255, 246, 141, 45),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao concluir pedido. Código: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao concluir pedido: ${e.toString()}')),
      );
    }
  }

  void _showDeleteDialog(PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eliminar Pedido"),
        content: Text("Deseja eliminar este pedido?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteOrder(order);
            },
            child: Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(PurchaseOrder order) async {
    try {
      final response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=24&nome=${order.requester}&ids=${order.number}'));

      if (response.statusCode == 200) {
        setState(() {
          currentOrders.removeWhere((o) => o.number == order.number);
          purchaseOrderController.add(currentOrders);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido eliminado com sucesso.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao eliminar pedido. Código: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao eliminar pedido: ${e.toString()}')),
      );
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (ctx) => LoginForm()),
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
                return FutureBuilder(
                  future: Future.delayed(Duration(seconds: 5)),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(
                          child:
                              CircularProgressIndicator());
                    } else {
                      return Center(
                          child: Text(
                              'Sem Pedidos'));
                    }
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Erro ao carregar pedidos'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Sem Pedidos'));
              }

              List<PurchaseOrder> data = snapshot.data!;

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  PurchaseOrder order = data[index];
                  String formattedTotal = double.parse(order.total)
                      .toStringAsFixed(2)
                      .replaceAll('.', ',');
                  String base64String = order.imagem.toString();
                  String cleanedBase64 = cleanBase64(base64String);
                  Uint8List decodedBytes = safeBase64Decode(cleanedBase64);

                  // Processar a descrição para agrupar itens
                  Map<String, int> groupedItems = processDescription(order.description);
                  String groupedDescription = groupedItems.entries
                      .map((e) => '${e.value}x ${e.key}')
                      .join(', ');

                  Color buttonColor;
                  String? buttonText;
                  switch (int.parse(order.status)) {
                    case 1:
                      buttonColor = const Color.fromARGB(255, 221, 163, 2);
                      buttonText = "Concluir";
                      break;
                    default:
                      buttonColor = Color.fromARGB(255, 175, 175, 175);
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
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                      children: groupedItems.entries.map((entry) {
                                        return TextSpan(
                                          text: '• ${entry.value}x ${entry.key}\n',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        );
                                      }).toList(),
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
                                    'Troco: ${double.parse(order.troco).toStringAsFixed(2).replaceAll('.', ',')}€',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Text(
                                        'Método de Pagamento: ',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: order.paymentMethod.toLowerCase() == 'mbway' 
                                              ? Color.fromARGB(255, 232, 240, 254) 
                                              : order.paymentMethod.toLowerCase() == 'saldo'
                                                  ? Colors.orange[50]
                                              : Color.fromARGB(255, 239, 249, 239),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: order.paymentMethod.toLowerCase() == 'mbway' 
                                                ? Colors.red
                                                : order.paymentMethod.toLowerCase() == 'saldo'
                                                    ? Colors.orange[700]!
                                                : Color.fromARGB(255, 76, 175, 80),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              order.paymentMethod.toLowerCase() == 'mbway'
                                                  ? Icons.phone_android
                                                  : order.paymentMethod.toLowerCase() == 'saldo'
                                                      ? Icons.account_balance_wallet
                                                      : Icons.money,
                                              size: 16,
                                              color: order.paymentMethod.toLowerCase() == 'mbway'
                                                  ? Colors.red
                                                  : order.paymentMethod.toLowerCase() == 'saldo'
                                                      ? Colors.orange[700]
                                                      : Color.fromARGB(255, 76, 175, 80),
                                            ),
                                            SizedBox(width: 4),
                                            Text(
                                              order.paymentMethod.toLowerCase() == 'mbway'
                                                  ? 'MBWay'
                                                  : order.paymentMethod.toLowerCase() == 'saldo'
                                                      ? 'Saldo'
                                                      : 'Dinheiro',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: order.paymentMethod.toLowerCase() == 'mbway' 
                                                ? Colors.red
                                                    : order.paymentMethod.toLowerCase() == 'saldo'
                                                        ? Colors.orange[700]
                                                : Color.fromARGB(255, 76, 175, 80),
                                          ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
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
                                  _showDeleteDialog(order);
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      color: Color.fromARGB(255, 228, 225, 223),
                      elevation: 4.0,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                        'Descrição: $groupedDescription',
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
                                SizedBox(width: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
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
                            SizedBox(height: 12),
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
                                  'Troco: ${double.parse(order.troco).toStringAsFixed(2).replaceAll('.', ',')}€',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            // Display payment method
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: order.paymentMethod.toLowerCase() == 'mbway' 
                                        ? Color.fromARGB(255, 232, 240, 254) 
                                        : order.paymentMethod.toLowerCase() == 'saldo'
                                            ? Colors.orange[50]
                                        : Color.fromARGB(255, 239, 249, 239),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: order.paymentMethod.toLowerCase() == 'mbway' 
                                          ? Colors.red
                                          : order.paymentMethod.toLowerCase() == 'saldo'
                                              ? Colors.orange[700]!
                                          : Color.fromARGB(255, 76, 175, 80),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        order.paymentMethod.toLowerCase() == 'mbway'
                                            ? Icons.phone_android
                                            : order.paymentMethod.toLowerCase() == 'saldo'
                                                ? Icons.account_balance_wallet
                                                : Icons.money,
                                        size: 16,
                                        color: order.paymentMethod.toLowerCase() == 'mbway'
                                            ? Colors.red
                                            : order.paymentMethod.toLowerCase() == 'saldo'
                                                ? Colors.orange[700]
                                                : Color.fromARGB(255, 76, 175, 80),
                                      ),
                                      SizedBox(width: 4),
                                      Text(
                                        order.paymentMethod.toLowerCase() == 'mbway'
                                            ? 'MBWay'
                                            : order.paymentMethod.toLowerCase() == 'saldo'
                                                ? 'Saldo'
                                                : 'Dinheiro',
                                    style: TextStyle(
                                          fontSize: 12,
                                      color: order.paymentMethod.toLowerCase() == 'mbway' 
                                          ? Colors.red
                                              : order.paymentMethod.toLowerCase() == 'saldo'
                                                  ? Colors.orange[700]
                                          : Color.fromARGB(255, 76, 175, 80),
                                    ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () {
                                if (buttonText == "Preparar") {
                                  _prepareOrder(order, data);
                                } else if (buttonText == "Concluir") {
                                  _markOrderAsCompleted(order);
                                }
                              },
                              child: Text(
                                buttonText!,
                                style: TextStyle(fontSize: 12),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: buttonColor,
                                foregroundColor: Colors.white,
                                minimumSize: Size(double.infinity, 40),
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
    _channel?.sink.close();
    purchaseOrderController.close();
    super.dispose();
  }
} 