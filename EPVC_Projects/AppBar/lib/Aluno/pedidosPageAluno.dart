import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Aluno/drawerHome.dart';
import 'package:my_flutter_project/Aluno/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PedidosPageAlunos extends StatefulWidget {
  @override
  _PedidosPageAlunosState createState() => _PedidosPageAlunosState();
}

class _PedidosPageAlunosState extends State<PedidosPageAlunos> {
  List<dynamic> users = [];
  List<dynamic> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserInfoAndOrders();
  }

  Future<void> fetchUserInfoAndOrders() async {
    await fetchUserInfo();
    if (users.isNotEmpty) {
      await fetchPurchaseOrders();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    if (user != null) {
      final response = await http.post(
        Uri.parse('http://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '1',
          'user': user,
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
      } else {
        print("Failed to load user info");
      }
    }
  }

  Future<void> fetchPurchaseOrders() async {
    if (users.isNotEmpty) {
      var nome = users[0]['Nome'];
      var apelido = users[0]['Apelido'];
      var user = '$nome $apelido';

      final response = await http.get(
        Uri.parse(
            'http://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=13&nome=$user'),
      );
      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(response.body);
        });
      } else {
        print("Failed to load orders");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos Registados'),
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
      body: Center(
        child: isLoading
            ? CircularProgressIndicator()
            : orders.isNotEmpty
                ? ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      var order = orders[index];
                      var formattedTotal = "";
                      try {
                        formattedTotal = double.parse(order['Total'])
                            .toStringAsFixed(2)
                            .replaceAll('.', ',');
                      } catch (e) {
                        formattedTotal = 'Invalid Total';
                      }

                      return Card(
                        elevation: 3,
                        margin:
                            EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        child: ListTile(
                          title: Text('Nº Pedido: ${order["NPedido"]}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Descrição: ${order["Descricao"].replaceAll('[', '').replaceAll(']', '')}'),
                              Text('Data: ${order["Data"]}'),
                              Text('Hora: ${order["Hora"]}'),
                              Text('Total: $formattedTotal€'),
                              Text(
                                'Estado: ${order["Estado"] == '0' ? 'Por Fazer' : 'Concluído'}',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                : Text("No orders found"),
      ),
    );
  }
}
