import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Admin/drawerAdmin.dart';
import 'package:appbar_epvc/Bar/produtoPageBar.dart';
import 'package:appbar_epvc/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart';

// Conditional imports for web platform
import 'dart:html' if (dart.library.io) 'dart:io' as platform;

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
  try {
    final pdf = pw.Document();
    double total = 0;

    // Load a font that supports Euro symbol
    final font = await rootBundle.load("lib/assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(font: ttf, fontSize: 12),
            cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
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
          child: pw.Text(
            'Total: ${total.toStringAsFixed(2)}€',
            style: pw.TextStyle(font: ttf, fontSize: 14),
          ),
        );
      },
    ));

    final bytes = await pdf.save();
    
    if (kIsWeb) {
      // For web platform
      final blob = platform.Blob([bytes], 'application/pdf');
      final url = platform.Url.createObjectUrlFromBlob(blob);
      final anchor = platform.AnchorElement(href: url)
        ..setAttribute('download', 'pedidos_$selectedDate.pdf')
        ..click();
      platform.Url.revokeObjectUrl(url);
    } else {
      // For mobile/desktop platforms
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/pedidos_$selectedDate.pdf');
      await file.writeAsBytes(bytes);
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exportado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}
//finish coment

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

Future<void> _showExportOptions(List<PurchaseOrder> orders) async {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Exportar'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.receipt_long),
              title: Text('Exportar Pedidos'),
              onTap: () {
                Navigator.pop(context);
                _showDatePicker(orders);
              },
            ),
            ListTile(
              leading: Icon(Icons.inventory),
              title: Text('Exportar Produtos Vendidos'),
              onTap: () {
                Navigator.pop(context);
                _showDatePickerForProducts(orders);
              },
            ),
          ],
        ),
      );
    },
  );
}

Future<void> _showDatePickerForProducts(List<PurchaseOrder> orders) async {
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
    await exportProductsToPdf(orders, formattedDate, context);
  }
}

Future<void> exportProductsToPdf(List<PurchaseOrder> orders, String selectedDate, BuildContext context) async {
  try {
    final pdf = pw.Document();
    
    // Load a font that supports Euro symbol
    final font = await rootBundle.load("lib/assets/fonts/Roboto-Regular.ttf");
    final ttf = pw.Font.ttf(font);

    // Group products by name and count occurrences
    Map<String, int> productCount = {};
    Map<String, double> productTotal = {};
    
    for (var order in orders) {
      if (order.data.split(' ').first == selectedDate) {
        // Split the description into individual products
        final products = order.description
            .replaceAll('[', '')
            .replaceAll(']', '')
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
            
        for (var product in products) {
          productCount[product] = (productCount[product] ?? 0) + 1;
          // Add the total value divided by the number of products
          final orderTotal = double.tryParse(order.total.replaceAll(',', '.')) ?? 0;
          productTotal[product] = (productTotal[product] ?? 0) + (orderTotal / products.length);
        }
      }
    }

    // Sort products by count
    var sortedProducts = productCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text(
              'Produtos Vendidos - $selectedDate',
              style: pw.TextStyle(font: ttf, fontSize: 20),
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(font: ttf, fontSize: 12, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(font: ttf, fontSize: 10),
            headerDecoration: pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
            },
            data: <List<String>>[
              ['Produto', 'Quantidade', 'Preço Unitário', 'Total', 'Média'],
              ...sortedProducts.map((entry) {
                final total = productTotal[entry.key] ?? 0;
                final quantity = entry.value;
                final unitPrice = total / quantity;
                final averagePrice = total / quantity;
                return [
                  entry.key,
                  entry.value.toString(),
                  '${unitPrice.toStringAsFixed(2)}€',
                  '${total.toStringAsFixed(2)}€',
                  '${averagePrice.toStringAsFixed(2)}€',
                ];
              }),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Total de Produtos Vendidos: ${productCount.values.fold(0, (sum, count) => sum + count)}',
            style: pw.TextStyle(font: ttf, fontSize: 12),
          ),
          pw.Text(
            'Total em Vendas: ${productTotal.values.fold(0.0, (sum, total) => sum + total).toStringAsFixed(2)}€',
            style: pw.TextStyle(font: ttf, fontSize: 12),
          ),
        ],
      ),
    );

    final bytes = await pdf.save();
    
    if (kIsWeb) {
      // For web platform
      final blob = platform.Blob([bytes], 'application/pdf');
      final url = platform.Url.createObjectUrlFromBlob(blob);
      final anchor = platform.AnchorElement(href: url)
        ..setAttribute('download', 'produtos_vendidos_$selectedDate.pdf')
        ..click();
      platform.Url.revokeObjectUrl(url);
    } else {
      // For mobile/desktop platforms
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/produtos_vendidos_$selectedDate.pdf');
      await file.writeAsBytes(bytes);
      
      // Show success message with file path
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exportado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao gerar PDF: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}

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
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.white);
              },
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
                  errorBuilder: (context, error, stackTrace) {
                    return Container();
                  },
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
            child: Icon(Icons.picture_as_pdf),
            label: 'Exportar PDF',
            onTap: () async {
              final orders = await futurePurchaseOrders;
              _showExportOptions(orders);
            },
          ),
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
