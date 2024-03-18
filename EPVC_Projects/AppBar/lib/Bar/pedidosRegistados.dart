import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Bar/produtoPageBar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:my_flutter_project/Bar/drawerBar.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
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

class PedidosRegistados extends StatefulWidget {
  @override
  _PedidosRegistadosState createState() => _PedidosRegistadosState();
}

class _PedidosRegistadosState extends State<PedidosRegistados> {
  late Stream<List<PurchaseOrder>> purchaseOrderStream;
  late TextEditingController horaPretendidaController;
  late List<PurchaseOrder> pedidos;

  @override
  void initState() {
    super.initState();
    purchaseOrderStream = Stream.empty();
    horaPretendidaController = TextEditingController();
    pedidos = [];
    WidgetsBinding.instance!.addPostFrameCallback((_) {
      askForTime();
    });
  }

  Future<void> askForTime() async {
    horaPretendidaController.text = '';
    showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Informe a Hora Pretendida'),
          content: TextField(
            controller: horaPretendidaController,
            decoration: InputDecoration(hintText: 'HH:MM'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                fetchPurchaseOrders(horaPretendidaController.text);
                Navigator.of(context).pop();
              },
              child: Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> fetchPurchaseOrders(String horaPretendida) async {
    final response = await http.get(
      Uri.parse(
          'http://api.gfserver.pt/appBarAPI_GET.php?query_param=19&horaPretendida=$horaPretendida'),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      setState(() {
        pedidos = data.map((json) => PurchaseOrder.fromJson(json)).toList();
        purchaseOrderStream = Stream.value(pedidos);
      });
    } else {
      throw Exception('Failed to load purchase orders');
    }
  }

  Future<void> generatePdf(String horaPretendida) async {
    // Solicitar permissão de armazenamento
    if (await _requestStoragePermission()) {
      // Permissão concedida, gerar PDF
      await _generatePdf(horaPretendida);
    } else {
      // Permissão negada
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Permissão Necessária'),
            content: Text('Por favor, conceda permissão de armazenamento para gerar PDF.'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
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
                        builder: (BuildContext ctx) =>  LoginForm()));
                ModalRoute.withName('/');
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _requestStoragePermission() async {
    var status = await Permission.storage.status;
    if (!status.isGranted) {
      // Solicitar permissão de armazenamento
      var result = await Permission.storage.request();
      return result.isGranted;
    }
    return true; // Permissão já concedida
  }

  Future<void> _generatePdf(String horaPretendida) async {
    final pdf = pw.Document();
    double totalGeral = 0.0;

    // Carregar a fonte
    final fontData = await rootBundle.load('lib/assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    // Adiciona uma página ao PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Lista de Pedidos', style: pw.TextStyle(fontSize: 20)),
              pw.SizedBox(height: 20),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: pedidos.map((pedido) {
                  totalGeral += double.parse(pedido.total.replaceAll(',', '.'));
                  return pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Nº Pedido: ${pedido.number}', style: pw.TextStyle(font: ttf)),
                      pw.Text('Quem pediu: ${pedido.requester}', style: pw.TextStyle(font: ttf)),
                      pw.Text('Turma: ${pedido.group}', style: pw.TextStyle(font: ttf)),
                      pw.Text('Descrição: ${pedido.description}', style: pw.TextStyle(font: ttf)),
                      pw.Text('Total: ${pedido.total}', style: pw.TextStyle(font: ttf)),
                      pw.Text(
                        'Estado: ${pedido.status == '0' ? 'Por Fazer' : 'Concluído'}',
                        style: pw.TextStyle(font: ttf),
                      ),
                      pw.Divider(),
                    ],
                  );
                }).toList(),
              ),
              pw.Text('Total Geral: $totalGeral', style: pw.TextStyle(font: ttf)), // Exibe o total geral no PDF
            ],
          );
        },
      ),
    );

    // Converte o PDF para bytes
    final bytes = await pdf.save();

    // Salva o PDF localmente
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/pedido_registado_$horaPretendida.pdf');
    await file.writeAsBytes(bytes);

    // Abre o PDF na mesma aplicação
    OpenFile.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
         backgroundColor: Color.fromARGB(255, 246, 141, 45),
        title: Text('Pedidos Registados'),
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
      floatingActionButton: SpeedDial(
        icon: Icons.more_horiz,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 130, 201, 189),
        children: [
          SpeedDialChild(
            child: Icon(Icons.picture_as_pdf),
            onTap: () async {
          generatePdf(horaPretendidaController.text);
            }
          ),
          SpeedDialChild(
            child: Icon(Icons.av_timer),
            onTap: () {
              setState(() {
                askForTime();
              });
            },
          ),
        ],
      ),
      body: Center(
        child: StreamBuilder<List<PurchaseOrder>>(
          stream: purchaseOrderStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Erro: ${snapshot.error}');
            } else {
              List<PurchaseOrder>? data =
                  snapshot.data as List<PurchaseOrder>?;
              if (data == null || data.isEmpty) {
                return Text('Sem pedidos');
              }
              return ListView.builder(
                itemCount: data.length,
                itemBuilder: (context, index) {
                  PurchaseOrder order = data[index];
                  return ListTile(
                    title: Text('Nº Pedido: ${order.number}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Quem pediu: ${order.requester}'),
                        Text('Turma: ${order.group}'),
                        Text('Descrição: ${order.description}'),
                        Text('Total: ${order.total}'),
                        Text(
                          'Estado: ${order.status == '0' ? 'Por Fazer' : 'Concluído'}',
                        ),
                      ],
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

  @override
  void dispose() {
    horaPretendidaController.dispose();
    super.dispose();
  }
}
