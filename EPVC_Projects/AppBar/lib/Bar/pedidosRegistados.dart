import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart'; // Import Print Bluetooth Thermal

class PurchaseOrder {
  final String number;
  final String requester;
  final String group;
  final String description;
  final String total;
  final String status;
  final String data;
  final String hora;

  PurchaseOrder({
    required this.number,
    required this.requester,
    required this.group,
    required this.description,
    required this.total,
    required this.status,
    required this.data,
    required this.hora,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      number: json['NPedido'],
      requester: json['QPediu'],
      group: json['Turma'],
      description: json['Descricao'],
      data: json['Data'],
      hora: json['Hora'],
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
  late DateTime selectedDate;
  late String formattedDate;
  late String formattedTime;
  late TimeOfDay selectedTime;

  @override
  void initState() {
    super.initState();
    purchaseOrderStream = Stream.empty();
    horaPretendidaController = TextEditingController();
    pedidos = [];
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDateTimePicker();
    });
  }

  Future<void> _showDateTimePicker() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Color.fromARGB(255, 130, 201, 189),
            ),
          ),
          child: child!,
        );
      },
    );

    if (date != null) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        setState(() {
          selectedDate = date;
          selectedTime = time;
          formattedDate = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';
          formattedTime = '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';
        });
        fetchPurchaseOrders();
      }
    }
  }

  Future<void> fetchPurchaseOrders() async {
    final response = await http.get(
      Uri.parse('http://appbar.epvc.pt/appBarAPI_GET.php?query_param=19&horaPretendida=$formattedTime&dataPretendida=$formattedDate'),
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
    if (await _requestStoragePermission()) {
      final pdfBytes = await _generatePdf(horaPretendida);
      await _printBluetooth(pdfBytes);
    } else {
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

  Future<Uint8List> _generatePdf(String horaPretendida) async {
    final pdf = pw.Document();
    double totalGeral = 0.0;

    final fontData = await rootBundle.load('lib/assets/fonts/Roboto-Regular.ttf');
    final ttf = pw.Font.ttf(fontData);

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Lista de Pedidos', style: pw.TextStyle(fontSize: 20, font: ttf)),
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
                      pw.Text('Descrição: ${pedido.description.replaceAll("[", "").replaceAll("]", "")}', style: pw.TextStyle(font: ttf)),
                      pw.Text('Data: ${pedido.data}', style: pw.TextStyle(font: ttf)),
                      pw.Text('Hora: ${pedido.hora}', style: pw.TextStyle(font: ttf)),
                      pw.Text('Total: ${pedido.total.replaceAll(".", ",")}€', style: pw.TextStyle(font: ttf)),
                      pw.Text('Estado: ${pedido.status == '0' ? 'Por Fazer' : 'Concluído'}', style: pw.TextStyle(font: ttf)),
                      pw.Divider(),
                    ],
                  );
                }).toList(),
              ),
              pw.Text('Total Geral: ${totalGeral.toString().replaceAll(".", ",")}€', style: pw.TextStyle(font: ttf)),
            ],
          );
        },
      ),
    );

    final bytes = await pdf.save();
    final directory = await getExternalStorageDirectory();
    final file = File('${directory!.path}/pedido_registado_$horaPretendida.pdf');
    await file.writeAsBytes(bytes);

    OpenFile.open(file.path);

    return bytes;
  }

  Future<void> _printBluetooth(Uint8List pdfBytes) async {
    bool isConnected = await PrintBluetoothThermal.connectionStatus;
    if (!isConnected) {
      await PrintBluetoothThermal.startScan(timeout: Duration(seconds: 5));
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;

      if (devices.isNotEmpty) {
        await PrintBluetoothThermal.connect(macPrinterAddress: devices.first.macAddress);
      } else {
        print('No Bluetooth devices found.');
        return;
      }
    }

    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    // Convert the PDF data into ESC/POS commands
    List<int> escPosCommands = generator.text(
      String.fromCharCodes(pdfBytes),
      styles: PosStyles(align: PosAlign.left, bold: true),
    );

    // Send ESC/POS commands to the printer
    await PrintBluetoothThermal.writeBytes(Uint8List.fromList(escPosCommands));
    print('Printed successfully.');
  }

  Future<bool> _requestStoragePermission() async {
    PermissionStatus status = await Permission.storage.request();
    return status.isGranted;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedidos Registados'),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
            child: Icon(Icons.picture_as_pdf),
            label: 'Gerar PDF',
            onTap: () => generatePdf(horaPretendidaController.text),
          ),
        ],
      ),
      body: StreamBuilder<List<PurchaseOrder>>(
        stream: purchaseOrderStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading purchase orders.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No purchase orders found.'));
          } else {
            final orders = snapshot.data!;
            return ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return ListTile(
                  title: Text('Nº Pedido: ${order.number}'),
                  subtitle: Text('Total: ${order.total.replaceAll(".", ",")}€'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
