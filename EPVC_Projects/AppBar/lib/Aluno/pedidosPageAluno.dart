import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Aluno/drawerHome.dart';
import 'package:my_flutter_project/Aluno/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PurchaseOrder {
  final String number;
  final String requester;
  final String group;
  final String description;
  final String total;
  final String status;

  PurchaseOrder({
    required this.number,
    required this.requester,
    required this.group,
    required this.description,
    required this.total,
    required this.status,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      number: json['NPedido'],
      requester: json['QPediu'],
      group: json['Turma'],
      description: json['Descricao'],
      total: json['Total'],
      status: json['Estado'],
    );
  }
}

  dynamic users = [];

class PedidosPageAlunos extends StatefulWidget {
  @override
  _PurchaseOrdersPageAlunoState createState() => _PurchaseOrdersPageAlunoState();
}

class _PurchaseOrdersPageAlunoState extends State<PedidosPageAlunos> {
  late Future<List<PurchaseOrder>> futurePurchaseOrders;
  String formattedTotal = "";

  @override
  void initState() {
    super.initState();
    futurePurchaseOrders = fetchPurchaseOrders();
    UserInfo();
  }

  void UserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    final response = await http.post(
      Uri.parse('http://appbar.epvc.pt//appBarAPI_Post.php'),
      body: {
        'query_param': '1',
        'user': user!,
      },
    );
    if (response.statusCode == 200) {
      setState(() {
        users = json.decode(response.body);
      });
    } else {
      print("Failed to fetch user information");
    }
  }

  Future<List<PurchaseOrder>> fetchPurchaseOrders() async {
  if (users == null) {
    print("User data is not available");
    return [];
  }

  var nome = users[0]['Nome'];
  var apelido = users[0]['Apelido'];
  var user = nome + " " + apelido;

  final response = await http.get(
    Uri.parse('http://appbar.epvc.pt//appBarAPI_GET.php?query_param=13&nome=$user'),
  );

  if (response.statusCode == 200) {
    List<dynamic> data = jsonDecode(response.body);
    List<PurchaseOrder> orders = data.map((json) => PurchaseOrder.fromJson(json)).toList();

    // Ordenar os pedidos por estado
    orders.sort((a, b) {
      if (a.status == b.status) {
        return 0;
      } else if (a.status == '0') {
        return -1; // Pedidos 'Por Fazer' aparecem primeiro
      } else {
        return 1; // Pedidos 'Concluído' aparecem depois
      }
    });

    return orders;
  } else {
    print("Failed to fetch purchase orders");
    throw Exception('Failed to load purchase orders');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos Registados'),
      ),
      body: Center(
        child: FutureBuilder<List<PurchaseOrder>>(
          future: futurePurchaseOrders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Failed to load purchase orders');
            } else if (snapshot.data!.isEmpty) {
              return Text('No purchase orders found');
            } else {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  PurchaseOrder order = snapshot.data![index];
                  try {
                    formattedTotal = double.parse(order.total)
                        .toStringAsFixed(2)
                        .replaceAll('.', ',');
                  } catch (e) {
                    formattedTotal = 'Invalid Total';
                  }
                  return Card(
                    elevation: 3,
                    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text('Nº Pedido: ${order.number.toString()}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Descrição: ${order.description.replaceAll('[', '').replaceAll(']', '')}'),
                          Text('Total: $formattedTotal€'),
                          Text(
                            'Estado: ${order.status == '0' ? 'Por Fazer' : 'Concluído'}',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
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
),
    );
  }
}
