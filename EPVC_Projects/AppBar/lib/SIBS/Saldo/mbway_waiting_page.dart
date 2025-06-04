import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../sibs_service.dart';
import 'order_declined_page.dart';
import 'order_confirmation_page.dart';

class MBWayWaitingSaldoPage extends StatefulWidget {
  final String transactionId;
  final String transactionSignature;
  final SibsService sibsService;
  final Function(bool success, int orderNumber) onResult;
  final VoidCallback onCancel;
  final double amount;

  const MBWayWaitingSaldoPage({
    Key? key,
    required this.transactionId,
    required this.transactionSignature,
    required this.sibsService,
    required this.onResult,
    required this.onCancel,
    required this.amount,
  }) : super(key: key);

  @override
  _MBWayWaitingSaldoPageState createState() => _MBWayWaitingSaldoPageState();
}

class _MBWayWaitingSaldoPageState extends State<MBWayWaitingSaldoPage> {
  late Timer _timer;
  int _secondsRemaining = 4 * 60; // 4 minutes in seconds
  bool _isCheckingStatus = false;
  Timer? _statusCheckTimer;
  int _statusCheckCount = 0;
  bool _paymentProcessed = false;
  double _transactionAmount = 0.0;

  @override
  void initState() {
    super.initState();
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
          _statusCheckTimer?.cancel();
          widget.onResult(false, 0);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDeclinedSaldoPage(
                  amount: widget.amount,
                  reason: "Tempo Expirado",
                ),
              ),
            );
          }
        }
      });
    });
  }

  void _startStatusCheck() {
    _statusCheckTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_paymentProcessed) {
        timer.cancel();
        return;
      }

      setState(() {
        _isCheckingStatus = true;
        _statusCheckCount++;
      });

      try {
        final result = await widget.sibsService.checkPaymentStatus(
          widget.transactionId,
        );

        if (result['status'] == 'Success') {
          _paymentProcessed = true;
          _timer.cancel();
          _statusCheckTimer?.cancel();

          // Process successful balance loading
          await _processSuccessfulBalanceLoad();

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderConfirmationSaldoPage(
                  amount: widget.amount,
                ),
              ),
            );
          }
        } else if (result['status'] == 'Declined' || 
                   result['status'] == 'Cancelled' || 
                   result['status'] == 'Error') {
          _paymentProcessed = true;
          _timer.cancel();
          _statusCheckTimer?.cancel();

          String errorMsg = "Pagamento recusado";
          if (result['returnStatus'] != null && 
              result['returnStatus'] is Map && 
              result['returnStatus'].isNotEmpty) {
            errorMsg = result['returnStatus']['statusMsg'] ?? errorMsg;
          }

          widget.onResult(false, 0);
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => OrderDeclinedSaldoPage(
                  amount: widget.amount,
                  reason: errorMsg,
                ),
              ),
            );
          }
        }
      } catch (e) {
        print('Error checking payment status: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isCheckingStatus = false;
          });
        }
      }
    });
  }

  Future<void> _processSuccessfulBalanceLoad() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var username = prefs.getString("username");

      if (username == null) {
        throw Exception('No user logged in');
      }

      // Update user balance and record transaction in ab_movimentossaldo
      final updateResponse = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '9',
          'email': username,
          'amount': widget.amount.toString(),
          'transaction_id': widget.transactionId,
          'type': '1',
          'description': 'Carregamento MBWay',
        },
      );

      if (updateResponse.statusCode != 200) {
        throw Exception('Failed to process balance load: ${updateResponse.statusCode}');
      }

      final responseData = json.decode(updateResponse.body);
      if (responseData['success'] != true) {
        throw Exception('API reported failure: ${responseData['error'] ?? 'Unknown error'}');
      }

      widget.onResult(true, 0);
    } catch (e) {
      print('Error processing balance load: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao processar carregamento: ${e.toString()}')),
        );
      }
      throw e;
    }
  }

  String _formatTime(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')} : ${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
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
    return WillPopScope(
      onWillPop: () async {
        // Prevent navigating back
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
        body: Container(
          color: Colors.white,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // Center vertically within the column
              crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally within the column
              children: [
                // Main card
                Container(
                  margin: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // MB WAY Logo
                        Image.asset(
                          'lib/assets/mbway_logo.png',
                          height: 40,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 50,
                              color: Colors.red[900],
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

                        // Instruction text
                        const Text(
                          'É necessário aprovar o carregamento na App MB WAY em até 4 minutos, senão o carregamento será cancelado.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),

  
                  
                        // Timer
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color.fromARGB(255, 206, 26, 26),
                              width: 3,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _formatTime(_secondsRemaining),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              color: const Color.fromARGB(255, 206, 26, 26),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Footer
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
