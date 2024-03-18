import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Bar/drawerBar.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseOrder {
  final String number;
  final String requester;
  final String group;
  final String description;
  final String total;
  final String status;
  final String userPermission;

  PurchaseOrder({
    required this.number,
    required this.requester,
    required this.group,
    required this.description,
    required this.total,
    required this.status,
    required this.userPermission,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      number: json['NPedido'],
      requester: json['QPediu'],
      group: json['Turma'],
      description: json['Descricao'],
      total: json['Total'],
      status: json['Estado'],
      userPermission: json['Permissao'],
    );
  }
}

class BarPagePedidos extends StatefulWidget {
  @override
  _BarPagePedidosState createState() => _BarPagePedidosState();
}

class _BarPagePedidosState extends State<BarPagePedidos> {
  late Stream<List<PurchaseOrder>> purchaseOrderStream;
  String formattedTotal = "";

  @override
  void initState() {
    super.initState();
    purchaseOrderStream = Stream.periodic(Duration(seconds: 1), (_) {
      return fetchPurchaseOrders();
    }).asyncMap((_) => fetchPurchaseOrders());
  }

  Future<List<PurchaseOrder>> fetchPurchaseOrders() async {
    final response = await http.get(
        Uri.parse('http://api.gfserver.pt/appBarAPI_GET.php?query_param=10'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PurchaseOrder.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load purchase orders');
    }
  }

  void checkPedido(String orderNumber, String orderRequester) async {
    final response = await http.get(Uri.parse(
        'http://api.gfserver.pt/appBarAPI_GET.php?query_param=17&nome=$orderRequester&npedido=$orderNumber'));
    if (response.statusCode == 200) {
      setState(() async {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Valor atualizado com sucesso no banco de dados!'),
          ),
        );
      });
    } else {
      throw Exception('Failed to load purchase orders');
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
                    builder: (BuildContext ctx) => const LoginForm(),
                  ),
                );
                ModalRoute.withName('/');
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
              return Text('Sem Pedidos');
            } else {
              List<PurchaseOrder>? data = snapshot.data;
              if (data == null || data.isEmpty) {
                return Text('Sem Pedidos');
              }
              
              // Ordenar a lista de pedidos, colocando os pedidos de professor no topo
              data.sort((a, b) {
                if (a.userPermission == 'Professor' && b.userPermission != 'Professor') {
                  return -1;
                } else if (a.userPermission != 'Professor' && b.userPermission == 'Professor') {
                  return 1;
                }
                return 0;
              });
              
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  PurchaseOrder order = data[index];
                  try {
                    formattedTotal = double.parse(order.total)
                        .toStringAsFixed(2)
                        .replaceAll('.', ',');
                  } catch (e) {
                    formattedTotal = 'Invalid Total';
                  }
                  
                  return Dismissible(
                    key: Key(order.number),
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
                    onDismissed: (direction) {},
                    confirmDismiss: (direction) async {
                      return await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Confirmar Conclusão'),
                            content: Text(
                                'Deseja marcar este pedido como concluído?'),
                            actions: <Widget>[
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text('Cancelar'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  checkPedido(order.number, order.requester);
                                  Navigator.of(context).pop(false);
                                },
                                child: Text('Confirmar'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      elevation: 3,
                      margin:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: order.userPermission == 'Professor'
                          ? Colors.red
                          : null,
                      child: ListTile(
                        title:
                            Text('Nº Pedido: ${order.number.toString()}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quem pediu: ${order.requester}'),
                            Text('Turma: ${order.group}'),
                            Text(
                                'Descrição: ${order.description.replaceAll('[', '').replaceAll(']', '')}'),
                            Text('Total: $formattedTotal€'),
                            Text(
                              'Estado: ${order.status == '0' ? 'Por Fazer' : 'Concluído'}',
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: BarPagePedidos(),
  ));
}
