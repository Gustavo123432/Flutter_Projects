import 'dart:convert';
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
/*

  Future<void> exportToPdf(List<PurchaseOrder> orders, BuildContext context) async {
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
    total += double.tryParse(order.total) ?? 0;
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

  if (kIsWeb) { // Use kIsWeb to check if running on web
    final blob = html.Blob([pdfData]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'purchase_orders.pdf')
      ..click();
    html.Url.revokeObjectUrl(url);
  } else {
    final directory = await getExternalStorageDirectory();
    final filePath = '${directory?.path}/purchase_orders.pdf';
    final file = io.File(filePath);
    await file.writeAsBytes(pdfData);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('PDF exportado com sucesso'),
      ),
    );
  }
}
 */


  Future<void> exportToPdf(List<PurchaseOrder> orders) async {
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

  double total = 0;
  for (var order in orders) {
    total += double.tryParse(order.total) ?? 0;
  }

  pdf.addPage(pw.Page(
    build: (pw.Context context) {
      return pw.Center(
        child: pw.Text('Total: ${total.toStringAsFixed(2)}'),
      );
    },
  ));

  final output = await getTemporaryDirectory();
  final file = File("${output.path}/purchase_orders.pdf");
  await file.writeAsBytes(await pdf.save());

  // Após salvar o arquivo PDF, você pode exibir uma mensagem ou realizar outra ação.
  // Por exemplo, mostrar um SnackBar informando que o PDF foi exportado com sucesso.
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('PDF exportado com sucesso'),
    ),
  );
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
    body: Container(
        width: double.infinity, // Usar toda a largura disponível
        height: double.infinity, // Usar toda a altura disponível
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/assets/epvc.png'), // Caminho para a sua imagem de fundo
            // fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Imagem de fundo
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255)
                      .withOpacity(0.80), // Cor preta com opacidade de 40%
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
                              Text('Estado: ${order.status == '0' ? 'Por Fazer' : 'Concluído'}'),
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
            exportToPdf(orders);
          },
        ),
        /*SpeedDialChild(
          child: Icon(Icons.recycling),
          onTap: () {
            removeAll(context);
          },
        ),*/
      ],
    ),
  );
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
        Uri.parse('http://api.gfserver.pt/appBarAPI_GET.php?query_param=12'));

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