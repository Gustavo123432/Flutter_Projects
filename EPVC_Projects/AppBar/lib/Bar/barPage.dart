import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appbar_epvc/Bar/drawerBar.dart';
import 'package:appbar_epvc/login.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:diacritic/diacritic.dart';
import '../services/base_product_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:appbar_epvc/config/app_config.dart';

class PurchaseOrder {
  final String number;
  final String requester;
  final String group;
  final String description;
  final String total;
  final String troco;
  final String status;
  final String userPermission;
  final String imagem;
  final String paymentMethod;

  PurchaseOrder({
    required this.number,
    required this.requester,
    required this.group,
    required this.description,
    required this.total,
    required this.troco,
    required this.status,
    required this.userPermission,
    required this.imagem,
    required this.paymentMethod,
  });

  factory PurchaseOrder.fromJson(Map<String, dynamic> json) {
    return PurchaseOrder(
      number: json['NPedido']?.toString() ?? 'N/A',
      requester: json['QPediu'] ?? 'Desconhecido',
      group: json['Turma'] ?? 'Sem turma',
      description: (json['Descricao'] is List)
          ? (json['Descricao'] as List).join(', ')
          : json['Descricao']?.toString() ?? 'Sem descrição',
      total: json['Total']?.toString() ?? '0.00',
      troco: json['Troco']?.toString() ?? '0.00',
      status: json['Estado']?.toString() ?? '0',
      imagem: json['Imagem'] ?? '',
      userPermission: json['Permissao'] ?? 'Sem permissão',
      paymentMethod:
          json['payment_method'] ?? json['MetodoDePagamento'] ?? 'dinheiro',
    );
  }
}

class BarPagePedidos extends StatefulWidget {
  @override
  _BarPagePedidosState createState() => _BarPagePedidosState();
}

class _BarPagePedidosState extends State<BarPagePedidos> {
  late Stream<List<PurchaseOrder>> purchaseOrderStream;
  final StreamController<List<PurchaseOrder>> purchaseOrderController =
      StreamController.broadcast();
  List<PurchaseOrder> currentOrders = [];
  WebSocketChannel? _channel;
  Timer? _pingTimer; // Timer para keep-alive
  Timer? _inactivityTimer;
  final Duration inactivityDuration = Duration(minutes:2); // ajuste o tempo aqui
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Map para guardar os dados originais dos pedidos (incluindo dados de faturação)
  Map<String, Map<String, dynamic>> rawOrdersData = {};

  bool? isDayOpen; // null = loading, false = closed, true = open
  bool _showCalculator = false;
  Offset _calculatorOffset = Offset(100, 200);

  // 1. No início do widget/página pai (exemplo: BarPage):
  List<Map<String, dynamic>> _cart = [];

  DateTime? _lastOrderReceived;
  bool _shouldPlayNotification = false;

  @override
  void initState() {
    super.initState();
    _checkDayStatus();
  }

