import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Bar/drawerBar.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:intl/intl.dart';
//import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart'; // Import Print Bluetooth Thermal

class Order {
  final String number;
  final String requester;
  final String description;
  final String total;
  final String status;
  final String date;

  Order({
    required this.number,
    required this.requester,
    required this.description,
    required this.total,
    required this.status,
    required this.date,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      number: json['NPedido']?.toString() ?? 'N/A',
      requester: json['QPediu'] ?? 'Desconhecido',
      description: json['Descricao']?.toString() ?? 'Sem descrição',
      total: json['Total']?.toString() ?? '0.00',
      status: json['Estado']?.toString() ?? '0',
      date: json['Data']?.toString() ?? '',
    );
  }
}

class PedidosRegistadosPage extends StatefulWidget {
  @override
  _PedidosRegistadosPageState createState() => _PedidosRegistadosPageState();
}

class _PedidosRegistadosPageState extends State<PedidosRegistadosPage> {
  late Future<List<Order>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
  }

  Future<List<Order>> _fetchOrders() async {
    try {
      final response = await http.get(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=10'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<Order> orders = data.map((json) => Order.fromJson(json)).toList();
        // Sort orders by date, most recent first
        orders.sort((a, b) {
            try {
              DateTime aDate = DateFormat('dd/MM/yyyy').parse(a.date);
              DateTime bDate = DateFormat('dd/MM/yyyy').parse(b.date);
              return bDate.compareTo(aDate);
            } catch(e) {
              return 0;
            }
        });
        return orders;
      } else {
        throw Exception('Erro ao carregar pedidos.');
      }
    } catch (e) {
      throw Exception('Erro ao carregar pedidos: ${e.toString()}');
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case '0':
        return 'Pendente';
      case '1':
        return 'Em Preparação';
      case '2':
        return 'Concluído';
      default:
        return 'Desconhecido';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '0':
        return Colors.red;
      case '1':
        return Colors.orange;
      case '2':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Pedidos'),
        backgroundColor: Colors.orange,
      ),
      body: FutureBuilder<List<Order>>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Colors.orange));
          } else if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('Nenhum pedido encontrado.'));
          }

          final orders = snapshot.data!;
          return ListView.builder(
            padding: EdgeInsets.all(8.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 4,
                margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pedido #${order.number}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.orange[800],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusText(order.status),
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 16, thickness: 1),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Requisitante: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: order.requester),
                          ]
                        )
                      ),
                      SizedBox(height: 4),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: 'Data: ', style: TextStyle(fontWeight: FontWeight.bold)),
                            TextSpan(text: order.date),
                          ]
                        )
                      ),
                       SizedBox(height: 8),
                      Text('Descrição:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text(order.description),
                      SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Total: ${order.total}€',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
