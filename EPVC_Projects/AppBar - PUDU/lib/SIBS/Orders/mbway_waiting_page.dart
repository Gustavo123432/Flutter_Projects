import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:my_flutter_project/Aluno/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../sibs_service.dart';
import 'mbway_phone_page.dart';
import 'order_declined_page.dart';
import 'order_confirmation_page.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:intl/intl.dart';

class MBWayPaymentWaitingPage extends StatefulWidget {
  final double amount;
  final String transactionId;
  final String phoneNumber;
  final String accessToken;
  final String merchantId;
  final String merchantName;
  final Function(bool success, String message) onPaymentResult;
  final Map<String, dynamic> orderData; // Adicionar dados do pedido

  const MBWayPaymentWaitingPage({
    Key? key,
    required this.amount,
    required this.transactionId,
    required this.phoneNumber,
    required this.accessToken,
    required this.merchantId,
    required this.merchantName,
    required this.onPaymentResult,
    required this.orderData,
  }) : super(key: key);

  @override
  _MBWayPaymentWaitingPageState createState() =>
      _MBWayPaymentWaitingPageState();
}

class _MBWayPaymentWaitingPageState extends State<MBWayPaymentWaitingPage> {
  late Timer _timer;
  int _secondsRemaining = 4 * 60; // 4 minutos em segundos
  bool _isCheckingStatus = false;
  Timer? _statusCheckTimer;
  late SibsService _sibsService;
  int _statusCheckCount = 0; // Counter for status checks
  bool _paymentProcessed = false; // Track if payment has been processed
  dynamic users;