  Future<void> _checkDayStatus() async {
    setState(() {
      isDayOpen = null;
    });
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=37'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int open = 0;
        if (data is List &&
            data.isNotEmpty &&
            (data[0]['open'] != null || data[0]['Open'] != null)) {
          open =
              int.tryParse((data[0]['open'] ?? data[0]['Open']).toString()) ??
                  0;
        } else if (data is Map &&
            (data['open'] != null || data['Open'] != null)) {
          open = int.tryParse((data['open'] ?? data['Open']).toString()) ?? 0;
        }
        setState(() {
          isDayOpen = open == 1;
        });
        if (open == 1) {
          purchaseOrderStream = getPurchaseOrdersStream();
          _fetchInitialPurchaseOrders();
          _connectToWebSocket();
        }
      } else {
        setState(() {
          isDayOpen = false;
        });
      }
    } catch (e) {
      setState(() {
        isDayOpen = false;
      });
    }
  }

  Future<void> _openDay() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=37.2'),
      );
      if (response.statusCode == 200 && response.body.contains('Dia Aberto')) {
        setState(() {
          isDayOpen = true;
        });
        // Now load orders
        purchaseOrderStream = getPurchaseOrdersStream();
        _fetchInitialPurchaseOrders();
        _connectToWebSocket();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao abrir o dia.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao abrir o dia.')),
      );
    }
  }

  Future<void> _fetchInitialPurchaseOrders() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=10'),
      );
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        List<PurchaseOrder> orders =
            data.map((json) => PurchaseOrder.fromJson(json)).toList();

        setState(() {
          currentOrders = orders.where((order) => order.status != '2').toList();
          purchaseOrderController.add(currentOrders);
          _resetInactivityTimer();
        });
      } else {
        throw Exception('Erro ao carregar pedidos. Verifique a Internet.');
      }
    } catch (e) {
      print('Erro ao buscar pedidos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pedidos: ${e.toString()}')),
      );
    }
  }

  void _connectToWebSocket() {
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('ws://192.168.25.94:2536'),
      );

      // Iniciar o timer de keep-alive (ping)
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(Duration(minutes: 4), (_) {
        try {
          _channel?.sink.add('ping');
        } catch (e) {
          print('Erro ao enviar ping: $e');
        }
      });

      _channel!.stream.listen(
        (message) async {
          if (message != null && message.isNotEmpty) {
            final now = DateTime.now();
            if (_shouldPlayNotification) {
              print('[NOTIFICAÇÃO] Tocando som de notificação após inatividade de 2 minutos');
              await _audioPlayer.play(   AssetSource('sound/appBarNotification.mp3'));
              _shouldPlayNotification = false;
            }
            _lastOrderReceived = now;
            try {
              Map<String, dynamic> data = jsonDecode(message);
              print('[DEBUG] Mensagem recebida do WebSocket: ' + message);
              print('[DEBUG] Chaves recebidas do WebSocket: ' +
                  data.keys.join(', '));

              // Guardar os dados originais do pedido
              String orderNumber = data['NPedido']?.toString() ?? '';
              if (orderNumber.isNotEmpty) {
                rawOrdersData[orderNumber] = data;
              }

              PurchaseOrder order = PurchaseOrder.fromJson(data);

              setState(() {
                // Remove completed orders (status 2)
                if (order.status == '2') {
                  currentOrders.removeWhere((o) => o.number == order.number);
                  // Remover também os dados originais
                  rawOrdersData.remove(order.number);
                }
                // Update existing orders
                else {
                  int index =
                      currentOrders.indexWhere((o) => o.number == order.number);
                  if (index >= 0) {
                    currentOrders[index] = order;
                  } else if (order.status == '0') {
                    currentOrders.add(order);
                  }
                }
                purchaseOrderController.add(currentOrders);
                _resetInactivityTimer();
              });
            } catch (e) {
              print('Erro ao processar a mensagem: $e');
            }
          }
        },
        onError: (error) {
          print('Erro WebSocket: $error');
          // Tentar reconectar após um erro
          Future.delayed(Duration(seconds: 5), () {
            if (mounted) {
              _connectToWebSocket();
            }
          });
        },
        onDone: () {
          print('Conexão WebSocket fechada');
          // Cancelar o timer de ping
          _pingTimer?.cancel();
          // Tentar reconectar quando a conexão for fechada
          Future.delayed(Duration(seconds: 5), () {
            if (mounted) {
              _connectToWebSocket();
            }
          });
        },
        cancelOnError: false, // Não cancelar a inscrição em caso de erro
      );
    } catch (e) {
      print('Erro ao estabelecer conexão WebSocket: $e');
      // Cancelar o timer de ping
      _pingTimer?.cancel();
      // Tentar reconectar em caso de erro na conexão inicial
      Future.delayed(Duration(seconds: 5), () {
        if (mounted) {
          _connectToWebSocket();
        }
      });
    }
  }

  Stream<List<PurchaseOrder>> getPurchaseOrdersStream() {
    return purchaseOrderController.stream.distinct();
  }

  Uint8List safeBase64Decode(String base64String) {
    try {
      String cleaned = base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
      while (cleaned.length % 4 != 0) {
        cleaned += '=';
      }
      return base64Decode(cleaned);
    } catch (e) {
      return Uint8List(0);
    }
  }

  String cleanBase64(String input) {
    return input.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
  }

  // Função auxiliar para processar a descrição e agrupar itens iguais
  Map<String, int> processDescription(String description) {
    Map<String, int> items = {};

    // Primeiro, substituir vírgulas em números decimais por ponto
    String processedDesc = description.replaceAllMapped(RegExp(r'(\d+),(\d+)'),
        (match) => '${match.group(1)}.${match.group(2)}');

    // Agora dividir por vírgulas, mas apenas as que não estão dentro de números
    List<String> products = processedDesc
        .replaceAll('[', '')
        .replaceAll(']', '')
        .split(',')
        .map((product) => product.trim())
        .where((product) => product.isNotEmpty)
        .toList();

    for (String product in products) {
      // Extrair quantidade e nome do produto
      RegExp regex = RegExp(r'(\d+)\s*x\s*(.*)');
      Match? match = regex.firstMatch(product);

      if (match != null) {
        int quantity = int.parse(match.group(1)!);
        String itemName = match.group(2)!.trim();
        // Substituir ponto de volta por vírgula para exibição
        itemName = itemName.replaceAll('.', ',');
        items[itemName] = (items[itemName] ?? 0) + quantity;
      } else {
        // Se não encontrar o padrão de quantidade, assume 1
        // Substituir ponto de volta por vírgula para exibição
        String itemName = product.replaceAll('.', ',');
        items[itemName] = (items[itemName] ?? 0) + 1;
      }
    }
    return items;
  }

  void _prepareOrder(
      PurchaseOrder currentOrder, List<PurchaseOrder> allOrders) {
    // Processar produtos do pedido atual
    Map<String, int> currentProducts =
        processDescription(currentOrder.description);

    // Encontrar pedidos com produtos semelhantes
    List<PurchaseOrder> matchingOrders = allOrders.where((order) {
      Map<String, int> orderProducts = processDescription(order.description);
      return orderProducts.keys
          .any((product) => currentProducts.containsKey(product));
    }).toList();

    matchingOrders.removeWhere((order) => order.number == currentOrder.number);
    matchingOrders.removeWhere((order) => int.parse(order.status) != 0);

    // Agregar produtos de todos os pedidos relevantes
    Map<String, int> productCounts = Map.from(currentProducts);

    // Adicionar produtos dos pedidos correspondentes
    for (PurchaseOrder order in matchingOrders) {
      Map<String, int> orderProducts = processDescription(order.description);
      orderProducts.forEach((product, quantity) {
        productCounts[product] = (productCounts[product] ?? 0) + quantity;
      });
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: AlertDialog(
            title: Text('Pedidos com Produtos Semelhantes'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Está a preparar o pedido ${currentOrder.number}.'),
                SizedBox(height: 10),

                // Display aggregated product counts
                Text('Total de produtos a preparar:'),
                SizedBox(height: 5),
                ...productCounts.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                    child: Text(
                      '• ${entry.value}x ${entry.key}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  );
                }).toList(),

                SizedBox(height: 15),
                Text('Produtos no pedido atual:'),
                Text.rich(
                  TextSpan(
                    children: currentProducts.entries.map((entry) {
                      return TextSpan(
                        text: '\t\t\t• ${entry.value}x ${entry.key}\n',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      );
                    }).toList(),
                  ),
                ),

                if (matchingOrders.isNotEmpty) ...[
                  SizedBox(height: 10),
                  Text('Os seguintes pedidos contêm produtos semelhantes:'),
                  ...matchingOrders.map((order) {
                    Map<String, int> orderProducts =
                        processDescription(order.description);
                    return ListTile(
                      title:
                          Text('Pedido ${order.number} - ${order.requester}'),
                      subtitle: Text(
                          'Produtos: ${orderProducts.entries.map((e) => '${e.value}x ${e.key}').join(', ')}'),
                    );
                  }).toList(),
                ],
              ],
            ),
            actions: [
              TextButton(
                child: Text('Preparar Apenas Este'),
                onPressed: () {
                  _markOrderAsPrepared(currentOrder);
                  Navigator.of(context).pop();
                },
              ),
              if (matchingOrders.isNotEmpty)
                TextButton(
                  child: Text('Preparar Todos'),
                  onPressed: () {
                    _markOrderAsPrepared(currentOrder);
                    matchingOrders.forEach((order) {
                      _markOrderAsPrepared(order);
                    });
                    Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markOrderAsPrepared(PurchaseOrder order) async {
    try {
      final response = await http.get(Uri.parse(
          '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=17&nome=${order.requester}&npedido=${order.number}&op=1'));

      if (response.statusCode == 200) {
        setState(() {
          int index = currentOrders.indexWhere((o) => o.number == order.number);
          if (index >= 0) {
            currentOrders[index] = PurchaseOrder(
              number: order.number,
              requester: order.requester,
              group: order.group,
              description: order.description,
              total: order.total,
              troco: order.troco,
              status: '1', // Set status to 1 (Preparar)
              userPermission: order.userPermission,
              imagem: order.imagem,
              paymentMethod: order.paymentMethod,
            );
            purchaseOrderController.add(currentOrders);
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro ao preparar pedido. Código: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao preparar pedido: ${e.toString()}')),
      );
    }
  }

  Future<bool?> _showPaymentConfirmationDialog(PurchaseOrder order) async {
    String formattedTotal =
        double.parse(order.total).toStringAsFixed(2).replaceAll('.', ',');
    String paymentMethodDisplay =
        order.paymentMethod.toLowerCase() == 'saldo' ? 'Saldo' : 'Dinheiro';

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmar Pagamento'),
        content: Text(
            'Deseja confirmar o pagamento de ${formattedTotal}€ em $paymentMethodDisplay?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  Future<void> _markOrderAsCompleted(PurchaseOrder order) async {
    bool? confirmed = true;

    if (order.paymentMethod.toLowerCase() == 'dinheiro' ||
        order.paymentMethod.toLowerCase() == 'saldo') {
      confirmed = await _showPaymentConfirmationDialog(order);
    }

    if (confirmed != true) {
      return; // User cancelled
    }

    try {
      // Primeiro, marcar como concluído
      final response = await http.get(Uri.parse(
          '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=17&nome=${order.requester}&npedido=${order.number}&op=2'));

      if (response.statusCode == 200) {
        // Só depois faturar
        await _faturarPedidoSeNecessario(order);
        setState(() {
          currentOrders.removeWhere((o) => o.number == order.number);
          // Remover também os dados originais
          rawOrdersData.remove(order.number);
          purchaseOrderController.add(currentOrders);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Pedido ${order.number} concluído com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao concluir pedido ${order.number}')),
        );
      }
    } catch (e) {
      print('Erro ao concluir pedido: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao concluir pedido: \\${e.toString()}')),
      );
    }
  }

  // Função auxiliar para obter o XDReference pelo nome do produto
  Future<String?> _getXDReferenceByName(String productName) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=5.1&nome=${Uri.encodeComponent(productName)}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0]['XDReference'] != null) {
          return data[0]['XDReference'].toString();
        }
      }
    } catch (e) {
      print('Erro ao obter XDReference para $productName: $e');
    }
    return null;
  }

  // Função para construir order_lines a partir da descrição
  Future<List<Map<String, dynamic>>> _buildOrderLinesFromDescricao(
      String descricao) async {
    List<Map<String, dynamic>> orderLines = [];
    print('[DEBUG] Descricao recebida para order_lines: $descricao');

    // Dividir por vírgulas E hífens, depois limpar cada item
    List<String> items = [];
    // Primeiro dividir por vírgulas
    List<String> commaSplit = descricao.split(',');
    for (String commaItem in commaSplit) {
      // Depois dividir cada item por hífens
      List<String> hyphenSplit = commaItem.split('-');
      for (String hyphenItem in hyphenSplit) {
        String trimmedItem = hyphenItem.trim();
        if (trimmedItem.isNotEmpty) {
          items.add(trimmedItem);
        }
      }
    }

    print('[DEBUG] Items extraídos: $items');

    for (var item in items) {
      item = item.trim();
      RegExp reg = RegExp(r'^(\d+)x\s*(.+)$');
      Match? match = reg.firstMatch(item);
      int quantity = 1;
      String productName = item;
      if (match != null) {
        quantity = int.tryParse(match.group(1) ?? '1') ?? 1;
        productName = match.group(2)?.trim() ?? '';
      }
      String? xdReference = await _getXDReferenceByName(productName);
      if (xdReference != null) {
        orderLines.add({
          'reference': xdReference,
          'quantity': quantity,
        });
        print(
            '[DEBUG] Produto adicionado: $productName (qty: $quantity, ref: $xdReference)');
      } else {
        print('XDReference não encontrado para "$productName".');
      }
    }
    return orderLines;
  }

  // Adicione uma função para salvar pedidos não faturados
  Future<void> _saveUnbilledOrder(PurchaseOrder order) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> failedOrders = prefs.getStringList('unbilled_orders') ?? [];
    failedOrders.add(order.number);
    await prefs.setStringList('unbilled_orders', failedOrders);
  }

  // Adicione uma função para buscar pedidos não faturados
  Future<List<String>> _getUnbilledOrders() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList('unbilled_orders') ?? [];
  }

  // Adicione uma função para remover pedido não faturado após sucesso
  Future<void> _removeUnbilledOrder(String orderNumber) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> failedOrders = prefs.getStringList('unbilled_orders') ?? [];
    failedOrders.remove(orderNumber);
    await prefs.setStringList('unbilled_orders', failedOrders);
  }

  // Modifique a função de faturação para tentar 5 vezes e salvar se falhar
  Future<bool> _faturarPedidoSeNecessario(PurchaseOrder order) async {
    try {
      Map<String, dynamic> rawData = rawOrdersData[order.number] ?? {};
      final invoiceFlag =
          (rawData['RequestInvoice'] ?? rawData['requestInvoice'] ?? '0')
              .toString();
      print(
          'RequestInvoice recebido: ${rawData['RequestInvoice']} / ${rawData['requestInvoice']}');
      if (invoiceFlag != '1') {
        print(
            'Faturação não solicitada para o pedido ${order.number} (valor recebido: $invoiceFlag)');
        return true;
      }
      print('Chamando API de faturação para o pedido ${order.number}');
      String customerName = rawData['CustomerName'] ?? order.requester;
      String customerAddress = rawData['CustomerAddress'] ?? 'Rua Exemplo';
      String customerPostalCode = rawData['CustomerPostalCode'] ?? '1000-001';
      String customerCity = rawData['CustomerCity'] ?? 'Lisboa';
      String customerCountry = 'PT';

      // Lógica para determinar o NIF a usar
      String customerVAT;
      String nifRecebido = rawData['NIF'] ?? '';

      if (nifRecebido.isNotEmpty && nifRecebido != '999999990') {
        customerVAT = nifRecebido;
      } else {
        customerVAT = '999999990';
      }

      String documentType = rawData['documentType'] ?? 'FS';
      String idUser = rawData['idUser']?.toString() ?? '0';

      print('[DEBUG] NIF recebido do WebSocket: $nifRecebido');
      print('[DEBUG] NIF que será usado na faturação: $customerVAT');
      print('[DEBUG] idUser: $idUser');
      print('[DEBUG] documentType: $documentType');
      List<Map<String, dynamic>> orderLines = [];
      int retryCount = 0;
      while (orderLines.isEmpty && retryCount < 5) {
        print('[DEBUG] order_lines vazio, a tentar novamente (${retryCount + 1}/5)...');
        await Future.delayed(Duration(milliseconds: 600));
        if (rawData['CartItems'] != null && rawData['CartItems'] is List) {
          orderLines.clear();
          for (var item in rawData['CartItems']) {
            if (item is Map && item.containsKey('XDReference')) {
              orderLines.add({
                'reference': item['XDReference'] ?? item['Id'] ?? '123',
                'quantity': 1
              });
            }
          }
        } else if (rawData['Descricao'] != null) {
          orderLines =
              await _buildOrderLinesFromDescricao(rawData['Descricao']);
        }
        retryCount++;
      }
      if (orderLines.isEmpty) {
        print('[ERRO] Não foi possível obter produtos para faturação após várias tentativas. Faturação não enviada.');
        await _saveUnbilledOrder(order);
        return false;
      }
      Map<String, dynamic> billingPayload = {
        'query_param': 1,
        'user_id': idUser,
        'vat': customerVAT,
        'name': customerName,
        'address': customerAddress,
        'postalCode': customerPostalCode,
        'city': customerCity,
        'country': customerCountry,
        'documentType': documentType,
        'customer_id': '0',
        'order_lines': orderLines
      };
      print('Payload da API de faturação: ${json.encode(billingPayload)}');
      bool faturado = false;
      for (int i = 0; i < 5; i++) {
        final response = await http.post(
          Uri.parse('http://192.168.22.88/api/api.php'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(billingPayload),
        );
        print('Tentativa de faturação ${i + 1}/5 - Status: ${response.statusCode}');
        print('Tentativa de faturação ${i + 1}/5 - Body: ${response.body}');
        if (response.statusCode == 200) {
          faturado = true;
          break;
        } else {
          await Future.delayed(Duration(seconds: 2));
        }
      }
      if (!faturado) {
        print('[ERRO] Não foi possível faturar após 5 tentativas. Salvando localmente.');
        await _saveUnbilledOrder(order);
        return false;
      } else {
        await _removeUnbilledOrder(order.number);
        return true;
      }
    } catch (e) {
      print('Erro ao chamar API de faturação: $e');
      await _saveUnbilledOrder(order);
      return false;
    }
  }

  // Adicione um método para exibir os pedidos não faturados (exemplo: dialog)
  Future<void> showUnbilledOrdersDialog(BuildContext context) async {
    List<String> unbilled = await _getUnbilledOrders();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pedidos Não Faturados'),
        content: unbilled.isEmpty
            ? Text('Todos os pedidos foram faturados.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: unbilled.map((orderNum) => Text('Pedido Nº $orderNum')).toList(),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Fechar'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Eliminar Pedido"),
        content: Text("Deseja eliminar este pedido?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteOrder(order);
            },
            child: Text("Eliminar", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteOrder(PurchaseOrder order) async {
    try {
      final response = await http.get(Uri.parse(
          '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=24&nome=${order.requester}&ids=${order.number}'));

      if (response.statusCode == 200) {
        setState(() {
          currentOrders.removeWhere((o) => o.number == order.number);
          purchaseOrderController.add(currentOrders);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pedido eliminado com sucesso.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Erro ao eliminar pedido. Código: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao eliminar pedido: ${e.toString()}')),
      );
    }
  }

  Future<void> _closeDay() async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=37.1'),
      );
      if (response.statusCode == 200 && response.body.contains('Dia Fechado')) {
        setState(() {
          isDayOpen = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dia fechado com sucesso.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao fechar o dia.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao fechar o dia.')),
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (ctx) => LoginForm()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _toggleCalculator() {
    setState(() {
      _showCalculator = !_showCalculator;
    });
  }

  void _resetInactivityTimer() {
    _inactivityTimer?.cancel();
    _inactivityTimer = Timer(inactivityDuration, () {
      _shouldPlayNotification = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            backgroundColor: Color.fromARGB(255, 246, 141, 45),
            title: Text('Pedidos'),
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
          body: isDayOpen == null
              ? Center(child: CircularProgressIndicator())
              : isDayOpen == false
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock, size: 60, color: Colors.orange),
                          SizedBox(height: 24),
                          Text(
                            'Precisa de abrir o dia para começar a entrar pedidos',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: Icon(Icons.lock_open),
                            label: Text('Abrir Dia'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                            ),
                            onPressed: _openDay,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: Center(
                        child: StreamBuilder<List<PurchaseOrder>>(
                          stream: purchaseOrderStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return FutureBuilder(
                                future: Future.delayed(Duration(seconds: 5)),
                                builder: (context, futureSnapshot) {
                                  if (futureSnapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return Center(
                                        child: CircularProgressIndicator());
                                  } else {
                                    return Center(
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.inbox, size: 80, color: Colors.orange[300]),
                                          SizedBox(height: 24),
                                          Text(
                                            'Ainda não há pedidos!',
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.orange[800],
                                            ),
                                          ),
                                          SizedBox(height: 12),
                                          Text(
                                            'Quando um pedido for registado, ele aparecerá aqui.',
                                            style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              );
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Erro ao carregar pedidos'));
                            } else if (!snapshot.hasData ||
                                snapshot.data!.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.inbox, size: 80, color: Colors.orange[300]),
                                    SizedBox(height: 24),
                                    Text(
                                      'Ainda não há pedidos!',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange[800],
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    Text(
                                      'Quando um pedido for registado, ele aparecerá aqui.',
                                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              );
                            }

                            List<PurchaseOrder> data = snapshot.data!;

                            return GridView.builder(
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.all(8.0),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                                childAspectRatio: 1.0,
                              ),
                              itemCount: data.length,
                              itemBuilder: (context, index) {
                                PurchaseOrder order = data[index];
                                String formattedTotal =
                                    double.parse(order.total)
                                        .toStringAsFixed(2)
                                        .replaceAll('.', ',');
                                String base64String = order.imagem.toString();
                                String cleanedBase64 =
                                    cleanBase64(base64String);
                                Uint8List decodedBytes =
                                    safeBase64Decode(cleanedBase64);

                                // Processar a descrição para agrupar itens
                                Map<String, int> groupedItems =
                                    processDescription(order.description);
                                String groupedDescription = groupedItems.entries
                                    .map((e) => '${e.value}x ${e.key}')
                                    .join(', ');

                                Color buttonColor;
                                String? buttonText;
                                switch (int.parse(order.status)) {
                                  case 1:
                                    buttonColor =
                                        const Color.fromARGB(255, 221, 163, 2);
                                    buttonText = "Concluir";
                                    break;
                                  default:
                                    buttonColor =
                                        Color.fromARGB(255, 175, 175, 175);
                                    buttonText = "Preparar";
                                }

                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (BuildContext context) {
                                        return AlertDialog(
                                          title: Text(
                                            'Detalhes do Pedido ${order.number}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Requisitante: ${order.requester}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Turma: ${order.group}',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Descrição:',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text.rich(
                                                  TextSpan(
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                    children: groupedItems
                                                        .entries
                                                        .map((entry) {
                                                      return TextSpan(
                                                        text:
                                                            '• ${entry.value}x ${entry.key}\n',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight
                                                                    .bold),
                                                      );
                                                    }).toList(),
                                                  ),
                                                ),
                                                SizedBox(height: 8),
                                                Text(
                                                  'Total: $formattedTotal€',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  'Troco: ${double.parse(order.troco).toStringAsFixed(2).replaceAll('.', ',')}€',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[800],
                                                  ),
                                                ),
                                                SizedBox(height: 6),
                                                Row(
                                                  children: [
                                                    Text(
                                                      'Método de Pagamento: ',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors.grey[800],
                                                      ),
                                                    ),
                                                    Container(
                                                      padding:
                                                          EdgeInsets.symmetric(
                                                              horizontal: 8,
                                                              vertical: 2),
                                                      decoration: BoxDecoration(
                                                        color: order.paymentMethod
                                                                    .toLowerCase() ==
                                                                'mbway'
                                                            ? Color.fromARGB(
                                                                255,
                                                                232,
                                                                240,
                                                                254)
                                                            : order.paymentMethod
                                                                        .toLowerCase() ==
                                                                    'saldo'
                                                                ? Colors
                                                                    .orange[50]
                                                                : Color
                                                                    .fromARGB(
                                                                        255,
                                                                        239,
                                                                        249,
                                                                        239),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(12),
                                                        border: Border.all(
                                                          color: order.paymentMethod
                                                                      .toLowerCase() ==
                                                                  'mbway'
                                                              ? Colors.red
                                                              : order.paymentMethod
                                                                          .toLowerCase() ==
                                                                      'saldo'
                                                                  ? Colors.orange[
                                                                      700]!
                                                                  : Color
                                                                      .fromARGB(
                                                                          255,
                                                                          76,
                                                                          175,
                                                                          80),
                                                          width: 1,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(
                                                            order.paymentMethod
                                                                        .toLowerCase() ==
                                                                    'mbway'
                                                                ? Icons
                                                                    .phone_android
                                                                : order.paymentMethod
                                                                            .toLowerCase() ==
                                                                        'saldo'
                                                                    ? Icons
                                                                        .account_balance_wallet
                                                                    : Icons
                                                                        .money,
                                                            size: 16,
                                                            color: order.paymentMethod
                                                                        .toLowerCase() ==
                                                                    'mbway'
                                                                ? Colors.red
                                                                : order.paymentMethod
                                                                            .toLowerCase() ==
                                                                        'saldo'
                                                                    ? Colors.orange[
                                                                        700]
                                                                    : Color
                                                                        .fromARGB(
                                                                            255,
                                                                            76,
                                                                            175,
                                                                            80),
                                                          ),
                                                          SizedBox(width: 4),
                                                          Text(
                                                            order.paymentMethod
                                                                        .toLowerCase() ==
                                                                    'mbway'
                                                                ? 'MBWay'
                                                                : order.paymentMethod
                                                                            .toLowerCase() ==
                                                                        'saldo'
                                                                    ? 'Saldo'
                                                                    : 'Dinheiro',
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              color: order.paymentMethod
                                                                          .toLowerCase() ==
                                                                      'mbway'
                                                                  ? Colors.red
                                                                  : order.paymentMethod
                                                                              .toLowerCase() ==
                                                                          'saldo'
                                                                      ? Colors.orange[
                                                                          700]
                                                                      : Color.fromARGB(
                                                                          255,
                                                                          76,
                                                                          175,
                                                                          80),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 12),
                                                Card(
                                                  elevation: 4,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    child: Image.memory(
                                                      decodedBytes,
                                                      width: 100,
                                                      height: 100,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context,
                                                          error, stackTrace) {
                                                        return Container(
                                                          width: 100,
                                                          height: 100,
                                                          color:
                                                              Colors.grey[300],
                                                          child: Icon(
                                                            Icons.error,
                                                            color: Colors.red,
                                                            size: 40,
                                                          ),
                                                        );
                                                      },
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              child: Text(
                                                'Fechar',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              onPressed: () {
                                                Navigator.of(context).pop();
                                              },
                                            ),
                                            TextButton(
                                              child: Text(
                                                'Eliminar Pedido',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.red,
                                                ),
                                              ),
                                              onPressed: () {
                                                _showDeleteDialog(order);
                                              },
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                  child: Card(
                                    color: Color.fromARGB(255, 228, 225, 223),
                                    elevation: 4.0,
                                    child: Padding(
                                      padding: EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Pedido ${order.number}',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 14,
                                                        color: Colors.black87,
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                    SizedBox(height: 6),
                                                    Text(
                                                      'Nome: ${order.requester}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[800],
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'Turma: ${order.group}',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[800],
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 1,
                                                    ),
                                                    SizedBox(height: 4),
                                                    Text(
                                                      'Descrição: $groupedDescription',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey[800],
                                                      ),
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                      maxLines: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(width: 12),
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.memory(
                                                  decodedBytes,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error,
                                                      stackTrace) {
                                                    return Container(
                                                      width: 100,
                                                      height: 100,
                                                      color: Colors.grey[300],
                                                      child: Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                        size: 40,
                                                      ),
                                                    );
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Total: $formattedTotal€',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                              Text(
                                                'Troco: ${double.parse(order.troco).toStringAsFixed(2).replaceAll('.', ',')}€',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[800],
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Display payment method
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.end,
                                            children: [
                                              Container(
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: order.paymentMethod
                                                              .toLowerCase() ==
                                                          'mbway'
                                                      ? Color.fromARGB(
                                                          255, 232, 240, 254)
                                                      : order.paymentMethod
                                                                  .toLowerCase() ==
                                                              'saldo'
                                                          ? Colors.orange[50]
                                                          : Color.fromARGB(255,
                                                              239, 249, 239),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: order.paymentMethod
                                                                .toLowerCase() ==
                                                            'mbway'
                                                        ? Colors.red
                                                        : order.paymentMethod
                                                                    .toLowerCase() ==
                                                                'saldo'
                                                            ? Colors
                                                                .orange[700]!
                                                            : Color.fromARGB(
                                                                255,
                                                                76,
                                                                175,
                                                                80),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Icon(
                                                      order.paymentMethod
                                                                  .toLowerCase() ==
                                                              'mbway'
                                                          ? Icons.phone_android
                                                          : order.paymentMethod
                                                                      .toLowerCase() ==
                                                                  'saldo'
                                                              ? Icons
                                                                  .account_balance_wallet
                                                              : Icons.money,
                                                      size: 16,
                                                      color: order.paymentMethod
                                                                  .toLowerCase() ==
                                                              'mbway'
                                                          ? Colors.red
                                                          : order.paymentMethod
                                                                      .toLowerCase() ==
                                                                  'saldo'
                                                              ? Colors
                                                                  .orange[700]
                                                              : Color.fromARGB(
                                                                  255,
                                                                  76,
                                                                  175,
                                                                  80),
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      order.paymentMethod
                                                                  .toLowerCase() ==
                                                              'mbway'
                                                          ? 'MBWay'
                                                          : order.paymentMethod
                                                                      .toLowerCase() ==
                                                                  'saldo'
                                                              ? 'Saldo'
                                                              : 'Dinheiro',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: order.paymentMethod
                                                                    .toLowerCase() ==
                                                                'mbway'
                                                            ? Colors.red
                                                            : order.paymentMethod
                                                                        .toLowerCase() ==
                                                                    'saldo'
                                                                ? Colors
                                                                    .orange[700]
                                                                : Color.fromARGB(
                                                                    255,
                                                                    76,
                                                                    175,
                                                                    80),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 12),
                                          ElevatedButton(
                                            onPressed: () {
                                              if (buttonText == "Preparar") {
                                                _prepareOrder(order, data);
                                              } else if (buttonText ==
                                                  "Concluir") {
                                                _markOrderAsCompleted(order);
                                              }
                                            },
                                            child: Text(
                                              buttonText!,
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: buttonColor,
                                              foregroundColor: Colors.white,
                                              minimumSize:
                                                  Size(double.infinity, 40),
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 12),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ),
          floatingActionButton: isDayOpen == true
              ? SpeedDial(
                  animatedIcon: AnimatedIcons.menu_close,
                  backgroundColor: Color.fromARGB(255, 246, 141, 45),
                  overlayColor: Colors.black,
                  overlayOpacity: 0.3,
                  children: [
                    SpeedDialChild(
                      child: Icon(Icons.add, color: Colors.white),
                      backgroundColor: Colors.green,
                      label: 'Novo Registo',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) =>
                              NewRegistrationDialog(cart: _cart),
                        );
                      },
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.close, color: Colors.white),
                      backgroundColor: Colors.red,
                      label: 'Fechar Dia',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Fechar Dia'),
                            content:
                                Text('Tem a certeza que deseja fechar o dia?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: Text('Cancelar'),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () async {
                                  Navigator.of(context).pop();
                                  await _closeDay();
                                },
                                child: Text('Fechar Dia'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                    SpeedDialChild(
                      child: Icon(Icons.calculate, color: Colors.white),
                      backgroundColor: Colors.blue,
                      label: 'Calculadora',
                      labelStyle: TextStyle(fontWeight: FontWeight.bold),
                      onTap: _toggleCalculator,
                    ),
                  ],
                )
              : null,
        ),
        if (_showCalculator)
          Positioned(
            left: _calculatorOffset.dx,
            top: _calculatorOffset.dy,
            child: Draggable(
              feedback: Material(
                color: Colors.transparent,
                child: CalculatorWidget(onClose: _toggleCalculator),
              ),
              childWhenDragging: Container(),
              onDragEnd: (details) {
                setState(() {
                  _calculatorOffset = details.offset;
                });
              },
              child: CalculatorWidget(onClose: _toggleCalculator),
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _pingTimer?.cancel();
    _channel?.sink.close();
    purchaseOrderController.close();
    _inactivityTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class NewRegistrationDialog extends StatefulWidget {
  final List<Map<String, dynamic>> cart;
  const NewRegistrationDialog({required this.cart, Key? key}) : super(key: key);

  @override
  _NewRegistrationDialogState createState() => _NewRegistrationDialogState();
}

class _NewRegistrationDialogState extends State<NewRegistrationDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _allProducts = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  TextEditingController _searchController = TextEditingController();
  Map<String, int> _availableQuantities = {};

  @override
  void initState() {
    super.initState();
    _getAllProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<int> getAvailableQuantity(String productName) async {
    if (_availableQuantities.containsKey(productName)) {
      return _availableQuantities[productName]!;
    }
    int qty = await _checkQuantity(productName);
    if (mounted) {
      setState(() {
        _availableQuantities[productName] = qty;
      });
    }
    return qty;
  }

  // Get effective quantity for display (shows base product quantity for variations)
  Future<int> getEffectiveQuantity(String productName) async {
    return await BaseProductService.getEffectiveQuantity(productName);
  }

  Future<int> _checkQuantity(String productName) async {
    try {
      // Use o nome original, sem removeDiacritics
      String cleanProductName = productName.replaceAll('"', '').trim();
      final response = await http.get(Uri.parse(
          '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=8&nome=$cleanProductName'));
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        if (data is Map && data.containsKey('error')) return 0;
        if (data is List && data.isNotEmpty) {
          return int.tryParse(data[0]['Qtd'].toString()) ?? 0;
        }
      }
      return 0;
    } catch (e) {
      print('Error checking quantity: $e');
      return 0;
    }
  }

  Future<void> _getAllProducts() async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_Post.php'),
        body: {'query_param': '4'},
      );
      if (response.statusCode == 200) {
        List<dynamic> jsonData = json.decode(response.body);
        setState(() {
          _allProducts =
              jsonData.map((item) => item as Map<String, dynamic>).toList();
          _filteredProducts = _allProducts;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar produtos: $e')),
      );
    }
  }

  void _filterProducts() {
    final query = removeDiacritics(_searchController.text.toLowerCase());
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final productName =
            removeDiacritics(product['Nome'].toString().toLowerCase());
        return productName.contains(query);
      }).toList();
    });
  }

  void _addToCart(Map<String, dynamic> product) {
    final productName = product['Nome'].toString();
    int availableQuantity = _availableQuantities[productName] ?? 0;
    int currentQuantityInCart =
        widget.cart.where((item) => item['Nome'] == productName).length;

    if (currentQuantityInCart < availableQuantity) {
      setState(() {
        widget.cart.add(product);
        // Manually decrement cached quantity for instant UI feedback
        _availableQuantities[productName] = availableQuantity - 1;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Quantidade máxima para "$productName" atingida.')),
      );
    }
  }

  void _removeFromCart(String productName) {
    setState(() {
      final index =
          widget.cart.lastIndexWhere((item) => item['Nome'] == productName);
      if (index != -1) {
        widget.cart.removeAt(index);
        // Manually increment cached quantity
        if (_availableQuantities.containsKey(productName)) {
          _availableQuantities[productName] =
              _availableQuantities[productName]! + 1;
        }
      }
    });
  }

  double _calculateTotal() {
    return widget.cart
        .fold(0.0, (sum, item) => sum + double.parse(item['Preco'].toString()));
  }

// Função para converter imagem para base64
  Future<String> _getImageAsBase64() async {
    try {
      final ByteData data = await rootBundle.load('lib/assets/barapp.png');
      final Uint8List bytes = data.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (e) {
      print('Erro ao carregar imagem: $e');
      return '';
    }
  }

// Exemplo de função para finalizar a compra com o fluxo correto
  Future<void> finalizarCompra(
    BuildContext context,
    List<Map<String, dynamic>> cart,
    String nif,
    String nomeCliente,
    String keyId, {
    String morada = '',
    String codigoPostal = '',
    String cidade = '',
    String userId = '0',
    String paymentMethod = 'dinheiro',
  }) async {
    try {
      // Obter imagem em base64
      final imageBase64 = await _getImageAsBase64();

      // 1. Regista a compra na base de dados
      final registoResponse = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php'),
        body: {
          'query_param': '5',
          'nome': nomeCliente,
          'apelido': '',
          'turma': 'N/A',
          'descricao': cart.map((item) => item['Nome']).join(', '),
          'permissao': 'Bar',
          'total': cart
              .fold(0.0,
                  (sum, item) => sum + double.parse(item['Preco'].toString()))
              .toStringAsFixed(2),
          'valor': cart
              .fold(0.0,
                  (sum, item) => sum + double.parse(item['Preco'].toString()))
              .toStringAsFixed(2),
          'imagem': imageBase64.isNotEmpty
              ? 'data:image/png;base64,$imageBase64'
              : '',
          'payment_method': paymentMethod,
          'phone_number': '--',
          'requestInvoice': '1',
          'nif': nif,
          'documentType': (nif != '999999990' && nif.isNotEmpty) ? 'FR' : 'FS',
          'idUser': userId,
          'customerName': nomeCliente,
          'customerAddress': morada,
          'customerPostalCode': codigoPostal,
          'customerCity': cidade,
          'customerCountry': 'PT',
          'customerVAT': nif,
        },
      );

      if (registoResponse.statusCode == 200) {
        final registoData = json.decode(registoResponse.body);
        final orderNumber = registoData['orderNumber']?.toString();
        if (orderNumber != null) {
          // 2. Marca como concluído
          final concluirResponse = await http.get(Uri.parse(
              '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=17&nome=$nomeCliente&npedido=$orderNumber&op=2'));
          if (concluirResponse.statusCode == 200) {
            // 3. Só agora faz a faturação
            await registrarCompraComFaturacao(context,
                nif: nif, keyId: keyId, nome: nomeCliente, cart: cart);
            // 4. Limpa o carrinho e fecha o modal/dialog
            setState(() {
              widget.cart.clear();
            });
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao concluir pedido.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao obter número do pedido.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao registar compra.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro inesperado: $e')),
      );
    }
  }

  Future<void> _registerPurchase({
    bool querFatura = false,
    String nifCliente = '',
    String nomeCliente = '',
    String moradaCliente = '',
    String codigoPostalCliente = '',
    String cidadeCliente = '',
    String userIdCliente = '0',
  }) async {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('O carrinho está vazio.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final description = widget.cart.map((item) => item['Nome']).join(', ');
      final total = _calculateTotal();

      // Definir dados de faturação conforme escolha do cliente
      final String nif = querFatura ? nifCliente : '999999990';
      final String nome = querFatura ? nomeCliente : 'Consumidor Final';
      final String morada = querFatura ? moradaCliente : '';
      final String codigoPostal = querFatura ? codigoPostalCliente : '';
      final String cidade = querFatura ? cidadeCliente : '';
      final String userId = querFatura ? userIdCliente : '0';
      final String requestInvoice = querFatura ? '1' : '0';

      // Agrupar carrinho por produto para obter quantidade
      Map<String, int> groupedCart = {};
      for (var item in widget.cart) {
        final name = item['Nome'].toString();
        groupedCart[name] = (groupedCart[name] ?? 0) + 1;
      }

      // Obter XDReference e construir order_lines
      List<Map<String, dynamic>> orderLines = [];
      for (final entry in groupedCart.entries) {
        final productName = entry.key;
        final quantity = entry.value;
        final xdReference = await _getXDReferenceByName(productName);
        if (xdReference != null) {
          orderLines.add({
            'reference': xdReference,
            'quantity': quantity,
          });
        }
      }

      // Definir documentType e customerId localmente
      String documentType =
          (nif != '999999990' && nif.isNotEmpty) ? 'FR' : 'FS';
      String customerId =
          '0'; // Use '0' if you don't have a real keyId in this context

      final billingPayload = {
        'query_param': 1,
        'user_id': 0,
        'vat': nif.toString(),
        'name': nome.toString(),
        'address': ''.toString(),
        'postalCode': ''.toString(),
        'city': ''.toString(),
        'country': 'PT',
        'documentType': documentType.toString(),
        'customer_id': customerId.toString(),
        'order_lines': orderLines
            .map((line) => {
                  'reference': line['reference'].toString(),
                  'quantity': line['quantity'], // keep as int
                })
            .toList(),
      };

      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php'),
        body: {
          'query_param': '5',
          'nome': 'Bar',
          'apelido': '',
          'orderNumber': '0',
          'turma': 'N/A',
          'descricao': description,
          'permissao': 'Bar',
          'total': total.toString(),
          'valor': total.toString(),
          'imagem': '',
          'payment_method': 'dinheiro',
          'phone_number': '--',
          'requestInvoice': requestInvoice,
          'nif': nif,
          'CustomerName': nome,
          'CustomerAddress': morada,
          'CustomerPostalCode': codigoPostal,
          'CustomerCity': cidade,
          'user_id': userId,
        },
      );
                print('Desconto de stock - Status: \\${response.body}');


      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          final orderNumber = data['orderNumber'];

          // Descontar stock dos produtos comprados
          final grouped = _getGroupedCart();
          final ids = grouped.keys.map((name) {
            final item = widget.cart.firstWhere((p) => p['Nome'] == name);
            // Tente pegar idApp, Id, id, etc.
            return (item['idApp'] ?? item['Id'] ?? item['id'] ?? '').toString();
          }).join(',');
          final quantities = grouped.values.join(',');
          final stockResponse = await http.get(Uri.parse(
              '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=18&op=2&ids=$ids&quantities=$quantities'));
          // Debug da resposta da API de desconto de stock
          print('Desconto de stock - Status: \\${stockResponse.statusCode}');
          print('Desconto de stock - Body: \\${stockResponse.body}');
          // Opcional: podes verificar stockResponse.statusCode e mostrar erro se necessário

          // Mark the order as completed immediately
          final completeResponse = await http.get(Uri.parse(
              '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=17&nome=Bar&npedido=$orderNumber&op=2'));

          if (completeResponse.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      'Compra registada e concluída! Pedido Nº $orderNumber')),
            );
            // Limpa o carrinho
            setState(() {
              widget.cart.clear();
            });
            Navigator.of(context).pop();
          } else {
            throw Exception('Erro ao marcar pedido como concluído.');
          }
        } else {
          throw Exception(data['message'] ?? 'Unknown error');
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao registar a compra: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Map<String, int> _getGroupedCart() {
    Map<String, int> grouped = {};
    for (var item in widget.cart) {
      final name = item['Nome'].toString();
      grouped[name] = (grouped[name] ?? 0) + 1;
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
      title: Row(
        children: [
          Icon(Icons.shopping_cart, color: Colors.orange, size: 28),
          SizedBox(width: 8),
          Text(
            'Novo Registo de Compra',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.orange[800],
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Container(
        width: double.maxFinite,
        height: 540,
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.orange))
            : Column(
                children: [
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(10),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Pesquisar produto por nome...',
                        labelStyle: TextStyle(color: Colors.orange),
                        prefixIcon: Icon(Icons.search, color: Colors.orange),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.orange, width: 2),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(color: Colors.orange.withOpacity(0.5)),
                        ),
                        filled: true,
                        fillColor: Colors.orange[50],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = _filteredProducts[index];
                        final productName = product['Nome'].toString();
                        final productImage = product['Imagem'] as String?;
                        return Card(
                          elevation: 2,
                          margin: EdgeInsets.symmetric(vertical: 4),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          child: ListTile(
                            leading: productImage != null && productImage.isNotEmpty
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      base64Decode(productImage),
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Icon(Icons.fastfood, color: Colors.orange, size: 32),
                            title: Text(productName,
                                style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text('${product['Preco']}€',
                                style: TextStyle(
                                    color: Colors.orange[800],
                                    fontWeight: FontWeight.bold)),
                            trailing: FutureBuilder<int>(
                              future: getAvailableQuantity(productName),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting &&
                                    !_availableQuantities.containsKey(productName)) {
                                  return SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.orange));
                                }
                                final qty = _availableQuantities[productName] ?? 0;
                                final isAvailable = qty > 0;
                                return Tooltip(
                                  message: isAvailable ? 'Adicionar ao carrinho' : 'Indisponível',
                                  child: IconButton(
                                    icon: Icon(Icons.add_circle,
                                        color: isAvailable ? Colors.green : Colors.grey[400], size: 28),
                                    onPressed: isAvailable ? () => _addToCart(product) : null,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Divider(height: 20, thickness: 1),
                  Row(
                    children: [
                      Icon(Icons.shopping_basket, color: Colors.orange[800]),
                      SizedBox(width: 8),
                      Text('Carrinho',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.orange[800])),
                    ],
                  ),
                  Expanded(
                    child: widget.cart.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.remove_shopping_cart, size: 48, color: Colors.grey[400]),
                              SizedBox(height: 8),
                              Text('O carrinho está vazio.',
                                  style: TextStyle(color: Colors.grey, fontSize: 16)),
                            ],
                          )
                        : ListView.builder(
                            itemCount: _getGroupedCart().length,
                            itemBuilder: (context, index) {
                              final entry = _getGroupedCart().entries.elementAt(index);
                              final productName = entry.key;
                              final quantity = entry.value;
                              final item = widget.cart.firstWhere((p) => p['Nome'] == productName);
                              return Card(
                                color: Colors.orange[50],
                                elevation: 1,
                                margin: EdgeInsets.symmetric(vertical: 4),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                child: ListTile(
                                  dense: true,
                                  leading: Icon(Icons.shopping_cart, color: Colors.orange[700]),
                                  title: Text('$quantity x $productName',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text('${item['Preco']}€ cada',
                                      style: TextStyle(
                                          color: Colors.orange[800], fontWeight: FontWeight.bold)),
                                  trailing: Tooltip(
                                    message: 'Remover do carrinho',
                                    child: IconButton(
                                      icon: Icon(Icons.remove_circle_outline, color: Colors.red[700]),
                                      onPressed: () => _removeFromCart(productName),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Total: ${_calculateTotal().toStringAsFixed(2)}€',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                        color: Colors.orange[900]),
                  ),
                ],
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => {Navigator.of(context).pop(), widget.cart.clear()},
          child: Row(
            children: [
              Icon(Icons.cancel, color: Colors.orange),
              SizedBox(width: 4),
              Text('Cancelar', style: TextStyle(color: Colors.orange)),
            ],
          ),
        ),
        ElevatedButton.icon(
          onPressed: _isLoading || widget.cart.isEmpty
              ? null
              : () async {
                  await showFaturacaoDialogERegistrarCompra(context);
                },
          icon: Icon(Icons.check_circle, color: Colors.white),
          label: Text('Registar Compra'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            textStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> showFaturacaoDialogERegistrarCompra(BuildContext context) async {
    // 1. Pergunta se deseja fatura com NIF
    bool querNIF = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Fatura com NIF?'),
            content: Text('Deseja fatura com número de contribuinte (NIF)?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Não'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sim'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ??
        false;

    String nif = '999999990';
    String keyId = '0';
    String nomeCliente = 'Consumidor Final';

    if (querNIF) {
      // 2. Solicita o NIF com validação
      String? nifInput = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          bool isValid = false;
          String validationMessage = '';

          return StatefulBuilder(
            builder: (context, setState) {
              void validateNIF(String value) {
                final cleanedNIF = value.replaceAll(RegExp(r'[^0-9]'), '');
                if (cleanedNIF.length != 9) {
                  setState(() {
                    isValid = false;
                    validationMessage = 'O NIF precisa de ter 9 dígitos';
                  });
                  return;
                }

                final firstDigit = int.tryParse(cleanedNIF[0]);
                if (firstDigit == null ||
                    ![1, 2, 3, 5, 6, 7, 8, 9].contains(firstDigit)) {
                  setState(() {
                    isValid = false;
                    validationMessage = 'Primeiro dígito inválido';
                  });
                  return;
                }

                // Calcular dígito de controlo
                int total = 0;
                for (int i = 0; i < 8; i++) {
                  total += int.parse(cleanedNIF[i]) * (9 - i);
                }
                final remainder = total % 11;
                final checkDigit =
                    (remainder == 0 || remainder == 1) ? 0 : 11 - remainder;

                if (int.parse(cleanedNIF[8]) != checkDigit) {
                  setState(() {
                    isValid = false;
                    validationMessage = 'NIF inválido';
                  });
                  return;
                }

                setState(() {
                  isValid = true;
                  validationMessage = 'NIF válido';
                });
              }

              return AlertDialog(
                title: Text('Introduza o NIF'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      keyboardType: TextInputType.number,
                      maxLength: 9,
                      decoration: InputDecoration(
                        hintText: 'NIF',
                        border: OutlineInputBorder(),
                        counterText: '',
                      ),
                      onChanged: validateNIF,
                    ),
                    if (validationMessage.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          validationMessage,
                          style: TextStyle(
                            color: isValid ? Colors.green : Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancelar'),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: isValid
                        ? () => Navigator.pop(context, controller.text.trim())
                        : null,
                    child: Text('OK'),
                    style: TextButton.styleFrom(
                      backgroundColor:
                          isValid ? Colors.orange : Colors.grey[300],
                      foregroundColor:
                          isValid ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ],
              );
            },
          );
        },
      );

      if (nifInput == null || nifInput.isEmpty) return; // Cancelado
      nif = nifInput;

      // 3. Pesquisa clientes na XD (ciclo for 1 a 1000) com loading
      List<Map<String, dynamic>> clientesXD = [];

      // Mostrar loading durante a pesquisa
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('A pesquisar clientes...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('A pesquisar clientes com NIF: $nif'),
            ],
          ),
        ),
      );

          try {
      final response = await http
          .post(
            Uri.parse('http://192.168.22.88/api/api.php'),
            body: json.encode({
              'query_param': 2.1,
              'vat': nif,
            }),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map && data['success'] == true && data['customer'] != null) {
          final customer = data['customer'];
          if (customer['success'] == true) {
            // Cliente encontrado
            clientesXD.add(Map<String, dynamic>.from(customer));
          } else {
            // Cliente não encontrado - não adicionar à lista
            print('Cliente com NIF $nif não encontrado: ${customer['message']}');
          }
        }
      } else {
        print('Erro na API: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Erro geral na pesquisa: $e');
    }

      // Fechar loading
      Navigator.pop(context);

      // 4. Mostra confirmação do cliente encontrado
      Map<String, dynamic>? clienteSelecionado;
      if (clientesXD.isNotEmpty) {
        // Cliente encontrado - mostrar confirmação
        final cliente = clientesXD.first;
        bool usarClienteEncontrado = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Cliente encontrado'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Nome: ${cliente['name']?.toString() ?? 'N/A'}'),
                Text('NIF: ${cliente['vat']?.toString() ?? 'N/A'}'),
                Text('Morada: ${cliente['address']?.toString() ?? 'N/A'}'),
                Text('Cidade: ${cliente['city']?.toString() ?? 'N/A'}'),
                SizedBox(height: 16),
                Text('Deseja usar este cliente?'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Não, usar Cliente Passante'),
                style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Sim, usar este cliente'),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ) ?? false;
        
        if (usarClienteEncontrado) {
          clienteSelecionado = cliente;
        }
      } else {
        // Se não encontrou clientes, perguntar se quer introduzir manualmente
        bool introduzirManual = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Nenhum cliente encontrado'),
                content: Text(
                    'Não foi encontrado nenhum cliente com o NIF $nif. Deseja introduzir manualmente como Cliente Passante?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: Text('Cancelar'),
                    style:
                        TextButton.styleFrom(foregroundColor: Colors.grey[600]),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text('Sim'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ) ??
            false;

        if (!introduzirManual) return; // Cancelado
      }

      if (clienteSelecionado != null) {
        // Usar cliente selecionado
        keyId = clienteSelecionado['keyId']?.toString() ?? '0';
        nif = clienteSelecionado['vat']?.toString() ?? nif;
        nomeCliente = clienteSelecionado['name']?.toString() ?? 'Cliente';
      } else {
        // Permitir introdução manual de NIF e fatura como Cliente Passante
        nomeCliente = 'Cliente Passante';
      }
    }

    // 5. Registar a compra/faturar com os dados escolhidos
    await finalizarCompra(
      context,
      widget.cart,
      nif,
      nomeCliente,
      keyId,
      morada: '',
      codigoPostal: '',
      cidade: '',
      userId: '0',
      paymentMethod: 'dinheiro',
    );
  }

  Future<void> registrarCompraComFaturacao(BuildContext context,
      {required String nif,
      required String keyId,
      required String nome,
      required List<Map<String, dynamic>> cart}) async {
    try {
      // Mostrar loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('A processar...'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('A registar compra e emitir fatura...'),
            ],
          ),
        ),
      );

      print('Registando compra com NIF: $nif, keyId: $keyId, nome: $nome');

      Future<String?> _getXDReferenceByName(String productName) async {
        try {
          final response = await http.get(
            Uri.parse(
                '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=5.1&nome=${Uri.encodeComponent(productName)}'),
          );
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            if (data is List &&
                data.isNotEmpty &&
                data[0]['XDReference'] != null) {
              return data[0]['XDReference'].toString();
            }
          }
        } catch (e) {
          print('Erro ao obter XDReference para $productName: $e');
        }
        return null;
      }

      // Agrupar carrinho por produto para obter quantidade
      Map<String, int> groupedCart = {};
      for (var item in cart) {
        final name = item['Nome'].toString();
        groupedCart[name] = (groupedCart[name] ?? 0) + 1;
      }

      // Obter XDReference e construir order_lines
      List<Map<String, dynamic>> orderLines = [];
      for (final entry in groupedCart.entries) {
        final productName = entry.key;
        final quantity = entry.value;
        final xdReference = await _getXDReferenceByName(productName);
        if (xdReference != null) {
          orderLines.add({
            'reference': xdReference.toString(),
            'quantity': quantity,
          });
        }
      }

      String documentType =
          (nif != '999999990' && nif.isNotEmpty) ? 'FR' : 'FS';
      String customerId = keyId ?? '0';
      final billingPayload = {
        'query_param': '1',
        'user_id': '0',
        'vat': nif.toString(),
        'name': nome.toString(),
        'address': ''.toString(),
        'postalCode': ''.toString(),
        'city': ''.toString(),
        'country': 'PT',
        'documentType': documentType.toString(),
        'customer_id': customerId.toString(),
        'order_lines': orderLines,
      };
      print('[INVOICE API] Payload: ' + json.encode(billingPayload));
      final response = await http.post(
        Uri.parse('http://192.168.22.88/api/api.php'),
        body: json.encode(billingPayload),
        headers: {'Content-Type': 'application/json'},
      );
      print('[INVOICE API] Status: ' + response.statusCode.toString());
      print('[INVOICE API] Body: ' + response.body);
      // Fechar loading
      Navigator.pop(context);

      if (response.statusCode == 200) {
        print(
            '[INVOICE API] Invoice registered successfully, now marking order as completed.');
        try {
          final data = json.decode(response.body);
          final orderNumber = data['orderNumber'] ?? null;
          if (orderNumber != null) {
            final completeResponse = await http.get(Uri.parse(
                '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=17&nome=Bar&npedido=$orderNumber&op=2'));
            print('[INVOICE API] Mark as completed status: ' +
                completeResponse.statusCode.toString());
            print('[INVOICE API] Mark as completed body: ' +
                completeResponse.body);
            if (completeResponse.statusCode == 200) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Compra registada e concluída! Pedido Nº $orderNumber'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Fatura emitida, mas erro ao concluir pedido.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Fatura emitida, mas não foi possível concluir o pedido automaticamente.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        } catch (e) {
          print('Erro ao marcar pedido como concluído: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Fatura emitida, mas erro ao concluir pedido.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar faturação: ${response.body}'),
            backgroundColor: Colors.red,
          ),
        );
      }

      // Descontar stock dos produtos comprados após faturação XD
      final grouped = <String, int>{};
      for (var item in cart) {
        final name = item['Nome'].toString();
        grouped[name] = (grouped[name] ?? 0) + 1;
      }
      final ids = grouped.keys.map((name) {
        final item = cart.firstWhere((p) => p['Nome'] == name);
        return (item['idApp'] ?? item['Id'] ?? item['id'] ?? '').toString();
      }).join(',');
      final quantities = grouped.values.join(',');
      final stockResponse = await http.get(Uri.parse(
          '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=18&op=2&ids=$ids&quantities=$quantities'));
      print('Desconto de stock - Status: ${stockResponse.statusCode}');
      print('Desconto de stock - Body: ${stockResponse.body}');
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao processar faturação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Dentro da classe _NewRegistrationDialogState:
  Future<String?> _getXDReferenceByName(String productName) async {
    try {
      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=5.1&nome=${Uri.encodeComponent(productName)}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List && data.isNotEmpty && data[0]['XDReference'] != null) {
          return data[0]['XDReference'].toString();
        }
      }
    } catch (e) {
      print('Erro ao obter XDReference para $productName: $e');
    }
    return null;
  }
}

// Widget de calculadora simples e movível
class CalculatorWidget extends StatefulWidget {
  final VoidCallback onClose;
  const CalculatorWidget({required this.onClose});

  @override
  State<CalculatorWidget> createState() => _CalculatorWidgetState();
}

class _CalculatorWidgetState extends State<CalculatorWidget> {
  String _expression = '';
  String _result = '';

  void _onPressed(String value) {
    setState(() {
      if (value == 'C') {
        _expression = '';
        _result = '';
      } else if (value == '=') {
        try {
          _result = _calculate(_expression);
        } catch (e) {
          _result = 'Erro';
        }
      } else {
        // Se já foi calculado e o utilizador clica num operador, continua com o resultado
        if (_result.isNotEmpty) {
          if ('+-*/'.contains(value)) {
            _expression = _result + value;
            _result = '';
          } else if ('0123456789.'.contains(value)) {
            // Se clicar num número, começa novo cálculo
            _expression = value;
            _result = '';
          } else {
            _expression += value;
            _result = '';
          }
        } else {
          _expression += value;
        }
      }
    });
  }

  String _calculate(String expr) {
    // Simples parser para + - * /
    expr = expr.replaceAll('×', '*').replaceAll('÷', '/');
    double res = double.parse(_evaluate(expr));
    return res.toString();
  }

  String _evaluate(String expr) {
    // Usa a função Expression do Dart, mas para simplicidade, faz apenas eval básico
    // (não recomendado para produção, mas suficiente para calculadora simples)
    try {
      // Remove espaços
      expr = expr.replaceAll(' ', '');
      // Expressão simples, sem parênteses
      List<String> tokens = [];
      String number = '';
      for (int i = 0; i < expr.length; i++) {
        String c = expr[i];
        if ('0123456789.'.contains(c)) {
          number += c;
        } else {
          if (number.isNotEmpty) {
            tokens.add(number);
            number = '';
          }
          tokens.add(c);
        }
      }
      if (number.isNotEmpty) tokens.add(number);
      // Primeiro *, /
      for (int i = 0; i < tokens.length; i++) {
        if (tokens[i] == '*' || tokens[i] == '/') {
          double left = double.parse(tokens[i - 1]);
          double right = double.parse(tokens[i + 1]);
          double res = tokens[i] == '*' ? left * right : left / right;
          tokens.replaceRange(i - 1, i + 2, [res.toString()]);
          i = 0;
        }
      }
      // Depois +, -
      double result = double.parse(tokens[0]);
      for (int i = 1; i < tokens.length; i += 2) {
        String op = tokens[i];
        double next = double.parse(tokens[i + 1]);
        if (op == '+') result += next;
        if (op == '-') result -= next;
      }
      return result.toString();
    } catch (e) {
      return '0';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 260,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Calculadora',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.orange[800])),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.red),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            SizedBox(height: 8),
            Container(
              alignment: Alignment.centerRight,
              child: Text(_expression,
                  style: TextStyle(fontSize: 20, color: Colors.black87)),
            ),
            Container(
              alignment: Alignment.centerRight,
              child: Text(_result,
                  style: TextStyle(
                      fontSize: 22,
                      color: Colors.green,
                      fontWeight: FontWeight.bold)),
            ),
            SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              physics: NeverScrollableScrollPhysics(),
              children: [
                '7',
                '8',
                '9',
                '/',
                '4',
                '5',
                '6',
                '*',
                '1',
                '2',
                '3',
                '-',
                '0',
                '.',
                'C',
                '+',
                '='
              ].map((e) {
                if (e == '=') {
                  return GridTile(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _onPressed(e),
                      child: Text(e,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                  );
                }
                return GridTile(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          e == 'C' ? Colors.red[200] : Colors.grey[200],
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => _onPressed(e),
                    child: Text(e, style: TextStyle(fontSize: 20)),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
