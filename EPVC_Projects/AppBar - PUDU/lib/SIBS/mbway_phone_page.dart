import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'sibs_service.dart';
import 'mbway_waiting_page.dart';
import 'order_confirmation_page.dart';

class MBWayPhoneNumberPage extends StatefulWidget {
  final double amount;
  final Function(bool success, int orderNumber) onResult;
  final VoidCallback onCancel;
  final Map<String, dynamic> orderData; // Dados do pedido
  final SibsService sibsService;

  const MBWayPhoneNumberPage({
    Key? key,
    required this.amount,
    required this.onResult,
    required this.onCancel,
    required this.orderData,
    required this.sibsService,
  }) : super(key: key);

  @override
  _MBWayPhoneNumberPageState createState() => _MBWayPhoneNumberPageState();
}

class _MBWayPhoneNumberPageState extends State<MBWayPhoneNumberPage> {
  final TextEditingController _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValidPhone = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _validatePhone() {
    setState(() {
      final phoneText = _phoneController.text.trim();
      _isValidPhone = phoneText.length == 9 &&
          (phoneText.startsWith('9') ||
              phoneText.startsWith('2') ||
              phoneText.startsWith('3'));
    });
  }

  Future<void> _processMBWayPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isProcessing = true;
    });

    final String phoneNumber = _phoneController.text.trim();

    try {
      // 1. Iniciar o pagamento para obter credenciais da transação (sem criar o pedido ainda)
      final paymentInitResponse = await widget.sibsService.initiateMBWayPayment(
        amount: widget.amount,
        orderNumber: "temp_" +
            DateTime.now().millisecondsSinceEpoch.toString(), // ID temporário
        phoneNumber: phoneNumber,
      );

      // Debug print
      print('Initiate Payment Response: $paymentInitResponse');

      // 2. Extrair o ID da transação e assinatura
      if (!paymentInitResponse.containsKey('transactionID') ||
          !paymentInitResponse.containsKey('transactionSignature')) {
        throw Exception(
            'Credenciais de transação ausentes na resposta: $paymentInitResponse');
      }

      final transactionId = paymentInitResponse['transactionID'].toString();
      final transactionSignature =
          paymentInitResponse['transactionSignature'].toString();

      // 3. Criar o pagamento MBWay com essas credenciais
      final createResponse = await widget.sibsService.createMBWayPayment(
        transactionId: transactionId,
        transactionSignature: transactionSignature,
        phoneNumber: phoneNumber,
      );

      // Debug print
      print('Create Payment Response: $createResponse');

      // 4. Verificar resposta da criação do pagamento
      if (!createResponse.containsKey('transactionID') &&
          createResponse['statusCode'] != "000") {
        throw Exception('Resposta de pagamento inválida: $createResponse');
      }

      // 5. Navegar para a página de espera do MB WAY
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MBWayPaymentWaitingPage(
            amount: widget.amount,
            transactionId: transactionId,
            phoneNumber: phoneNumber,
            accessToken: widget.sibsService.accessToken,
            merchantId: widget.sibsService.merchantId,
            merchantName: widget.sibsService.merchantName,
            onPaymentResult: (success, message) async {
              if (success) {
                // Se o pagamento for bem-sucedido, AGORA criar o pedido na API
                final orderResponse = await http.post(
                  Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php'),
                  body: {
                    'query_param': '5',
                    'nome': widget.orderData['nome'],
                    'apelido': widget.orderData['apelido'],
                    'orderNumber': '0',
                    'turma': widget.orderData['turma'],
                    'descricao': widget.orderData['descricao'],
                    'permissao': widget.orderData['permissao'],
                    'total': widget.amount.toString(),
                    'valor': widget.amount.toString(),
                    'imagem': widget.orderData['imagem'],
                    'cartItems': widget.orderData['cartItems'],
                    'payment_method': 'mbway',
                    'phone_number': phoneNumber,
                    'transaction_id':
                        transactionId, // Incluir ID da transação para rastreamento
                    'payment_status': 'paid', // Já marcar como pago
                  },
                );

                if (orderResponse.statusCode != 200) {
                  throw Exception(
                      'Erro na criação do pedido (status ${orderResponse.statusCode})');
                }

                final orderResponseData = json.decode(orderResponse.body);
                if (orderResponseData['status'] != 'success') {
                  throw Exception(orderResponseData['message'] ??
                      'Erro na criação do pedido');
                }

                int orderNumber =
                    int.parse(orderResponseData['orderNumber'].toString());

                // Agora que temos o número do pedido e a confirmação do pagamento,
                // enviar os detalhes dos produtos para a API
                await sendOrderItemsToAPI(
                    orderNumber, widget.orderData['cartItems'], transactionId);

                // Retornar sucesso para a página que chamou
                widget.onResult(true, orderNumber);

                // Navegar para a página de confirmação de pedido
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
              } else {
                // Retornar falha - nenhum pedido foi criado
                widget.onResult(false, 0);

                // Mostrar mensagem de erro
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(message),
                      backgroundColor: Colors.red,
                    ),
                  );

                  Navigator.pop(
                      context); // Fechar a página de espera e voltar para o telefone
                }
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('Erro ao processar pagamento MBWay: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Erro ao processar pagamento: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}'),
            duration: Duration(seconds: 5),
            backgroundColor: Colors.red,
          ),
        );

        setState(() {
          _isProcessing = false;
        });
      }

      widget.onResult(false, 0);
    }
  }

  Future<void> _updateOrderStatusInAPI(String orderId, String status) async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php'),
        body: {
          'query_param': 'update_order_status',
          'order_id': orderId,
          'status': status,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao atualizar status do pedido na API');
      }

      print('Status do pedido atualizado com sucesso: $status');
    } catch (e) {
      print('Erro ao atualizar status do pedido: $e');
    }
  }

  Future<void> sendOrderItemsToAPI(
      int orderId, String cartItemsJson, String transactionId) async {
    try {
      // Decodificar o JSON dos itens do carrinho
      List<dynamic> cartItems = json.decode(cartItemsJson);

      // Enviar cada item para a API individualmente ou em lote
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php'),
        body: {
          'query_param': 'add_order_items',
          'order_id': orderId.toString(),
          'items': cartItemsJson, // Enviando todos os itens de uma vez
          'transaction_id': transactionId,
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Falha ao enviar itens do pedido para a API');
      }

      print('Itens do pedido enviados com sucesso');
    } catch (e) {
      print('Erro ao enviar itens do pedido: $e');
      // Não lança a exceção para não interromper o fluxo após o pagamento ser confirmado
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
        onWillPop: () async {
          if (!_isProcessing) {
            widget.onCancel();
          }
          return false; // Não permita o pop nativo, deixe a callback lidar com isso
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text('Pagamento MB WAY'),
            automaticallyImplyLeading: false, // This removes the back button
          ),
          body: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Logo MB WAY
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30.0),
                      child: Image.asset(
                        'lib/assets/mbway_logo.png',
                        height: 100,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 100,
                            color: Colors.red[800],
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
                    ),

                    // Valor do pagamento
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Valor a pagar:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${widget.amount.toStringAsFixed(2).replaceAll('.', ',')}€',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[800],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 40),

                    // Campo de telefone
                    Text(
                      'Digite o número de telefone MB WAY',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey[300]!,
                          width: 1.0,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Prefixo +351
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(12),
                                bottomLeft: Radius.circular(12),
                              ),
                            ),
                            child: Text(
                              '+351',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          // Campo de entrada
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.number,
                              maxLength: 9,
                              enabled: !_isProcessing,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: '9XXXXXXXX',
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 16),
                                counterText: '',
                              ),
                              validator: (value) {
                                if (value == null || value.length != 9) {
                                  return 'Digite um número válido com 9 dígitos';
                                }
                                if (!value.startsWith('9') &&
                                    !value.startsWith('2') &&
                                    !value.startsWith('3')) {
                                  return 'Número inválido. Deve começar com 9, 2 ou 3';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),
                    Text(
                      'O número deve ter 9 dígitos e começar com 9, 2 ou 3',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    SizedBox(height: 40),

                    // Botão de continuar
                    _isProcessing
                        ? CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.red),
                          )
                        : ElevatedButton(
                            onPressed:
                                _isValidPhone ? _processMBWayPayment : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[800],
                              padding: EdgeInsets.symmetric(vertical: 15),
                              minimumSize: Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Continuar',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),

                    SizedBox(height: 15),

                    // Botão de cancelar
                    _isProcessing
                        ? SizedBox.shrink()
                        : TextButton(
                            onPressed: widget.onCancel,
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
