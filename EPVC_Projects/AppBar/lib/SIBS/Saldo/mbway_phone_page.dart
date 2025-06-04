import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../sibs_service.dart';
import 'mbway_waiting_page.dart';
import 'order_confirmation_page.dart';
import 'order_declined_page.dart';
import 'package:appbar_epvc/Aluno/home.dart';

class MBWayPhoneNumberSaldoPage extends StatefulWidget {
  final Function(bool success, int orderNumber) onResult;
  final VoidCallback onCancel;
  final SibsService sibsService;

  const MBWayPhoneNumberSaldoPage({
    Key? key,
    required this.onResult,
    required this.onCancel,
    required this.sibsService,
  }) : super(key: key);

  @override
  _MBWayPhoneNumberSaldoPageState createState() => _MBWayPhoneNumberSaldoPageState();
}

class _MBWayPhoneNumberSaldoPageState extends State<MBWayPhoneNumberSaldoPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customAmountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isValidPhone = false;
  bool _isProcessing = false;
  List<dynamic> users = [];
  double _selectedAmount = 5.0; // Default amount
  bool _isCustomAmount = false;

  final List<double> _availableAmounts = [2.0, 5.0, 10.0, 20.0];

  @override
  void initState() {
    super.initState();
    print('MBWayPhoneNumberPage initialized');
    _initializeData();
  }

  Future<void> _initializeData() async {
    print('Initializing data...');
    await fetchUser();
    _phoneController.addListener(_validatePhone);
  }

  Future<void> fetchUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var idUser = prefs.getString("username");
      print('Retrieved user ID from SharedPreferences: $idUser');

      if (idUser == null || idUser.isEmpty) {
        print('Error: No user ID found in SharedPreferences');
        return;
      }

      print('Fetching user data from API...');
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '1',
          'user': idUser,
        },
      );

      print('API Response status: ${response.statusCode}');
      print('API Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Decoded response data: $responseData');
        
        if (responseData is List && responseData.isNotEmpty) {
          print('User data found in response');
          
          if (mounted) {
          setState(() {
            users = responseData;
              
              // Verifica se há número de telefone no banco
              if (responseData[0]['Telefone'] != null && responseData[0]['Telefone'].toString().isNotEmpty) {
                print(responseData);
                String phoneNumber = responseData[0]['Telefone'].toString();
                print('Setting phone from database: $phoneNumber');
                _phoneController.text = phoneNumber;
                _validatePhone();
            } 
              // Se não houver no banco, verifica nas preferências
            else {
              String? savedPhone = prefs.getString('phone');
              if (savedPhone != null && savedPhone.isNotEmpty) {
                  print('Setting phone from preferences: $savedPhone');
                  _phoneController.text = savedPhone;
              _validatePhone();
                }
            }
          });
          }
        } else {
          print('No user data found in response');
        }
      } else {
        print('API request failed with status: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('Error fetching user data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _validatePhone() {
      final phoneText = _phoneController.text.trim();
    print('Validating phone: $phoneText');
      bool isProperLength = phoneText.length == 9;
      bool hasCorrectPrefix = phoneText.startsWith('9') || 
                              phoneText.startsWith('2') || 
                              phoneText.startsWith('3');
      
    bool isValid = isProperLength && hasCorrectPrefix;
    print('Phone validation result: $isValid');
    
    if (mounted) {
      setState(() {
        _isValidPhone = isValid;
    });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _processMBWayPayment() async {
    if (!_formKey.currentState!.validate()) return;

    if (users.isEmpty) {
      await fetchUser();
      
      if (users.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao carregar dados do usuário. Tente novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isProcessing = true;
    });

    final String phoneNumber = _phoneController.text.trim();

    try {
      final paymentInitResponse = await widget.sibsService.initiateMBWayPayment(
        amount: _selectedAmount,
        orderNumber: "EPVC",
        phoneNumber: phoneNumber,
      );

      if (!paymentInitResponse.containsKey('transactionID') ||
          !paymentInitResponse.containsKey('transactionSignature')) {
        throw Exception('Credenciais de transação ausentes na resposta');
      }

      final transactionId = paymentInitResponse['transactionID'].toString();
      final transactionSignature = paymentInitResponse['transactionSignature'].toString();

      final createResponse = await widget.sibsService.createMBWayPayment(
        transactionId: transactionId,
        transactionSignature: transactionSignature,
        phoneNumber: phoneNumber,
      );

      if (createResponse.containsKey('returnStatus')) {
        final returnStatus = createResponse['returnStatus'];
        if (returnStatus != null && returnStatus is Map) {
          final statusCode = returnStatus['statusCode'];
          final statusDescription = returnStatus['statusDescription'];

          if (statusCode == 'E0506' || 
              (statusDescription != null && statusDescription.toString().toLowerCase().contains('alias does not exists'))) {
            if (mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Erro de Carregamento'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 48,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Número MB WAY não registado ou inativo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }
            if (mounted) {
              setState(() {
                _isProcessing = false;
              });
            }
            return;
          }
        }
      }

      print('Registering transaction with webhook for status monitoring');
      try {
        final webhookResponse = await widget.sibsService.SendToWebhook(
          transactionId: transactionId,
          transactionSignature: transactionSignature,
        );

        if (webhookResponse['status'] == 'success') {
          print('Transaction successfully registered with webhook');
        } else {
          print('Warning: Webhook registration returned non-success: ${webhookResponse['message']}');
        }
      } catch (e) {
        print('Warning: Error during webhook registration: $e');
      }

      if (!createResponse.containsKey('transactionID') &&
          createResponse['statusCode'] != "000") {
        throw Exception('Resposta de pagamento inválida: $createResponse');
      }

      if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => MBWayWaitingSaldoPage(
            transactionId: transactionId,
              transactionSignature: transactionSignature,
              sibsService: widget.sibsService,
              onResult: widget.onResult,
              onCancel: widget.onCancel,
              amount: _selectedAmount,
          ),
        ),
      );
      }
    } catch (e) {
      print('Error processing MBWay payment: $e');
      if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text(e.toString()),
              backgroundColor: Colors.red,
            ),
          );
        }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
        title: Text('Pagamento MB WAY', style: TextStyle(color: Colors.black),),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
          ),
          body: SingleChildScrollView(
        padding: EdgeInsets.all(25),
              child: Form(
                key: _formKey,
                child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              // MB WAY Logo
              Image.asset(
                        'lib/assets/mbway_logo.png',
                height: 60,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                    height: 60,
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
              const SizedBox(height: 16),

              // Instruction text
              const Text(
                'Selecione o valor a carregar e insira o seu número de telefone MB WAY.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),

              // Valor a pagar section
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                      'Valor a carregar:',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                            ),
                          ),
                          Text(
                      '${_selectedAmount.toStringAsFixed(2)}€',
                            style: TextStyle(
                        fontSize: 18,
                              fontWeight: FontWeight.bold,
                        color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 24),

                    Text(
                'Selecione o valor a carregar:',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                ),
              ),
              SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ..._availableAmounts.map((amount) {
                    final isSelected = _selectedAmount == amount && !_isCustomAmount;
                    return ChoiceChip(
                      label: Text(
                        '${amount.toStringAsFixed(2)}€',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.grey[800],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedAmount = amount;
                            _isCustomAmount = false;
                            _customAmountController.clear();
                          });
                        }
                      },
                      backgroundColor: Colors.grey[200],
                      selectedColor: Colors.red[900],
                    );
                  }),
                  ChoiceChip(
                    label: Text(
                      'Outro',
                      style: TextStyle(
                        color: _isCustomAmount ? Colors.white : Colors.grey[800],
                        fontWeight: _isCustomAmount ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: _isCustomAmount,
                    onSelected: (selected) {
                      setState(() {
                        _isCustomAmount = true;
                        _selectedAmount = 0.0;
                      });
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.red[900],
                  ),
                ],
              ),
              if (_isCustomAmount) ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _customAmountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: '0.00',
                    suffixText: '€',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                  ],
                  onChanged: (value) {
                    if (value.isNotEmpty) {
                      setState(() {
                        _selectedAmount = double.tryParse(value) ?? 0.0;
                      });
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira um valor';
                    }
                    double? amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Por favor, insira um valor válido';
                    }
                    return null;
                  },
                              ),
              ],
              SizedBox(height: 24),
              Text(
                'Introduza o seu número de telemóvel:',
                              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                              ),
                            ),
              SizedBox(height: 8),
              TextFormField(
                              controller: _phoneController,
                keyboardType: TextInputType.phone,
                              maxLength: 9,
                decoration: InputDecoration(
                  hintText: '9xxxxxxxx',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixText: '+351 ',
                  prefixStyle: TextStyle(fontSize: 16, color: Colors.black),
                  prefixIcon: Icon(Icons.phone),
                ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, introduza o seu número de telemóvel';
                  }
                  if (value.length != 9) {
                    return 'O número deve ter 9 dígitos';
                                }
                  if (!value.startsWith('9') && !value.startsWith('2') && !value.startsWith('3')) {
                    return 'O número deve começar com 9, 2 ou 3';
                                }
                                return null;
                              },
                            ),
              SizedBox(height: 24),
                    Text(
                      'O número deve ter 9 dígitos e começar com 9, 2 ou 3',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isValidPhone && !_isProcessing && (!_isCustomAmount || _selectedAmount > 0) ? _processMBWayPayment : null,
                            style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[900],
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                child: _isProcessing
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                              'Continuar',
                        style: TextStyle(fontSize: 16),
                            ),
                          ),
              SizedBox(height: 16),
              TextButton(
                onPressed: _isProcessing ? null : () => Navigator.pop(context),
                            child: Text(
                              'Cancelar',
                              style: TextStyle(
                                fontSize: 16,
                    color: Colors.red[900],
                              ),
                            ),
                          ),
                  ],
          ),
        ),
      ),
    );
  }
}
