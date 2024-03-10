import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Admin/drawerAdmin.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

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

class PedidosPage extends StatefulWidget {
  @override
  _PurchaseOrdersPageState createState() => _PurchaseOrdersPageState();
}

class _PurchaseOrdersPageState extends State<PedidosPage> {
  late Future<List<PurchaseOrder>> futurePurchaseOrders;
  String formattedTotal = "";

  @override
  void initState() {
    super.initState();
    futurePurchaseOrders = fetchPurchaseOrders();
  }

  Future<List<PurchaseOrder>> fetchPurchaseOrders() async {
    final response = await http.get(
        Uri.parse('http://api.gfserver.pt/appBarAPI_GET.php?query_param=9'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PurchaseOrder.fromJson(json)).toList();
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
                Navigator.of(context).pop(); // Close the AlertDialog
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
                        builder: (BuildContext ctx) => const LoginForm()));
                ModalRoute.withName('/');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> exportToPdf(List<PurchaseOrder> orders, var totall) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Table.fromTextArray(
            data: <List<String>>[
              ['Nº Pedido', 'Quem pediu', 'Turma', 'Descrição', 'Total    ', 'Estado'],
              for (var order in orders)
                [
                  order.number,
                  order.requester,
                  order.group,
                  order.description.replaceAll('[', '').replaceAll(']', ''),
                  totall + "€",
                  order.status == '0' ? 'Por Fazer' : 'Concluído',
                ],
            ],
          ),
        ],
      ),
    );

    double total = 0;
    for (var order in orders) {
      total += double.tryParse(order.total) ?? 0;
    }

    pdf.addPage(pw.Page(
      build: (pw.Context context) {
        return pw.Center(
          child: pw.Text('Total: ${total.toStringAsFixed(2)}€'),
        );
      },
    ));

    final bytes = await pdf.save();
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', 'purchase_orders.pdf')
      ..click();

    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        title: Text('Registo de Pedidos'),
        actions: [
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      drawer: DrawerAdmin(),
      body: Center(
        child: FutureBuilder<List<PurchaseOrder>>(
          future: futurePurchaseOrders,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
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
                          Text('Quem pediu: ${order.requester}'),
                          Text('Turma: ${order.group}'),
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
      floatingActionButton: SpeedDial(
        icon: Icons.more_horiz,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 130, 201, 189),
        children: [
          SpeedDialChild(
            child: Icon(Icons.backup),
            onTap: () async {
              final orders = await futurePurchaseOrders;
              exportToPdf(orders, formattedTotal);
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.recycling),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