  @override
  void initState() {
    super.initState();
    _sibsService = SibsService(
      accessToken: widget.accessToken,
      merchantId: widget.merchantId,
      merchantName: widget.merchantName,
    );
    _startTimer();
    _startStatusCheck();

  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer.cancel();
          // Tempo expirado - informar o usuário
          widget.onPaymentResult(
              false, "Tempo expirado para o pagamento MB WAY");
          // Redirecionar para a página inicial se o tempo expirar
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => OrderDeclinedPage(amount: widget.amount, reason: "Tempo Expirado",),
            ),
          );
        }
      });
    });
  }

  void _startStatusCheck() {
    // Verificar o status do pagamento a cada 5 segundos
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 3), (timer) async {
      // Skip if already checking or payment has been processed
      if (_isCheckingStatus || _paymentProcessed) return;

      setState(() {
        _isCheckingStatus = false;
      });

      try {
        // Verificar o status do pagamento usando o webhook
        _statusCheckCount++; // Increment check counter
        print('Checking payment status: Attempt $_statusCheckCount');
        
        final result =
            await _sibsService.checkPaymentStatus(widget.transactionId);

        print('Payment status check result: ${result.toString()}');
            
        if (result['status'] == 'Success') {
          // Mark as processed to prevent further checks
          _paymentProcessed = true;
          _timer.cancel();
          _statusCheckTimer?.cancel();
          
          // Processar o pedido diretamente aqui
          try {
            await _processSuccessfulPayment();
          } catch (e) {
            print('Error processing successful payment: $e');
            widget.onPaymentResult(false, "Erro ao processar pedido: $e");
            
            if (mounted) {
              Navigator.pushReplacement(
                context, 
                MaterialPageRoute(
                  builder: (context) => HomeAlunoMain(),
                ),
              );
            }
            return;
          }
        } else if (result['status'] == 'Declined' || result['status'] == 'Cancelled' || result['status'] == 'Error') {
          // Mark as processed to prevent further checks
          _paymentProcessed = true;
          _timer.cancel();
          _statusCheckTimer?.cancel();
          
          // Get error message from returnStatus if available
          String errorMsg = "Pagamento recusado";
          String reasonCode = "Pagamento recusado";
          
          if (result['returnStatus'] != null && result['returnStatus'] is Map && result['returnStatus'].isNotEmpty) {
            errorMsg = result['returnStatus']['statusMsg'] ?? errorMsg;
            reasonCode = result['returnStatus']['statusCode'] ?? "Pagamento recusado";
          }
          
          print('Payment ${result['status']}: $errorMsg (code: $reasonCode)');
          
          // Verificar se é erro E9999 (problema com número de telefone)
          bool isPhoneNumberError = false;
          
          // Verificar todas as condições possíveis para erro de telefone
          if (reasonCode == "E9999") {
            isPhoneNumberError = true;
            print("Detected phone number error: E9999 code");
          } else if (result['returnStatus'] != null && 
                    result['returnStatus']['statusDescription'] != null) {
            String description = result['returnStatus']['statusDescription'].toString().toLowerCase();
            if (description.contains("declined") && description.contains("authorisation")) {
              isPhoneNumberError = true;
              print("Detected phone number error: authorization declined");
            }
          }
          
          if (isPhoneNumberError) {
            print("Processing phone number error");
            
            // O usuário precisa voltar à página anterior para corrigir o número
            // Mas como isso acontece raramente (erro durante verificação do status),
            // redirecionamos para a página de pedido recusado com mensagem específica
            
            // Informar falha no pagamento
            widget.onPaymentResult(false, "Erro no número de telefone MB WAY. Verifique e tente novamente.");
            
            // Navegar para a página de pedido recusado com mensagem específica
            if (mounted) {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDeclinedPage(
                    amount: widget.amount,
                    reason: "Número MB WAY inválido ou inativo. Verifique o número e tente novamente.",
                  ),
                ),
              );
            }
            return;
          }
          
          // Call the callback and let it handle navigation
          widget.onPaymentResult(false, errorMsg);
          
          // Navigate to declined page
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDeclinedPage(
                  amount: widget.amount,
                  reason: errorMsg,
                ),
              ),
            );
          }
        } else {
          // Se 'Pending', mostre mensagem de verificação
          print('Payment still pending. Will check again in 3 seconds.');
        }
      } catch (e) {
        print('Erro ao verificar status: $e');
        // Em caso de erro, continua tentando na próxima iteração
      } finally {
        if (mounted) {
          setState(() {
            _isCheckingStatus = false;
          });
        }
      }
    });
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    print('Disposing MBWayPaymentWaitingPage - cleaning up timers');
    if (_timer.isActive) {
      _timer.cancel();
    }
    if (_statusCheckTimer != null && _statusCheckTimer!.isActive) {
      _statusCheckTimer!.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
        onWillPop: () async {
          // Não permitir voltar para trás de nenhuma forma
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Pagamento MB WAY'),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            automaticallyImplyLeading: false, // This removes the back button
          ),
          body: 
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Valor a ser pago
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Valor total a ser pago:',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                              ),
                            ),
                            Text(
                              ' ${widget.amount.toStringAsFixed(2).replaceAll('.', ',')}€',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.red[800],
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Card principal
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo MB WAY
                          Image.asset(
                            'lib/assets/mbway_logo.png',
                            height: 40,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 50,
                                color: Colors.red,
                                child: Center(
                                  child: Text(
                                    'MB WAY',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Texto de instrução
                          const Text(
                            'É necessário aprovar o pagamento na App MB WAY em até 4 minutos, senão o pagamento será cancelado.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),

                          // Status indicator
                          if (_isCheckingStatus)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'A verificar pagamento... ($_statusCheckCount)',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // Detalhes adicionais
                          Text(
                            'Telefone: ${widget.phoneNumber}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14, color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 20),

                          // Temporizador circular
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.red, width: 3),
                            ),
                            child: Center(
                              child: Text(
                                _formatTime(_secondsRemaining),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  // Botão para cancelar
                 /* Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Cancelar Pagamento'),
                            content: const Text(
                                'Tem certeza que deseja cancelar o pagamento? O seu carrinho de compras será mantido.'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Não'),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => HomeAlunoMain(),
                                    ),
                                  );
                                  widget.onPaymentResult(false,
                                      'Pagamento cancelado pelo utilizador');
                                },
                                child: const Text('Sim'),
                              ),
                            ],
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red[800],
                      ),
                      child: const Text(
                        'Cancelar Pagamento',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),*/

                  // Rodapé
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      '©EPVC, todos os direitos reservados',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      
    );
  }

  // Método para processar pagamento bem-sucedido
  Future<void> _processSuccessfulPayment() async {
    print('Payment successful - creating order');
    
    // Log order data for debugging
    print('Creating order with data: ${widget.orderData}');
    
    // Wait for user info to be loaded
    await _loadUserInfo();
    
    if (users == null) {
      throw Exception('Failed to load user information');
    }
    
    // Criar o pedido na API
    final orderResponse = await http.post(
      Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php'),
      body: {
        'query_param': '5',
        'nome': widget.orderData['nome'],
        'apelido': widget.orderData['apelido'],
        'turma': widget.orderData['turma'],
        'descricao': widget.orderData['descricao'],
        'permissao': widget.orderData['permissao'],
        'total': widget.amount.toString(),
        'valor': widget.amount.toString(),
        'imagem': widget.orderData['imagem'],
        'payment_method': 'mbway',
        'phone_number': widget.phoneNumber,
      },
    );

    print('Order creation response status: ${orderResponse.statusCode}');
    print('Order creation response body: ${orderResponse.body}');

    if (orderResponse.statusCode != 200) {
      throw Exception(
          'Erro na criação do pedido (status ${orderResponse.statusCode}): ${orderResponse.body}');
    }

    final orderResponseData = json.decode(orderResponse.body);
    if (orderResponseData['status'] != 'success') {
      throw Exception(orderResponseData['message'] ??
          'Erro na criação do pedido: ${orderResponse.body}');
    }

    // Extrair orderNumber da resposta
    int orderNumber = int.parse(orderResponseData['orderNumber'].toString());
    
    print('Order created successfully with number: $orderNumber');

    // Enviar pedido para WebSocket e processar recentes
    try {
      if (widget.orderData.containsKey('cartItems') && widget.orderData['cartItems'] != null) {
        List<dynamic> cartItems = json.decode(widget.orderData['cartItems']);
        await _sendOrderToWebSocket(cartItems, orderNumber, widget.amount.toString(), widget.orderData);
        print('Successfully sent order to WebSocket');
        
        // Enviar para a API de pedidos recentes
        try {
          await _sendRecentOrderToApi(cartItems, widget.orderData);
          print('Successfully sent recent order to API');
        } catch (recentApiError) {
          print('Warning: Failed to send recent order to API: $recentApiError');
          // Continue even if recent order API fails
        }
      } else {
        print('No cart items found in order data. Skipping WebSocket notification and recent order API.');
      }
    } catch (socketError) {
      print('Warning: Failed to send order to WebSocket: $socketError');
      // Continue even if WebSocket notification fails
    }

    // Notificar o sistema de pedidos via WebSocket, se necessário
    try {
      await _notifyOrderSystem(orderNumber, widget.transactionId);
    } catch (notifyError) {
      print('Warning: Failed to notify order system: $notifyError');
      // Continue even if notification fails
    }

    // Informar sucesso à página anterior e limpar o carrinho após todo o processamento
    widget.onPaymentResult(true, "Pagamento efetuado com sucesso!");

    // Navegar para a página de confirmação
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationPage(
            orderNumber: orderNumber,
            amount: widget.amount,
          ),
        ),
      );
    }
  }

  Future<void> _notifyOrderSystem(int orderNumber, String transactionId) async {
    // This function can be used to notify other parts of the system about the new order
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php'),
        body: {
          'query_param': 'notify_order',
          'order_number': orderNumber.toString(),
          'transaction_id': transactionId,
          'status': 'new',
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );

      if (response.statusCode == 200) {
        print('Order system notified successfully');
        return;
      }
      
      print('Warning: Order system notification returned status ${response.statusCode}');
    } catch (e) {
      print('Error notifying order system: $e');
      // Don't throw exception, just log the error
    }
  }

  String _getLocalDate() {
    DateTime now = DateTime.now();
    String formattedDateTime = DateFormat('yyyy-MM-dd').format(now);
    return formattedDateTime;
  }

  // Função para calcular o total do carrinho (se necessário)
  double _calculateTotal(List<dynamic> cartItems) {
    double total = 0.0;
    for (var item in cartItems) {
      if (item is Map && item.containsKey('Preco')) {
        double preco = double.parse(item['Preco'].toString());
        total += preco;
      }
    }
    return total;
  }

  Future<void> _loadUserInfo() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var user = prefs.getString("username");

      if (user == null) {
        throw Exception('No user logged in');
      }

      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '1',
          'user': user,
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body);
        });
        print('User info loaded successfully');
      } else {
        throw Exception('Failed to load user info: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading user info: $e');
      throw e;
    }
  }

  void UserInfo() async {
    try {
      await _loadUserInfo();
    } catch (e) {
      print('Error in UserInfo: $e');
    }
  }

  Future<void> _sendRecentOrderToApi(List<dynamic> cartItems, Map<String, dynamic> orderData) async {
    try {
      print('Sending recent orders to API');
      
      for (var item in cartItems) {
        if (item is Map) {
          if (users == null) {
            print('Warning: users data is not loaded yet');
            return;
          }
          
          var localData = _getLocalDate();
          var prencado = item['Prencado'] ?? '0';
          var prepararPrencado = item['PrepararPrencado'] ?? false;
          
          // Convert boolean to string representation for API
          String prepararPrencadoValue = prepararPrencado ? '1' : '0';

          // Send regular POST request
          final response = await http.post(
            Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
            body: {
              'query_param': '6',
              'user': users[0]['Email'],
              'orderDetails': json.encode(item['Nome']),
              'data': localData.toString(),
              'imagem': item['Imagem'], // Use only the product image
              'preco': item['Preco'].toString(),
              'prencado': prencado.toString(),
              'prepararPrencado': prepararPrencadoValue,
            },
          );

          print('Recent order API response code: ${response.statusCode}');
          print('Recent order API response body: ${response.body}');

          if (response.statusCode == 200) {
            print('Pedido recente enviado com sucesso para a API');
          } else {
            print('Erro ao enviar pedido recente para a API: ${response.statusCode} - ${response.body}');
          }
        }
      }
    } catch (e) {
      print('Erro ao enviar pedidos recentes para a API: $e');
      throw e;
    }
  }

  Future<void> _sendOrderToWebSocket(List<dynamic> cartItems, int orderNumber, 
      String total, Map<String, dynamic> orderData) async {
    try {
      // Check if cartItems is not empty
      print('Cart items for WebSocket: $cartItems'); // Debugging
      
      // Debug each cart item's prensado status
      for (var item in cartItems) {
        if (item is Map) {
          print('Item: ${item['Nome']}, Prencado: ${item['Prencado']}, PrepararPrencado: ${item['PrepararPrencado']}');
        }
      }

      // Extract item names with prensado information
      List<String> formattedNames = [];
      for (var item in cartItems) {
        if (item is Map && item.containsKey('Nome')) {
          String name = item['Nome'] as String;
          bool prepararPrencado = item['PrepararPrencado'] ?? false;
          String prencado = item['Prencado'] ?? '0';
          
          if (prepararPrencado && prencado != '0') {
            if (prencado == '1') {
              formattedNames.add('$name - Prensado');
            } else if (prencado == '2') {
              formattedNames.add('$name - Aquecido');
            }
          } else {
            formattedNames.add(name);
          }
        }
      }
      
      print('Formatted names for WebSocket: $formattedNames'); // Debugging

      // Join the formatted names into a comma-separated string
      String descricao = formattedNames.join(', ');

      // Get user data from orderData
      final nome = orderData['nome'] + ' ' + orderData['apelido'];
      final turma = orderData['turma'];
      final permissao = orderData['permissao'];
      final imagem = orderData['imagem'];
      
      // Calculate any change (for MB WAY it's 0)
      final troco = "0.00";

      final channel = WebSocketChannel.connect(
        Uri.parse('ws://websocket.appbar.epvc.pt'),
      );

      // Send all necessary cart data
      Map<String, dynamic> webSocketData = {
        'QPediu': nome,
        'NPedido': orderNumber,
        'Troco': troco,
        'Turma': turma,
        'Permissao': permissao,
        'Estado': 0,
        'Descricao': descricao, // Use formatted description with prensado info
        'Total': total,
        'Imagem': imagem,
        'payment_method': 'mbway',
      };

      print('Sending over WebSocket: ${json.encode(webSocketData)}'); // Debugging

      // Send the order to the server
      channel.sink.add(json.encode(webSocketData));

      // Listen for response but don't wait (async)
      channel.stream.listen(
        (message) {
          try {
            var serverResponse = json.decode(message);
            if (serverResponse['status'] == 'success') {
              print('WebSocket order notification success! Order #$orderNumber');
            } else {
              print('WebSocket error response: $serverResponse');
            }
          } catch (e) {
            print('Error processing WebSocket response: $e');
          } finally {
            channel.sink.close();
          }
        },
        onError: (error) {
          print('WebSocket connection error: $error');
          channel.sink.close();
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Error establishing WebSocket connection: $e');
      throw e; // Re-throw so caller can handle
    }
  }
}
