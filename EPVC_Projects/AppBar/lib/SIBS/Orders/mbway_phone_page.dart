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
  List<dynamic> users = [];

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
      
      // Debug: Listar todas as chaves no SharedPreferences
      print('All SharedPreferences keys: ${prefs.getKeys()}');
      
      var idUser = prefs.getString("idUser");
      print('Retrieved user ID from SharedPreferences: $idUser');

      if (idUser == null || idUser.isEmpty) {
        print('Error: No user ID found in SharedPreferences');
        return;
      }

      print('Making API request with user ID: $idUser');
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '1',
          'user': idUser,
        },
      );

      print('Fetch user response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        print('Parsed response data: $responseData');
        
        if (responseData is List && responseData.isNotEmpty) {
          setState(() {
            users = responseData;
            print('Users data set: $users');
            
            // Tentar obter o telefone da seguinte ordem:
            // 1. Do banco de dados (API)
            // 2. Das SharedPreferences
            // 3. Deixar vazio para o usuário digitar
            String phoneNumber = '';
            
            // 1. Tentar do banco de dados
            if (users[0]['Telefone'] != null && users[0]['Telefone'] != '') {
              phoneNumber = users[0]['Telefone'];
              print('Phone number from DB: $phoneNumber');
            } 
            // 2. Tentar das SharedPreferences
            else {
              String? savedPhone = prefs.getString('phone');
              if (savedPhone != null && savedPhone.isNotEmpty) {
                phoneNumber = savedPhone;
                print('Phone number from SharedPreferences: $phoneNumber');
              } else {
                print('No phone number found in DB or SharedPreferences');
              }
            }
            
            // Definir o número no controlador se foi encontrado
            if (phoneNumber.isNotEmpty) {
              _phoneController.text = phoneNumber;
              _validatePhone();
            }
          });
        } else {
          print('Error: Response data is not a list or is empty: $responseData');
        }
      } else {
        print('Error: API request failed with status ${response.statusCode}');
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
      
      print('Phone validation: Length OK? $isProperLength, Prefix OK? $hasCorrectPrefix, Valid? $_isValidPhone');
    });
  }

  Future<void> _processMBWayPayment() async {
    if (!_formKey.currentState!.validate()) return;

    // Verificar se temos os dados do usuário
    if (users.isEmpty) {
      print('Trying to fetch user data before proceeding...');
      await fetchUser();
      
      if (users.isEmpty) {
        setState(() {
          _isProcessing = false;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Erro ao carregar dados do usuário. Tente novamente.'),
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
      // Se o usuário não tinha telefone na base de dados ou é diferente, salva
      if (users[0]['Telefone'] == null || users[0]['Telefone'] == '' || users[0]['Telefone'] != phoneNumber) {
        print('Saving phone number to database: $phoneNumber');
        
        // Salvar no banco de dados
        final savePhoneResponse = await http.get(
          Uri.parse(
              'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=31&tlf=$phoneNumber&id=${users[0]['IdUser']}'),
        );

        print('Save phone response: ${savePhoneResponse.statusCode}');
        if (savePhoneResponse.statusCode == 200) {
          print('Phone number saved successfully to database');
          
          // Atualizar dados locais
          users[0]['Telefone'] = phoneNumber;
          
          // Salvar também no SharedPreferences para uso em outras telas
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('phone', phoneNumber);
          print('Phone number saved to SharedPreferences');
        } else {
          print('Warning: Failed to save phone number to database');
        }
      }

      // 1. Iniciar o pagamento para obter credenciais da transação
      final paymentInitResponse = await widget.sibsService.initiateMBWayPayment(
        amount: widget.amount,
        orderNumber: "EPVC",
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

      // Verificar se há erro na resposta do createMBWayPayment
      if (createResponse.containsKey('returnStatus')) {
        final returnStatus = createResponse['returnStatus'];
        if (returnStatus != null && returnStatus is Map) {
          final statusCode = returnStatus['statusCode'];
          final statusMsg = returnStatus['statusMsg'];
          final statusDescription = returnStatus['statusDescription'];

          if (statusCode == 'E0506' || 
              (statusDescription != null && statusDescription.toString().toLowerCase().contains('alias does not exists'))) {
            throw Exception('Número MB WAY não registado ou inativo');
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

      // 6. Navegar para a página de espera do MB WAY
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
            orderData: widget.orderData,
            onPaymentResult: (success, message) async {
              if (success) {
                // O processamento do pedido agora é feito na página de espera
                // Apenas informamos o resultado ao chamador
                widget.onResult(true,
                    0); // O número do pedido já é exibido na página de confirmação
              } else {
                // Retornar falha - nenhum pedido foi criado
                print('Payment declined - returning to home screen');
                widget.onResult(false, 0);

                // Navegar para a página de pedido recusado já é feito na página de espera
              }
            },
          ),
        ),
      );
    } catch (e) {
      print('Erro ao processar pagamento MBWay: $e');

      setState(() {
        _isProcessing = false;
      });

      if (mounted) {
        String errorMessage = e.toString().toLowerCase();
        
        // Não tratar "Success" como erro
        if (errorMessage.contains('success')) {
          return;
        }

        bool isPhoneNumberError = 
            errorMessage.contains('número mb way não registado') ||
            errorMessage.contains('alias does not exists') ||
            errorMessage.contains('número inválido') ||
            errorMessage.contains('e0506') ||
            errorMessage.contains('400') ||
            errorMessage.contains('e9999') ||
            errorMessage.contains('failed to create mbway payment') ||
            (errorMessage.contains('error') && errorMessage.contains('400'));

        if (isPhoneNumberError) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return AlertDialog(
                title: Text('Número MB WAY Inválido'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('O número de telefone fornecido não está registado no MB WAY ou está inativo.'),
                    SizedBox(height: 12),
                    Text('Para utilizar o MB WAY, certifique-se que:'),
                    SizedBox(height: 8),
                    Text('• O número está correto'),
                    Text('• Tem a app MB WAY instalada'),
                    Text('• A conta MB WAY está ativa'),
                    Text('• O número está registado no MB WAY'),
                    SizedBox(height: 12),
                    Text('Por favor, verifique e tente novamente.',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: <Widget>[
                  TextButton(
                    child: Text('OK'),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                  ),
                ],
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao processar pagamento: ${e.toString().replaceAll(RegExp(r'^Exception: '), '')}'),
              duration: Duration(seconds: 5),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
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
                        height: 50,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 50,
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
