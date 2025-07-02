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
  List<PurchaseOrder> deliveryOrders = []; // Lista para pedidos em entrega
  Map<int, PurchaseOrder> allLocalOrders = {}; // Guardar todos os pedidos localmente
  Timer? statusTimer;
  Timer? deliveryTimer; // Timer para remover pedidos em entrega
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrders();
    _startRefreshTimer();
    _startDeliveryTimer();
  }

  @override
  void dispose() {
    statusTimer?.cancel();
    deliveryTimer?.cancel();
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
          
          // Verificar se a resposta indica "no records found"
          if (decoded is Map && decoded.containsKey('message') && 
              decoded['message'].toString().contains('No records found')) {
            print('[DEBUG] API retornou "No records found" - usando lista vazia');
            data = [];
          } else if (decoded is List) {
            data = decoded;
          } else if (decoded is Map && decoded.isEmpty) {
            data = [];
          } else {
            throw Exception('Resposta inesperada da API: $decoded');
          }
          
          print('Parsed ${data.length} orders from API');
          print('[DEBUG] Pedidos guardados localmente: ${allLocalOrders.keys}');
          
          // Processar pedidos da API
          Set<int> currentApiOrderIds = {};
          List<PurchaseOrder> newOrders = [];
          
          for (var json in data) {
            try {
              PurchaseOrder order = PurchaseOrder.fromJson(json);
              currentApiOrderIds.add(order.id);
              
              // Guardar/atualizar no mapa local
              allLocalOrders[order.id] = order;
              
              // Se está em preparação (estado 0, 1), adicionar à lista de preparação
              if (order.status == '0' || order.status == '1') {
                newOrders.add(order);
              }
              
              print('[DEBUG] Pedido da API: ID ${order.id}, Estado ${order.status}');
            } catch (e) {
              print('Error parsing order: $e');
              print('Order data: $json');
            }
          }
          
          print('[DEBUG] IDs da API atual: $currentApiOrderIds');
          
          // Verificar quais pedidos locais não estão na API (mudaram de estado)
          List<PurchaseOrder> ordersToMoveToDelivery = [];
          List<int> ordersToRemove = [];
          
          for (var entry in allLocalOrders.entries) {
            int orderId = entry.key;
            PurchaseOrder localOrder = entry.value;
            
            // Se o pedido não está na API atual, pode ter mudado de estado
            if (!currentApiOrderIds.contains(orderId)) {
              print('[DEBUG] Pedido $orderId não encontrado na API - movendo para entrega');
              
              // Criar cópia com estado 2 (pronto)
              PurchaseOrder deliveryOrder = localOrder.copyWith(status: '2');
              ordersToMoveToDelivery.add(deliveryOrder);
              
              // Marcar para remover do mapa local após mover para entrega
              ordersToRemove.add(orderId);
            }
          }
          
          // Remover pedidos do mapa local (fora da iteração)
          for (int orderId in ordersToRemove) {
            allLocalOrders.remove(orderId);
          }
          
          // Adicionar pedidos à lista de entrega
          for (var deliveryOrder in ordersToMoveToDelivery) {
            if (!deliveryOrders.any((o) => o.id == deliveryOrder.id)) {
              deliveryOrders.add(deliveryOrder);
              print('[DEBUG] Pedido ${deliveryOrder.id} adicionado à entrega. Total em entrega: ${deliveryOrders.length}');
            }
          }
          
          // Limpar pedidos antigos da lista de preparação que não estão mais na API
          orders = newOrders;
          
          setState(() {
            isLoading = false;
          });
          
          print('[DEBUG] Estado final - Preparação: ${orders.length}, Entrega: ${deliveryOrders.length}, Local: ${allLocalOrders.length}');
          
        } catch (e) {
          print('Error parsing JSON: $e');
          setState(() {
            errorMessage = null;
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

  void _startDeliveryTimer() {
    // Timer para remover pedidos em entrega após 15 segundos
    deliveryTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      setState(() {
        deliveryOrders.clear(); // Remove todos os pedidos em entrega
        print('[DEBUG] Pedidos em entrega removidos após 15s');
      });
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
          title: const Text('Gestão de Pedidos'),
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
                : Row(
                    children: [
                      // Lado esquerdo - Em Preparação
                      Expanded(
                        child: _buildPreparationSection(),
                      ),
                      // Divisor vertical mais espesso para Windows
                      Container(
                        width: 4,
                        color: Colors.grey[400],
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      // Lado direito - Em Entrega
                      Expanded(
                        child: _buildDeliverySection(),
                      ),
                    ],
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

  Widget _buildPreparationSection() {
    return Column(
      children: [
        // Header da seção
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border(
              bottom: BorderSide(color: Colors.orange[200]!, width: 2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.restaurant, color: Colors.orange[700], size: 32),
              const SizedBox(width: 12),
              Text(
                'Em Preparação',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${orders.length}',
                  style: TextStyle(
                    color: Colors.orange[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista de pedidos em preparação
        Expanded(
          child: orders.isEmpty
              ? _buildEmptyState('Nenhum pedido em preparação', Icons.restaurant)
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) => _buildOrderCard(orders[index]),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDeliverySection() {
    return Column(
      children: [
        // Header da seção
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.green[50],
            border: Border(
              bottom: BorderSide(color: Colors.green[200]!, width: 2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.green[700], size: 32),
              const SizedBox(width: 12),
              Text(
                'Em Entrega',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${deliveryOrders.length}',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Lista de pedidos em entrega
        Expanded(
          child: deliveryOrders.isEmpty
              ? _buildEmptyState('Nenhum pedido em entrega', Icons.delivery_dining)
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: deliveryOrders.length,
                    itemBuilder: (context, index) => _buildOrderCard(deliveryOrders[index], isDelivery: true),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(48),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              message,
              style: TextStyle(
                fontSize: 20,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(PurchaseOrder order, {bool isDelivery = false}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDelivery ? Colors.green[200]! : Colors.orange[200]!,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            // Imagem do produto
            CachedBase64Image(
              base64Image: order.products.isNotEmpty && order.products.first.imageUrl != null 
                  ? order.products.first.imageUrl! 
                  : '',
              width: 80,
              height: 80,
              borderRadius: BorderRadius.circular(12),
            ),
            const SizedBox(width: 20),
            // Informações do pedido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.customerName,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    order.description,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${order.total}€',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDelivery ? Colors.green[700] : Colors.orange[700],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatDateTime(order.time),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _getStatusColor(order.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _getStatusColor(order.status),
                  width: 1,
                ),
              ),
              child: Text(
                _getStatusText(order.status),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getStatusColor(order.status),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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