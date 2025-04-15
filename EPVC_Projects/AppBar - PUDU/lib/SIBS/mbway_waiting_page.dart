import 'dart:async';
import 'package:flutter/material.dart';
import 'package:my_flutter_project/Aluno/home.dart';
import 'sibs_service.dart';

class MBWayPaymentWaitingPage extends StatefulWidget {
  final double amount;
  final String transactionId;
  final String phoneNumber;
  final String accessToken;
  final String merchantId;
  final String merchantName;
  final Function(bool success, String message) onPaymentResult;

  const MBWayPaymentWaitingPage({
    Key? key,
    required this.amount,
    required this.transactionId,
    required this.phoneNumber,
    required this.accessToken,
    required this.merchantId,
    required this.merchantName,
    required this.onPaymentResult,
  }) : super(key: key);

  @override
  _MBWayPaymentWaitingPageState createState() =>
      _MBWayPaymentWaitingPageState();
}

class _MBWayPaymentWaitingPageState extends State<MBWayPaymentWaitingPage> {
  late Timer _timer;
  int _secondsRemaining = 5 * 60; // 5 minutos em segundos
  bool _isCheckingStatus = false;
  Timer? _statusCheckTimer;
  late SibsService _sibsService;

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
        }
      });
    });
  }

  void _startStatusCheck() {
    // Verificar o status do pagamento a cada 5 segundos
    _statusCheckTimer =
        Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (_isCheckingStatus) return;

      setState(() {
        _isCheckingStatus = true;
      });

      try {
        // Verificar o status do pagamento usando o serviço SIBS
        final result =
            await _sibsService.checkPaymentStatus(widget.transactionId);

        if (result['status'] == 'Success') {
          _timer.cancel();
          _statusCheckTimer?.cancel();
          widget.onPaymentResult(true, "Pagamento efetuado com sucesso!");
        } else if (result['status'] == 'Declined') {
          _timer.cancel();
          _statusCheckTimer?.cancel();
          String errorMsg =
              result['returnStatus']?['statusMsg'] ?? 'Motivo desconhecido';
          widget.onPaymentResult(false, "Pagamento recusado");
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ShoppingCartPage(),
            ),
          );
        }
        // Se 'Pending', continua aguardando
      } catch (e) {
        print('Erro ao verificar status: $e');
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
    _timer.cancel();
    _statusCheckTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WillPopScope(
        onWillPop: () async {
          // Mostrar diálogo de confirmação
          final shouldPop = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancelar Pagamento'),
              content: const Text(
                  'Tem certeza que deseja cancelar o pagamento? O seu carrinho de compras será mantido.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Não'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ShoppingCartPage(),
                      ),
                    );
                    widget.onPaymentResult(
                        false, 'Pagamento cancelado pelo utilizador');
                  },
                  child: const Text('Sim'),
                ),
              ],
            ),
          );
          return shouldPop ?? false;
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
                            height: 50,
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
                            'É necessário aprovar o pagamento na App MB WAY em até 5 minutos, senão o pagamento será cancelado.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 20),

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
                  Container(
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
                                      builder: (context) => ShoppingCartPage(),
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
                  ),

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
}
