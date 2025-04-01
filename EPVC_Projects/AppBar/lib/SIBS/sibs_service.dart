import 'dart:convert';
import 'package:http/http.dart' as http;

class SibsService {
  final String baseUrl = 'https://api.qly.sibspayments.com/sibs/spg/v2';
  final String clientId = '28d23dd7-a494-4d0d-97d5-dc6cd9f85576';
  final String terminalId = '82144';
  final String accessToken;
  final String merchantId;
  final String merchantName;

  SibsService({
    required this.accessToken,
    required this.merchantId,
    required this.merchantName,
  });

  Future<Map<String, dynamic>> createMBWayPayment({
    required String amount,
    required String phoneNumber,
    required String orderId,
    required String description,
    String? callbackUrl,
  }) async {
    try {
      print('Criando pagamento MBWay com:');
      print('Amount: $amount');
      print('OrderId: $orderId');
      print('PhoneNumber: $phoneNumber');
      print('Description: $description');
      print('AccessToken: $accessToken');
      print('ClientId: $clientId');
      print('TerminalId: $terminalId');

      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Client-Id': clientId,
        },
        body: jsonEncode({
          'merchant': {
            'terminalId': terminalId,
            'channel': 'web',
            'merchantTransactionId': orderId,
            'transactionDescription': description,
            'shopURL': 'https://appbar.epvc.pt'
          },
          'transaction': {
            'transactionTimestamp': DateTime.now().toIso8601String(),
            'description': description,
            'moto': false,
            'paymentType': 'PURS',
            'amount': {
              'value': double.parse(amount),
              'currency': 'EUR'
            },
            'paymentMethod': ['MBWAY']
          },
          'payment': {
            'mbway': {
              'phoneNumber': phoneNumber
            }
          },
          'webhook': {
            'url': 'https://appbar.epvc.pt/API/webhook.php',
            'events': ['PAYMENT.SUCCESS', 'PAYMENT.CANCELLED']
          }
        }),
      );

      print('Resposta SIBS: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        print('Erro SIBS: ${response.statusCode} - ${response.body}');
        throw Exception('Erro ao criar pagamento MBWay: ${errorBody['httpMessage']} - ${errorBody['moreInformation']}');
      }
    } catch (e) {
      print('Erro detalhado: $e');
      throw Exception('Erro na comunicação com SIBS: $e');
    }
  }

  Future<Map<String, dynamic>> getPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erro ao obter status do pagamento: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erro na comunicação com SIBS: $e');
    }
  }

  Future<Map<String, dynamic>> initiateMBWayPayment({
    required String amount,
    required String orderNumber,
    required String phoneNumber,
  }) async {
    try {
      print('Iniciando pagamento MBWay com:');
      print('Amount: $amount');
      print('OrderNumber: $orderNumber');
      print('PhoneNumber: $phoneNumber');
      print('AccessToken: $accessToken');
      print('ClientId: $clientId');
      print('TerminalId: $terminalId');

      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'Client-Id': clientId,
        },
        body: json.encode({
          'merchant': {
            'terminalId': terminalId,
            'channel': 'web',
            'merchantTransactionId': orderNumber,
            'transactionDescription': 'Pedido AppBar',
            'shopURL': 'https://appbar.epvc.pt'
          },
          'transaction': {
            'transactionTimestamp': DateTime.now().toIso8601String(),
            'description': 'Pedido AppBar - Nº $orderNumber',
            'moto': false,
            'paymentType': 'PURS',
            'amount': {
              'value': double.parse(amount),
              'currency': 'EUR'
            },
            'paymentMethod': ['MBWAY']
          },
          'payment': {
            'mbway': {
              'phoneNumber': phoneNumber
            }
          },
          'webhook': {
            'url': 'https://appbar.epvc.pt/API/webhook.php',
            'events': ['PAYMENT.SUCCESS', 'PAYMENT.CANCELLED']
          }
        }),
      );

      print('Resposta SIBS: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        print('Erro SIBS: ${response.statusCode} - ${response.body}');
        throw Exception('Erro ao iniciar pagamento MBWay: ${errorBody['httpMessage']} - ${errorBody['moreInformation']}');
      }
    } catch (e) {
      print('Erro detalhado: $e');
      throw Exception('Erro ao processar pagamento MBWay: $e');
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    try {
      print('Verificando status do pagamento: $paymentId');
      print('AccessToken: $accessToken');
      print('ClientId: $clientId');

      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Client-Id': clientId,
        },
      );

      print('Resposta SIBS: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': data['transaction']['status'] ?? 'UNKNOWN',
          'paymentId': paymentId,
          'amount': data['transaction']['amount']['value'],
          'currency': data['transaction']['amount']['currency'],
          'timestamp': data['transaction']['transactionTimestamp']
        };
      } else {
        final errorBody = json.decode(response.body);
        print('Erro SIBS: ${response.statusCode} - ${response.body}');
        throw Exception('Erro ao verificar status do pagamento: ${errorBody['httpMessage']} - ${errorBody['moreInformation']}');
      }
    } catch (e) {
      print('Erro detalhado: $e');
      throw Exception('Erro ao verificar status do pagamento: $e');
    }
  }
} 