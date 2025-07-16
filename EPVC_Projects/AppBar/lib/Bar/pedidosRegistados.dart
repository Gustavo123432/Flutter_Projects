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
import 'package:appbar_epvc/config/app_config.dart';

class Order {
  final String number;
  final String requester;
  final String description;
  final String total;
  final String status;
  final String date;
  final String hour; // Added for filtering by time

  Order({
    required this.number,
    required this.requester,
    required this.description,
    required this.total,
    required this.status,
    required this.date,
    required this.hour, // Initialize hour
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      number: json['NPedido']?.toString() ?? 'N/A',
      requester: json['QPediu'] ?? 'Desconhecido',
      description: json['Descricao']?.toString() ?? 'Sem descrição',
      total: json['Total']?.toString() ?? '0.00',
      status: json['Estado']?.toString() ?? '0',
      date: json['Data']?.toString() ?? '',
      hour: json['Hora']?.toString() ?? '00:00', // Extract hour from JSON
    );
  }
}

class PedidosRegistadosPage extends StatefulWidget {
  @override
  _PedidosRegistadosPageState createState() => _PedidosRegistadosPageState();
}

class _PedidosRegistadosPageState extends State<PedidosRegistadosPage> {
  late Future<List<Order>> _ordersFuture;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay(hour: 0, minute: 0);

  @override
  void initState() {
    super.initState();
    _ordersFuture = _fetchOrders();
    // Removido o addPostFrameCallback automático para evitar erro de contexto.
  }

  bool _dateTimeSelected = false;

  void _onSelectDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023, 1),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'PT'),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (pickedTime != null) {
        setState(() {
          _selectedTime = pickedTime;
          _dateTimeSelected = true;
        });
      }
    }
  }

  Future<List<Order>> _fetchOrders() async {
    // Buscar todos os pedidos da API, sem filtrar por estado
    final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=9'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    } else {
      throw Exception('Erro ao buscar pedidos');
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2023, 1),
      lastDate: DateTime.now(),
      locale: const Locale('pt', 'PT'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  List<Order> _filterOrders(List<Order> orders) {
    if (!_dateTimeSelected) return orders; // Se não filtrou, mostra todos
    final selectedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final selectedTime = _selectedTime;
    return orders.where((order) {
      final orderDate = order.date;
      final orderTime = TimeOfDay(
        hour: int.parse(order.hour.split(":")[0]),
        minute: int.parse(order.hour.split(":")[1]),
      );
      final isSameDate = orderDate == selectedDate;
      final isAfterTime = orderTime.hour > selectedTime.hour || (orderTime.hour == selectedTime.hour && orderTime.minute >= selectedTime.minute);
      return isSameDate && isAfterTime;
    }).toList();
  }

  double _getTotalFaturado(List<Order> orders) {
    return orders.fold(0.0, (sum, o) => sum + double.tryParse(o.total.replaceAll(',', '.'))!);
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

  String formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'pt_PT', symbol: '', decimalDigits: 2);
    return formatter.format(value).trim().replaceAll('.', ',');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Pedidos'),
        backgroundColor: Colors.orange,
      ),
      drawer: DrawerBar(),
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

          final allOrders = snapshot.data!;
          final filteredOrders = _filterOrders(allOrders);
          final totalFaturado = _getTotalFaturado(filteredOrders);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickDate(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.calendar_today, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(DateFormat('dd/MM/yyyy').format(_selectedDate),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _pickTime(context),
                        child: Container(
                          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.access_time, color: Colors.orange),
                              SizedBox(width: 8),
                              Text(_selectedTime.format(context),
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: Icon(Icons.filter_alt),
                      label: Text('Filtrar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      onPressed: () => setState(() => _dateTimeSelected = true),
                    ),
                    if (_dateTimeSelected)
                      IconButton(
                        icon: Icon(Icons.clear, color: Colors.red),
                        tooltip: 'Limpar filtro',
                        onPressed: () => setState(() => _dateTimeSelected = false),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Card(
                  color: Colors.orange[50],
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.list_alt, color: Colors.orange[800]),
                            SizedBox(width: 8),
                            Text('Pedidos: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                            Text(filteredOrders.length.toString(), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                        Row(
                          children: [
                            Icon(Icons.euro, color: Colors.orange[800]),
                            SizedBox(width: 8),
                            Text('Total: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800])),
                            Text(formatCurrency(totalFaturado) + '€', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: filteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 80, color: Colors.orange[300]),
                            SizedBox(height: 24),
                            Text(
                              'Nenhum pedido encontrado para o filtro selecionado!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[800],
                              ),
                            ),
                            SizedBox(height: 12),
                            Text(
                              'Altere a data ou hora para ver outros pedidos.',
                              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: EdgeInsets.all(8.0),
                        itemCount: filteredOrders.length,
                        itemBuilder: (context, index) {
                          final order = filteredOrders[index];
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                            child: Card(
                              elevation: 5,
                              margin: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.receipt_long, color: Colors.orange[800]),
                                            SizedBox(width: 8),
                                            Text(
                                              'Pedido #${order.number}',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                                color: Colors.orange[800],
                                              ),
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _getStatusColor(order.status).withOpacity(0.12),
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
                                    Divider(height: 18, thickness: 1),
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
                                    SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        'Total: ' + formatCurrency(double.tryParse(order.total.toString()) ?? 0) + '€',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.green[800],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
