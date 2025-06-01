import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Admin/drawerAdmin.dart';
import 'package:my_flutter_project/Bar/produtoPageBar.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
//coment
/*
import 'dart:io' as io;
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
*/
//finish coment

class PurchaseOrder {
  final String number;
  final String requester;
  final String group;
  final String description;
  final String total;
  final String status;
  final String data;

  PurchaseOrder({
    required this.number,
    required this.requester,
    required this.group,
    required this.description,
    required this.total,
    required this.status,
    required this.data,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      number: json['NPedido'],
      requester: json['QPediu'],
      group: json['Turma'],
      description: json['Descricao'],
      total: json['Total'],
      status: json['Estado'],
      data: json['Data'],
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
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=9'));
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => PurchaseOrder.fromJson(json)).toList();
    } else {
      throw Exception('Atualize a Página');
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
                
              },
            ),
          ],
        );
      },
    );
  }
  //coment
Future<void> exportToPdf(List<PurchaseOrder> orders, String selectedDate, BuildContext context) async {
  final pdf = pw.Document();
  double total = 0;
  pdf.addPage(
    pw.MultiPage(
      build: (pw.Context context) => [
        pw.Table.fromTextArray(
          data: <List<String>>[
            [
              'Nº Pedido',
              'Quem pediu',
              'Turma',
              'Descrição',
              'Total',
              'Estado'
            ],
            for (var order in orders)
              if (order.data.split(' ').first == selectedDate)
                [
                  order.number,
                  order.requester,
                  order.group,
                  order.description.replaceAll('[', '').replaceAll(']', ''),
                  order.total,
                  order.status == '0' ? 'Por Fazer' : 'Concluído',
                ],
          ],
        ),
      ],
    ),
  );
  for (var order in orders) {
    if (order.data.split(' ').first == selectedDate) {
      total += double.tryParse(order.total.replaceAll(',', '.')) ?? 0;
    }
  }
  pdf.addPage(pw.Page(
    build: (pw.Context context) {
      return pw.Center(
        child: pw.Text('Total: ${total.toStringAsFixed(2)}€'),
      );
    },
  ));
  final bytes = await pdf.save();
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/pedidos_$selectedDate.pdf');
  await file.writeAsBytes(bytes);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('PDF exportado para ${file.path}')),
  );
}
//finish coment


  @override
  Widget build(BuildContext context) {
    return Scaffold(
 
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'lib/assets/epvc.png',
              fit: BoxFit.scaleDown,
            ),
          ),
          // Centered logo
          Positioned.fill(
            child: Center(
              child: Opacity(
                opacity: 0.12, // semi-transparent
                child: Image.asset(
                  'lib/assets/logo.png',
                  width: 260,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          // White overlay and content
          Positioned.fill(
            child: Container(
              color: Color.fromARGB(255, 255, 255, 255).withOpacity(0.85),
              child: FutureBuilder<List<PurchaseOrder>>(
                future: futurePurchaseOrders,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Sem Dados', style: TextStyle(fontSize: 18, color: Colors.red)));
                  } else if (snapshot.data == null || snapshot.data!.isEmpty) {
                    return Center(child: Text('Nenhum pedido encontrado.', style: TextStyle(fontSize: 18)));
                  } else {
                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 24, horizontal: 8),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        PurchaseOrder order = snapshot.data![index];
                        String formattedTotal;
                        try {
                          formattedTotal = double.parse(order.total)
                              .toStringAsFixed(2)
                              .replaceAll('.', ',');
                        } catch (e) {
                          formattedTotal = 'Invalid Total';
                        }
                        Color statusColor = order.status == '0' ? Colors.orange : Colors.green;
                        String statusText = order.status == '0' ? 'Por Fazer' : 'Concluído';
                        return Card(
                          elevation: 4,
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Nº Pedido: ${order.number}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.15),
                                        border: Border.all(color: statusColor),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        statusText,
                                        style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.person, size: 18, color: Colors.blueGrey),
                                    SizedBox(width: 6),
                                    Text('Quem pediu: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                    Expanded(child: Text(order.requester)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.group, size: 18, color: Colors.blueGrey),
                                    SizedBox(width: 6),
                                    Text('Turma: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                    Expanded(child: Text(order.group)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.description, size: 18, color: Colors.blueGrey),
                                    SizedBox(width: 6),
                                    Text('Descrição: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                    Expanded(child: Text(order.description.replaceAll('[', '').replaceAll(']', ''))),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.euro, size: 18, color: Colors.blueGrey),
                                    SizedBox(width: 6),
                                    Text('Total: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                    Text('$formattedTotal€', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today, size: 18, color: Colors.blueGrey),
                                    SizedBox(width: 6),
                                    Text('Data: ', style: TextStyle(fontWeight: FontWeight.w500)),
                                    Text(order.data),
                                  ],
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
          ),
        ],
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
              _showDatePicker(orders);
            },
          ),
        ],
      ),
    );
  }

Future<void> _showDatePicker(List<PurchaseOrder> orders) async {
  final DateTime? selectedDate = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2100),
    builder: (BuildContext context, Widget? child) {
      return Theme(
        data: ThemeData.light().copyWith(
          colorScheme: ColorScheme.light(primary: Color.fromARGB(255, 130, 201, 189)),
        ),
        child: child!,
      );
    },
  );
  if (selectedDate != null) {
    final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    await exportToPdf(orders, formattedDate, context);
  }
}

  Future<void> removeAll(context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar'),
          content: const Text('Pretende Eliminar todos os Dados?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                removeAllApi();
                Navigator.of(context).pop();
                setState(() {
                  // Atualiza os dados chamando novamente fetchPurchaseOrders
                  futurePurchaseOrders = fetchPurchaseOrders();
                });
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> removeAllApi() async {
    var response = await http.get(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=12'));

    if (response.statusCode == 200) {
      setState(() {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pedidos eliminados com Sucesso'),
          ),
        );
      });
    }
  }
}
