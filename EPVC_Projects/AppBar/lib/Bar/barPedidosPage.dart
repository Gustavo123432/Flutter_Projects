import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:appbar_epvc/Bar/drawerBar.dart';

class BarRequests extends StatefulWidget {
  const BarRequests({Key? key}) : super(key: key);

  @override
  _BarRequestsState createState() => _BarRequestsState();
}

class _BarRequestsState extends State<BarRequests> {
  List<PurchaseOrder> orders = [];
  Timer? statusTimer;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startRefreshTimer();
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    try {
      print('Loading orders...');
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '14',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final decoded = json.decode(response.body);
          List<dynamic> data;
          if (decoded is List) {
            data = decoded;
          } else if (decoded is Map && decoded.isEmpty) {
            data = [];
          } else {
            throw Exception('Resposta inesperada da API: $decoded');
          }
          print('Parsed ${data.length} orders');
          setState(() {
            orders = data.map((json) {
              try {
                return PurchaseOrder.fromJson(json);
              } catch (e) {
                print('Error parsing order: $e');
                print('Order data: $json');
                return null;
              }
            }).where((order) => order != null).cast<PurchaseOrder>().toList();
            isLoading = false;
          });
        } catch (e) {
          print('Error parsing JSON: $e');
          setState(() {
            errorMessage = null;
            orders = [];
            isLoading = false;
          });
        }
      } else {
        print('HTTP error: ${response.statusCode}');
        setState(() {
          errorMessage = 'Erro ao carregar pedidos: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      print('Exception in _loadOrders: $e');
      setState(() {
        errorMessage = 'Erro de conexão: $e';
        isLoading = false;
      });
    }
  }

  void _startRefreshTimer() {
    statusTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _loadOrders();
    });
  }

  Widget _buildImageWidget(String base64Image) {
    try {
      if (base64Image.isEmpty) {
        print('Empty base64 image string');
        return _buildPlaceholderImage();
      }
      
      final bytes = base64Decode(base64Image);
      return Image.memory(
        bytes,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error building image: $error');
          return _buildPlaceholderImage();
        },
      );
    } catch (e) {
      print('Exception in _buildImageWidget: $e');
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.fastfood, size: 30),
    );
  }

  String _formatDateTime(String dateTime) {
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case '0':
        return Colors.orange;
      case '1':
        return Colors.blue;
      case '2':
        return Colors.green;
      case '3':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case '0':
        return 'Pendente';
      case '1':
        return 'Em Prep.';
      case '2':
        return 'Pronto';
      case '3':
        return 'Entregue';
      default:
        return 'Desconhecido';
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pedidos Pendentes'),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          actions: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.refresh, size: 16, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Auto 3s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        drawer: const DrawerBar(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadOrders,
                          child: const Text('Tentar Novamente'),
                        ),
                      ],
                    ),
                  )
                : orders.isEmpty
                    ? Center(
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          margin: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.receipt_long,
                                  size: 60,
                                  color: Colors.orange[700],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Nenhum Pedido Ativo',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[800],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Não existem pedidos pendentes\nno momento.',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                  height: 1.4,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange[50],
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.orange[200]!,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.refresh,
                                      size: 16,
                                      color: Colors.orange[700],
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Auto-refresh a cada 3s',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadOrders,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: orders.length,
                          itemBuilder: (context, index) {
                            try {
                              final order = orders[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 20),
                                elevation: 6,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      // Imagem grande
                                      CachedBase64Image(
                                        base64Image: order.products.isNotEmpty && order.products.first.imageUrl != null ? order.products.first.imageUrl! : '',
                                        width: 80,
                                        height: 80,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      const SizedBox(width: 28),
                                      // Info principal
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pedido #${order.id}',
                                              style: const TextStyle(
                                                fontSize: 32,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.orange,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              order.customerName,
                                              style: const TextStyle(
                                                fontSize: 26,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.black,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                                              decoration: BoxDecoration(
                                                color: _getStatusColor(order.status).withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                _getStatusText(order.status),
                                                style: TextStyle(
                                                  fontSize: 22,
                                                  fontWeight: FontWeight.bold,
                                                  color: _getStatusColor(order.status),
                                                  letterSpacing: 1.1,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } catch (e) {
                              print('Error building order item $index: $e');
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Text('Erro ao carregar pedido: $e'),
                                ),
                              );
                            }
                          },
                        ),
                      ),
      );
    } catch (e) {
      print('Error in build method: $e');
      return Scaffold(
        appBar: AppBar(
          title: const Text('Erro'),
          backgroundColor: Colors.red,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Erro ao carregar a página'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    isLoading = true;
                    errorMessage = null;
                  });
                  _loadOrders();
                },
                child: const Text('Tentar Novamente'),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class PurchaseOrder {
  final int id;
  final String customerName;
  final String className;
  final String total;
  final String time;
  final String status;
  final String description;
  final List<Product> products;

  PurchaseOrder({
    required this.id,
    required this.customerName,
    required this.className,
    required this.total,
    required this.time,
    required this.status,
    required this.description,
    required this.products,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    try {
      return PurchaseOrder(
        id: int.tryParse(json['NPedido']?.toString() ?? '0') ?? 0,
        customerName: json['QPediu']?.toString() ?? 'Cliente',
        className: json['Turma']?.toString() ?? 'Turma',
        total: json['Total']?.toString() ?? '0.00',
        time: json['Data']?.toString() ?? DateTime.now().toString(),
        status: json['Estado']?.toString() ?? '0',
        description: json['Descricao']?.toString() ?? '',
        products: [
          Product(
            name: json['Descricao']?.toString() ?? '',
            quantity: 1,
            price: double.tryParse(json['Total']?.toString() ?? '0.0') ?? 0.0,
            imageUrl: json['Imagem']?.toString(),
          ),
        ],
      );
    } catch (e) {
      print('Error in PurchaseOrder.fromJson: $e');
      print('JSON data: $json');
      // Return a default order to prevent crash
      return PurchaseOrder(
        id: 0,
        customerName: 'Erro',
        className: 'Erro',
        total: '0.00',
        time: DateTime.now().toString(),
        status: '0',
        description: 'Erro ao carregar',
        products: [
          Product(
            name: 'Erro',
            quantity: 1,
            price: 0.0,
            imageUrl: null,
          ),
        ],
      );
    }
  }

  PurchaseOrder copyWith({
    int? id,
    String? customerName,
    String? className,
    String? total,
    String? time,
    String? status,
    String? description,
    List<Product>? products,
  }) {
    return PurchaseOrder(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      className: className ?? this.className,
      total: total ?? this.total,
      time: time ?? this.time,
      status: status ?? this.status,
      description: description ?? this.description,
      products: products ?? this.products,
    );
  }
}

class OrderProduct {
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;

  OrderProduct({
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory OrderProduct.fromJson(Map<String, dynamic> json) {
    return OrderProduct(
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      imageUrl: json['image_url'],
    );
  }
}

class Product {
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl;

  Product({
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });
}

class CachedBase64Image extends StatefulWidget {
  final String base64Image;
  final double width;
  final double height;
  final BorderRadius borderRadius;
  const CachedBase64Image({
    required this.base64Image,
    this.width = 80,
    this.height = 80,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    Key? key,
  }) : super(key: key);

  @override
  State<CachedBase64Image> createState() => _CachedBase64ImageState();
}

class _CachedBase64ImageState extends State<CachedBase64Image> {
  late Image imageWidget;
  String? lastBase64;

  @override
  void didUpdateWidget(covariant CachedBase64Image oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.base64Image != lastBase64) {
      _decodeImage();
    }
  }

  @override
  void initState() {
    super.initState();
    _decodeImage();
  }

  void _decodeImage() {
    try {
      if (widget.base64Image.isEmpty) {
        imageWidget = _placeholder();
      } else {
        final bytes = base64Decode(widget.base64Image);
        imageWidget = Image.memory(
          bytes,
          width: widget.width,
          height: widget.height,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _placeholder(),
        );
      }
    } catch (e) {
      imageWidget = _placeholder();
    }
    lastBase64 = widget.base64Image;
  }

  Image _placeholder() {
    return Image.asset(
      'lib/assets/barapp.png',
      width: widget.width,
      height: widget.height,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: imageWidget,
    );
  }
} 