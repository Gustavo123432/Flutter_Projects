import 'dart:convert';
import 'package:http/http.dart' as http;

class SibsService {
  final String baseUrl = 'https://api.qly.sibspayments.com/sibs/spg/v2';
  final String clientId = '28d23dd7-a494-4d0d-97d5-dc6cd9f85576';
  final int terminalId = 82144;
  final String accessToken;
  final String merchantId;
  final String merchantName;

  SibsService({
    required this.accessToken,
    required this.merchantId,
    required this.merchantName,
  });

  Future<Map<String, dynamic>> createMBWayPayment({
    required String transactionId,
    required String transactionSignature,
    required String phoneNumber,
    String? callbackUrl,
  }) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final payload = {
        "customerPhone": "351#$phoneNumber",
      };

      print('Creating MBWay payment with payload: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/payments/$transactionId/mbway-id/purchase'),
        headers: {
          'Authorization': 'Digest $transactionSignature',
          'X-IBM-Client-Id': clientId,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      print('SIBS Response: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            'Failed to create MBWay payment: ${errorBody['httpMessage'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Detailed error: $e');
      throw Exception('SIBS communication error: $e');
    }
  }

    Future<Map<String, dynamic>> SendToWebhook({
    required String transactionId,
    required String transactionSignature,
  }) async {
    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      

    

      final response = await http.post(
        Uri.parse('$baseUrl/payments/$transactionId/mbway-id/purchase'),
        headers: {
          'Authorization': 'Digest $transactionSignature',
          'X-IBM-Client-Id': clientId,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(""),
      );

      print('SIBS Response: ${response.statusCode}');
      print('Body: ${response.body}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            'Failed to create MBWay payment: ${errorBody['httpMessage'] ?? 'Unknown error'}');
      }
    } catch (e) {
      print('Detailed error: $e');
      throw Exception('SIBS communication error: $e');
    }
  }

  Future<Map<String, dynamic>> initiateMBWayPayment({
    required double amount,
    required String orderNumber,
    required String phoneNumber,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final timestamp = now.toIso8601String();
      final expiry = now.add(const Duration(days: 2)).toIso8601String();

      final payload = {
        "merchant": {
          "terminalId": 82144,
          "channel": "app",
          "merchantTransactionId": orderNumber
        },
        "transaction": {
          "transactionTimestamp": timestamp,
          "description": "Pedido AppBar - Nº $orderNumber",
          "moto": false,
          "paymentType": "PURS",
          "amount": {"value": amount, "currency": "EUR"},
          "paymentMethod": ["MBWAY", "REFERENCE"],
          "paymentReference": {
            "initialDatetime": timestamp,
            "finalDatetime": expiry,
            "maxAmount": {"value": amount, "currency": "EUR"},
            "minAmount": {"value": amount, "currency": "EUR"},
            "entity": "24000"
          }
        }
      };

      print('Final payload: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse('$baseUrl/payments'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
          'X-IBM-Client-Id': clientId,
        },
        body: json.encode(payload),
      );

      print('SIBS Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('API Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Payment failed: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/payments/$paymentId/status'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'X-IBM-Client-Id': clientId,
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        return {
          'status': data['paymentStatus'] ??
              'UNKNOWN', // Changed from transaction.status
          'transactionStatusCode': data['transactionStatusCode'] ?? 'UNKNOWN',
          'paymentId': paymentId,
          'transactionId':
              data['transactionID'], // Added transactionID from response
          'amount': data['amount']?['value'],
          'currency': data['amount']?['currency'],
          'timestamp': data['execution']?['endTime'], // Using execution.endTime
          'paymentMethod': data['paymentMethod'],
          'phoneNumber': data['token']
              ?['value'], // Added phone number from token
          'returnStatus': data['returnStatus'], // Full status object
          'rawResponse': data // Include full response for debugging
        };
      } else {
        final errorBody = json.decode(response.body);
        throw Exception(
            'Payment status check failed: ${errorBody['returnStatus']?['statusDescription'] ?? errorBody['httpMessage'] ?? 'Unknown error (HTTP ${response.statusCode})'}');
      }
    } catch (e) {
      print('Detailed error: $e');
      throw Exception('Payment status check error: ${e.toString()}');
    }
  }
}
