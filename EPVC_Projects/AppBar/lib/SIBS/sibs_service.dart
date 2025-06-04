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
        
        // Verificar especificamente o erro E9999 (problema no número do telefone)
        if (errorBody['returnStatus'] != null && 
            errorBody['returnStatus']['statusCode'] == 'E9999') {
          throw Exception('Número MB WAY inválido ou inativo. Verifique o número e tente novamente.');
        }
        
        // Outros erros 
        throw Exception(
            'Failed to create MBWay payment: ${errorBody['httpMessage'] ?? errorBody['returnStatus']?['statusMsg'] ?? 'Unknown error'}');
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
      final payload = {
        "transactionID": transactionId,
        "transactionSignature": transactionSignature,
        "timestamp": DateTime.now().toUtc().toIso8601String(),
        "paymentMethod": "MBWAY",
        "paymentStatus": "PENDING",
        "amount": {
          "value": 0, // Will be updated when payment completes
          "currency": "EUR"
        }
      };

      print('Sending to webhook with payload: ${json.encode(payload)}');

      final response = await http.post(
        Uri.parse('https://api.appbar.epvc.pt/api/sibs/initial'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      print('Webhook registration response: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          return jsonDecode(response.body);
        } catch (e) {
          // If response isn't JSON, return simple success
          return {"status": "success", "message": "Transaction registered with webhook"};
        }
      } else {
        throw Exception('Failed to register transaction with webhook: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('Webhook registration error: $e');
      // Don't throw an exception, just return an error status
      return {"status": "error", "message": "Failed to register with webhook: $e"};
    }
  }

  double roundToTwoDecimals(double value) {
  return (value * 100).roundToDouble() / 100;
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
          "description": "Pedido AppBar - $orderNumber",
          "moto": false,
          "paymentType": "PURS",
          "amount": {"value": roundToTwoDecimals(amount), "currency": "EUR"},
          "paymentMethod": ["MBWAY", "REFERENCE"],
          "paymentReference": {
            "initialDatetime": timestamp,
            "finalDatetime": expiry,
            "maxAmount": {"value": roundToTwoDecimals(amount), "currency": "EUR"},
            "minAmount": {"value": roundToTwoDecimals(amount), "currency": "EUR"},
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
      print('Checking payment status for ID: $paymentId');
      // Use webhook instead of direct SIBS API
      final response = await http.get(
        Uri.parse('https://api.appbar.epvc.pt/api/status/$paymentId'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Status check response: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('Raw response: ${response.body}');
        final data = json.decode(response.body);
        
        // The response already contains the status in the correct format
        // Example response: {"paymentStatus": "Declined", "amount": {"value": null}, "returnStatus": {}, "rawResponse": {}}
        String resultStatus = data['paymentStatus'] ?? 'Pending';
        print('Payment status: $resultStatus');
        
        // Return the response in the expected format
        return {
          'status': resultStatus, // Already properly formatted (Success, Declined, Pending)
          'paymentId': paymentId,
          'transactionId': paymentId, // Use the same ID as we don't have a separate one
          'amount': data['amount']?['value'] ?? 0.0,
          'currency': 'EUR',
          'timestamp': DateTime.now().toIso8601String(),
          'returnStatus': data['returnStatus'] ?? {},
          'rawResponse': data // Include full response for debugging
        };
      } else if (response.statusCode == 404) {
        // If the transaction is not found, consider it pending (may not be registered yet)
        print('Transaction not found in status service, treating as pending');
        return {
          'status': 'Pending',
          'paymentId': paymentId,
          'transactionId': paymentId,
          'returnStatus': {
            'statusMsg': 'Transaction not found in status service'
          }
        };
      } else {
        // Attempt to parse error response
        Map<String, dynamic> errorData = {};
        try {
          errorData = json.decode(response.body);
          print('Error response: $errorData');
        } catch (e) {
          errorData = {'message': 'Invalid response format'};
          print('Error parsing response: $e');
        }
        
        throw Exception(
            'Payment status check failed: ${errorData['message'] ?? 'Unknown error (HTTP ${response.statusCode})'}');
      }
    } catch (e) {
      print('Detailed error checking payment status: $e');
      throw Exception('Payment status check error: ${e.toString()}');
    }
  }
}
