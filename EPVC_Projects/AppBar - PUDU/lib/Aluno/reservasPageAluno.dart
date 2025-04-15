import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Aluno/drawerHome.dart';
import 'package:my_flutter_project/Aluno/home.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Reservaspagealuno extends StatefulWidget {
  @override
  _ReservaspagealunoState createState() => _ReservaspagealunoState();
}

class _ReservaspagealunoState extends State<Reservaspagealuno> {
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
      await fetchReservation();
      
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
      } else {
        print("Failed to load user info");
      }
    }
  }

  Future<void> fetchReservation() async {
    if (users.isNotEmpty) {
      var user = users[0]['Email'];

      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': '8',
          'aluno': user,
        },
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

  Future<void> deleteReservation(String id) async {
    var user = users[0]['Email'];

    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': '9',
          'id': id,
          'aluno': user,
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          fetchReservation(); // Refresh the menu items
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Prato apagado com Sucesso')));
      } else {
        throw Exception('Error 02. Por Favor contacte o Administrador');
      }
    } catch (e) {
      print('Erro ao apagar prato: $e');
    }
  }

  void _confirmDelete(BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar Cancelamento da Reserva"),
          content: Text(
              "Tem certeza de que deseja cancelar a reserva Nº ${order["id"]}?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Fecha o diálogo
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                deleteReservation(order["id"]);
                Navigator.of(context).pop(); // Fecha o diálogo
              },
              child: Text("Confirmar", style: TextStyle(color: Colors.red)),
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
        title: Text('Reservas Feitas'),
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
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Nº Reserva: ${order["id"]}'),
                              if (order["estado"] ==
                                  '0') // Exibe o ícone apenas se puder ser apagado
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () =>
                                      _confirmDelete(context, order),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Descrição: ${order["description"].replaceAll('[', '').replaceAll(']', '')}'),
                              Text('Data: ${order["date"]}'),
                              Text('Hora: ${order["time"]}'),
                              Text(
                                'Estado: ${order["estado"] == '0' ? 'Por Reservar' : 'Reservado'}',
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
