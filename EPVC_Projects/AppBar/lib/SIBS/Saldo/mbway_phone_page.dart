import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../sibs_service.dart';
import 'mbway_waiting_page.dart';
import 'order_confirmation_page.dart';
import 'order_declined_page.dart';
import 'package:my_flutter_project/Aluno/home.dart';

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
  final _formKey = GlobalKey<FormState>();
  bool _isValidPhone = false;
  bool _isProcessing = false;
  List<dynamic> users = [];
  double _selectedAmount = 5.0; // Default amount

  final List<double> _availableAmounts = [2.0, 5.0, 10.0, 20.0];

  @override
  void initState() {
    super.initState();
    print('MBWayPhoneNumberPage initialized');
    fetchUser();
    _phoneController.addListener(_validatePhone);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> fetchUser() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      var idUser = prefs.getString("idUser");
      print('Retrieved user ID from SharedPreferences: $idUser');

      if (idUser == null || idUser.isEmpty) {
        print('Error: No user ID found in SharedPreferences');
        return;
      }

      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '1',
          'user': idUser,
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        if (responseData is List && responseData.isNotEmpty) {
          setState(() {
            users = responseData;
            
            String phoneNumber = '';
            
            if (users[0]['Telefone'] != null && users[0]['Telefone'] != '') {
              phoneNumber = users[0]['Telefone'];
            } else {
              String? savedPhone = prefs.getString('phone');
              if (savedPhone != null && savedPhone.isNotEmpty) {
                phoneNumber = savedPhone;
              }
            }
            
            if (phoneNumber.isNotEmpty) {
              _phoneController.text = phoneNumber;
              _validatePhone();
            }
          });
        }
      }
    } catch (e, stackTrace) {
      print('Error fetching user data: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _validatePhone() {
    setState(() {
      final phoneText = _phoneController.text.trim();
      bool isProperLength = phoneText.length == 9;
      bool hasCorrectPrefix = phoneText.startsWith('9') || 
                              phoneText.startsWith('2') || 
                              phoneText.startsWith('3');
      
      _isValidPhone = isProperLength && hasCorrectPrefix;
    });
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
      if (users[0]['Telefone'] == null || users[0]['Telefone'] == '' || users[0]['Telefone'] != phoneNumber) {
        final savePhoneResponse = await http.get(
          Uri.parse(
              'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=31&tlf=$phoneNumber&id=${users[0]['IdUser']}'),
        );

        if (savePhoneResponse.statusCode == 200) {
          users[0]['Telefone'] = phoneNumber;
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('phone', phoneNumber);
        }
      }

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
            // Show dialog for invalid MBWay number
            if (mounted) {
              showDialog( // Use showDialog from flutter/material
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Erro de Carregamento'),
                  content: Text('Número MB WAY não registado ou inativo.'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('OK'),
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
            return; // Exit the function after showing dialog
          }
        }
      }

      // 4. Enviar para o webhook para processamento de status
      print('Registering transaction with webhook for status monitoring');
      try {
        final webhookResponse = await widget.sibsService.SendToWebhook(
          transactionId: transactionId,
          transactionSignature: transactionSignature,
        );

        if (webhookResponse['status'] == 'success') {
          print('Transaction successfully registered with webhook');
        } else {
          print(
              'Warning: Webhook registration returned non-success: ${webhookResponse['message']}');
          // Continue even if webhook registration fails
        }
      } catch (e) {
        print('Warning: Error during webhook registration: $e');
        // Continue the process even if webhook registration fails
      }

      // 5. Verificar resposta da criação do pagamento
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
            content: Text(e.toString()), // Show the general error message for other exceptions
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
                children: _availableAmounts.map((amount) {
                  final isSelected = _selectedAmount == amount;
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
                        });
                      }
                    },
                    backgroundColor: Colors.grey[200],
                    selectedColor: Colors.red[900],
                  );
                }).toList(),
              ),
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
                onPressed: _isValidPhone && !_isProcessing ? _processMBWayPayment : null,
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
