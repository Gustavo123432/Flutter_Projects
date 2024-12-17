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
//coment

import 'dart:io' as io;
import 'dart:html' as html;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';

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
        Uri.parse('http://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=9'));
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
  final regularFont = await http.get(Uri.parse("lib/assets/fonts/Roboto-Regular.ttf"));
  final Uint8List fontData = regularFont.bodyBytes;
  final pdf = pw.Document();

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
              'Total    ',
              'Estado      '
            ],
            for (var order in orders)
              if (order.data == selectedDate) // Verifica se a data do pedido corresponde à data selecionada
                [
                  order.number,
                  order.requester,
                  order.group,
                  order.description.replaceAll('[', '').replaceAll(']', ''),
                  order.total,
                  order.status == '0' ? 'Por Fazer' : 'Concluído',
                ],
          ],
          cellStyle: pw.TextStyle(font: pw.Font.ttf(fontData.buffer.asByteData())),
        ),
      ],
    ),
  );

  double total = 0;
  for (var order in orders) {
    // Converta a data do objeto para o formato yyyy-mm-dd
    String orderDateFormatted = order.data.split(' ')[0];
    // Verifique se a data do pedido corresponde à data selecionada
    if (orderDateFormatted == selectedDate) {
      total += double.tryParse(order.total) ?? 0;
    }
  }

  pdf.addPage(pw.Page(
    build: (pw.Context context) {
      return pw.Center(
        child: pw.Text('Total: ${total.toStringAsFixed(2)}', style: pw.TextStyle(font: pw.Font.ttf(fontData.buffer.asByteData()))),
      );
    },
  ));

  final pdfBytes = await pdf.save();
  final pdfData = Uint8List.fromList(pdfBytes);

  if (kIsWeb) {
    final blob = html.Blob([pdfData]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'purchase_orders_$selectedDate.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    final directory = await getExternalStorageDirectory();
    final filePath = '${directory?.path}/purchase_orders_$selectedDate.pdf';
    final file = io.File(filePath);
    await file.writeAsBytes(pdfData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF exportado com sucesso'),
      ),
    );
  }
}
//finish coment


  @override
  Widget build(BuildContext context) {
    return Scaffold(
     /* appBar: AppBar(
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
      drawer: DrawerAdmin(),*/
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/epvc.png'),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255).withOpacity(0.80),
                ),
              ),
            ),
            Center(
              child: FutureBuilder<List<PurchaseOrder>>(
                future: futurePurchaseOrders,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Sem Dados');
                  } else {
                    return ListView.builder(
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
                        return Card(
                          elevation: 3,
                          margin:
                              EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                                    'Estado: ${order.status == '0' ? 'Por Fazer' : 'Concluído'}'),
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
          ],
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
          // Define a cor de fundo do seletor de data aqui
          colorScheme: ColorScheme.light(primary: Color.fromARGB(255, 130, 201, 189)),
        ),
        child: child!,
      );
    },
  );

  /*if (selectedDate != null) {
    // Formate a data selecionada para o formato yyyy-mm-dd
    final formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
    exportToPdf(orders, formattedDate, context);
  }*/
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
        Uri.parse('http://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=12'));

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
