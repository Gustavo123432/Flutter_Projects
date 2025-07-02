import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:appbar_epvc/Aluno/home.dart';
import 'package:appbar_epvc/Aluno/movimentosPage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Aluno/drawerHome.dart';
import 'package:appbar_epvc/SIBS/Saldo/mbway_phone_page.dart';
import 'package:appbar_epvc/SIBS/sibs_service.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  Map<String, dynamic> userData = {};
  String _balance = "0.00";
  bool _hasUnsavedChanges = false;
  bool _autoBillNIF = false;

    SibsService? _sibsService;


  // Controllers for editable fields
  final TextEditingController _nifController = TextEditingController();
  final TextEditingController _tlfController = TextEditingController();
  final TextEditingController _moradaController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _codigoPostalController = TextEditingController();

  // State for editable fields
  bool _isEditingNif = false;
  bool _isEditingPhone = false;
  bool _isEditingMorada = false;
  bool _isEditingCidade = false;
  bool _isEditingCodigoPostal = false;

  // Original values for comparison
  String _originalNif = '';
  String _originalPhone = '';
  String _originalMorada = '';
  String _originalCidade = '';
  String _originalCodigoPostal = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _initializeSibsService();
  }

  @override
  void dispose() {
    _nifController.dispose();
    _moradaController.dispose();
    _cidadeController.dispose();
    _codigoPostalController.dispose();
    _tlfController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Load user information
      await _fetchUserInfo();

      // Load user balance
      await _fetchUserBalance();

      // Set initial values for the controllers
      _nifController.text = userData['NIF'] ?? '';
      _moradaController.text = userData['Rua'] ?? '';
      _cidadeController.text = userData['Cidade'] ?? '';
      _codigoPostalController.text = userData['CodigoPostal'] ?? '';
      _tlfController.text = userData['Telefone'] ?? '';
      _autoBillNIF = userData['FaturacaoAutomatica'] == '1' ||
          userData['FaturacaoAutomatica'] == 1;

      // Store original values
      _originalNif = _nifController.text;
      _originalPhone = _tlfController.text;
      _originalMorada = _moradaController.text;
      _originalCidade = _cidadeController.text;
      _originalCodigoPostal = _codigoPostalController.text;
    } catch (e) {
      print('Error loading user data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _checkForUnsavedChanges() {
    return _nifController.text != _originalNif ||
        _tlfController.text != _originalPhone ||
        _moradaController.text != _originalMorada ||
        _cidadeController.text != _originalCidade ||
        _codigoPostalController.text != _originalCodigoPostal;
  }

  Future<bool> _onWillPop() async {
    if (_checkForUnsavedChanges()) {
      final shouldPop = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Alterações não guardadas'),
          content: Text(
              'Tem alterações não guardadas. Deseja guardar antes de sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.orange),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeAlunoMain()),
                );
              },
              child: Text('Não guardar', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.orange),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context, true);
                await _saveUserInfo();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => HomeAlunoMain()),
                );
              },
              child: Text('Guardar', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      );

      return shouldPop ?? false;
    }
    return true;
  }

  Future<void> _handleNavigation(BuildContext context, Widget destination) async {
    if (_checkForUnsavedChanges()) {
      final shouldNavigate = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Alterações não guardadas'),
          content: Text(
              'Tem alterações não guardadas. Deseja guardar antes de sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.orange),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => destination),
                );
              },
              child: Text('Não guardar', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.orange),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context, true);
                await _saveUserInfo();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => destination),
                );
              },
              child: Text('Guardar', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(backgroundColor: Colors.orange),
            ),
          ],
        ),
      );

      if (shouldNavigate == true) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => destination),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => destination),
      );
    }
  }

  Future<void> _fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? user = prefs.getString("username");

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
      List<dynamic> userDataList = json.decode(response.body);
      if (userDataList.isNotEmpty) {
        setState(() {
          userData = userDataList[0];
        });
      }
    } else {
      throw Exception('Failed to load user info: ${response.statusCode}');
    }
  }

  Future<void> _fetchUserBalance() async {
    // For now, we're using a placeholder since the actual API endpoint for balance wasn't found
    // When the API endpoint is created, this should be updated

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? user = prefs.getString("username");

    if (user == null) {
      throw Exception('No user logged in');
    }

    // This would be the actual API call once implemented
    // final response = await http.post(
    //   Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
    //   body: {
    //     'query_param': 'user_balance',  // This needs to be the correct query parameter
    //     'user': user,
    //   },
    // );

    setState(() {
      // Parse the saldo value and round to 2 decimal places
      double saldoValue = 0.0;
      try {
        if (userData['Saldo'] != null) {
          saldoValue = double.parse(userData['Saldo'].toString());
        }
      } catch (e) {
        print('Error parsing balance: $e');
      }

      // Format the balance to 2 decimal places
      _balance = saldoValue.toStringAsFixed(2);
    });
  }

  bool _isValid = false;
  String _validationMessage = '';

  bool _validateNIF() {
    final nif = _nifController.text;
    final result = validatePortugueseNIF(nif);

    setState(() {
      _isValid = result.$1;
      _validationMessage = result.$2;
    });

    return result.$1;
  }

  (bool, String) validatePortugueseNIF(String nif) {
    // Remove all non-digit characters
    final cleanedNIF = nif.replaceAll(RegExp(r'[^0-9]'), '');

    // Check length (must be 9 digits)
    if (cleanedNIF.length != 9) {
      return (false, 'O NIF precisa de ter 9 Digitos');
    }

    // Check first digit
    final firstDigit = int.parse(cleanedNIF[0]);
    if (![1, 2, 3, 5, 6, 7, 8, 9].contains(firstDigit)) {
      return (false, 'Primeiro Dígito Inválido');
    }

    // Calculate check digit
    int total = 0;
    for (int i = 0; i < 8; i++) {
      total += int.parse(cleanedNIF[i]) * (9 - i);
    }

    final remainder = total % 11;
    final checkDigit = (remainder == 0 || remainder == 1) ? 0 : 11 - remainder;

    // Verify check digit
    if (int.parse(cleanedNIF[8]) != checkDigit) {
      return (false, 'NIF Inválido');
    }

    return (true, 'NIF Válido');
  }

  Future<void> _saveUserInfo() async {
    setState(() {
      _isSaving = true;
    });

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? user = prefs.getString("username");

      if (user == null) {
        throw Exception('No user logged in');
      }
      
      // Validar NIF apenas se o utilizador o alterou
      bool isNifValid = true;
      if (_nifController.text != _originalNif) {
        isNifValid = _validateNIF();
      }
      
      // Validar telefone apenas se não estiver vazio
      bool isPhoneValid = true;
      String phoneErrorMessage = '';
      if (_tlfController.text.isNotEmpty) {
        if (_tlfController.text.length != 9) {
          isPhoneValid = false;
          phoneErrorMessage = 'O número de telefone deve ter 9 dígitos';
        } else if (!_tlfController.text.startsWith('9') &&
                   !_tlfController.text.startsWith('2') &&
                   !_tlfController.text.startsWith('3')) {
          isPhoneValid = false;
          phoneErrorMessage = 'O número deve começar com 9, 2 ou 3';
        }
      }
      
      if (isNifValid && isPhoneValid) {
        // Debug: Mostrar o que estamos enviando
        print('Saving user info:');
        print('User: $user');
        print('NIF: ${_nifController.text}');
        print('Morada: ${_moradaController.text}');
        print('Cidade: ${_cidadeController.text}');
        print('Código Postal: ${_codigoPostalController.text}');
        print('Telefone: ${_tlfController.text}');
        print('Auto Bill NIF: ${_autoBillNIF ? '1' : '0'}');
        
        // Make API call to update user information
        final Map<String, String> body = {
          'query_param': '1.1',
          'user': user,
          'morada': _moradaController.text,
          'cidade': _cidadeController.text,
          'codigo_postal': _codigoPostalController.text,
          'telefone': _tlfController.text,
          'auto_bill_nif': _autoBillNIF ? '1' : '0',
        };

        if (_nifController.text != _originalNif) {
          // Só envia o NIF se foi alterado (e nunca como '0')
          body['nif'] = _nifController.text.isEmpty || _nifController.text == '0' ? '' : _nifController.text;
        }

        final response = await http.post(
          Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
          body: body,
        );

        print('API Response status: ${response.statusCode}');
        print('API Response body: ${response.body}');

        if (response.statusCode == 200) {
          // Atualizar número de telefone via endpoint específico para garantir
          if (_tlfController.text.isNotEmpty) {
            print('Saving phone number via dedicated endpoint');
            final phoneResponse = await http.get(
              Uri.parse(
                  'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=31&tlf=${_tlfController.text}&id=${userData['IdUser']}'),
            );
            
            print('Phone API Response: ${phoneResponse.statusCode}');
            if (phoneResponse.statusCode == 200) {
              print('Phone number saved successfully using dedicated endpoint');
            } else {
              print('Warning: Failed to save phone using dedicated endpoint');
            }
          }

          // Update local userData
          setState(() {
            userData['NIF'] = _nifController.text;
            userData['Morada'] = _moradaController.text;
            userData['Cidade'] = _cidadeController.text;
            userData['CodigoPostal'] = _codigoPostalController.text;
            userData['Telefone'] = _tlfController.text;
            userData['Rua'] = _moradaController.text; // Campo duplicado no DB

            // Reset all editing states
            _isEditingNif = false;
            _isEditingMorada = false;
            _isEditingCidade = false;
            _isEditingCodigoPostal = false;
            _isEditingPhone = false;

            // Atualizar valores originais e flag de alterações
            _originalNif = _nifController.text;
            _originalPhone = _tlfController.text;
            _originalMorada = _moradaController.text;
            _originalCidade = _cidadeController.text;
            _originalCodigoPostal = _codigoPostalController.text;
            _hasUnsavedChanges = false;
          });

          // Atualizar nas SharedPreferences
          await prefs.setString('phone', _tlfController.text);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Informações atualizadas com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          
          // Recarregar os dados após salvar para confirmar
          await _fetchUserInfo();
        } else {
          throw Exception(
              'Failed to update user info: ${response.statusCode} - ${response.body}');
        }
      } else if (!isPhoneValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(phoneErrorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_validationMessage}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error saving user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar dados: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

    Future<String?> _showUnavaiable() async{
return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Método de Pagamento Indisponivel'),
          content: Text(
              'O método de pagamento encontra-se indisponível de momento, iremos tentar ser os mais breves possiveis.'),
          actions: [
            TextButton(
              onPressed: () { Navigator.of(context).pop(); /*Navigator.of(context).pop();*/},
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
              child: Text('OK'),
            ),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Definições'),
          backgroundColor: Colors.orange,
        ),
        drawer: DrawerHome(
          onNavigation: _handleNavigation,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUserInfoCard(),
                    SizedBox(height: 16),
                    if (userData['AutorizadoSaldo'] == '1' ||
                        userData['AutorizadoSaldo'] == 1)
                      _buildFinancialInfoCard(),
                    if (userData['AutorizadoSaldo'] == '1' ||
                        userData['AutorizadoSaldo'] == 1)
                      SizedBox(height: 16),
                    _buildEditableAddressCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                  Icon(Icons.person, size: 24, color: Color.fromARGB(255, 130, 201, 189)),
                SizedBox(width: 8),
                Text(
                  'Informações Pessoais',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            _buildInfoRow('Nome',
                '${userData['Nome'] ?? 'N/A'} ${userData['Apelido'] ?? ''}'),
            _buildInfoRow('Email', userData['Email'] ?? 'N/A'),
            _buildInfoRow('Turma', userData['Turma'] ?? 'N/A'),
            _buildEditableFieldRow(
                'Telefone',
                _tlfController,
                _isEditingPhone,
                () => setState(() => _isEditingPhone = !_isEditingPhone),
                () => _saveUserInfo()),
            _buildEditableFieldRow(
                'NIF',
                _nifController,
                _isEditingNif,
                () => setState(() => _isEditingNif = !_isEditingNif),
                () => _saveUserInfo()),
              if (_nifController.text.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(left: 0, top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Usar este NIF para Faturação Automática',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Switch(
                        value: _autoBillNIF,
                        onChanged: _handleAutoBillNIFChange,
                        activeColor: Color.fromARGB(255, 246, 141, 45),
                      ),
                      /*Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Text(
                          'Funcionalidade em desenvolvimento',
                          style: TextStyle(color: Colors.red, fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ),*/
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  Future<void> _initializeSibsService() async {
    try {
      _sibsService = SibsService(
        accessToken:
            '0267adfae94c224be1b374be2ce7b298f0.eyJlIjoiMjA1NzkzODk3NTc1MSIsInJvbGVzIjoiTUFOQUdFUiIsInRva2VuQXBwRGF0YSI6IntcIm1jXCI6XCI1MDYzNTBcIixcInRjXCI6XCI4MjE0NFwifSIsImkiOiIxNzQyNDA2MTc1NzUxIiwiaXMiOiJodHRwczovL3FseS5zaXRlMS5zc28uc3lzLnNpYnMucHQvYXV0aC9yZWFsbXMvREVWLlNCTy1JTlQuUE9SVDEiLCJ0eXAiOiJCZWFyZXIiLCJpZCI6IjVXcjN5WkZCSERmNzE4MDgxMGYxYjA0YTg2OTE4OTEwZDBjYzM2ZTRiMSJ9.6a6179e2d76dbe03f41f8252510dcb8a7056d9132a034c26174a6cf5c2ce75b3b5052d85f38fdd8b8765b7dfeb42e2d8aae898dfea1893b217856ef0794ee2f1',
        merchantId: '506350',
        merchantName: 'AppBar',
      );
      print('Serviço SIBS inicializado com sucesso');
    } catch (e) {
      print('Erro ao inicializar serviço SIBS: $e');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao inicializar serviço de pagamento')),
        );
      });
    }
  }

  Widget _buildFinancialInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Color.fromARGB(200, 162, 235, 223),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    size: 24, color: Color.fromARGB(255, 6, 165, 139)),
                SizedBox(width: 8),
                Text(
                  'Saldo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(color: Color.fromARGB(200, 162, 235, 223)),
            SizedBox(height: 16),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Saldo Disponível',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_balance.replaceAll('.', ',')}€',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 6, 165, 139),
                    ),
                  ),
                  SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      SizedBox(
                        width: 160,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Método de Carregamento'),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    ListTile(
                                      leading: Icon(Icons.money, color: Colors.green[800]),
                                      title: Text('Dinheiro'),
                                      onTap: () {
                                        Navigator.pop(context);
                                        showDialog(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Carregar com Dinheiro'),
                                            content: Text(
                                              'Se deseja carregar com dinheiro, dirija-se ao estabelecimento '
                                              'e informe o funcionário que deseja carregar a sua conta com dinheiro.'
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: Text(
                                                  'Fechar',
                                                  style: TextStyle(
                                                    color: Color.fromARGB(255, 246, 141, 45),
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    Divider(),
                                    ListTile(
                                      leading: Icon(Icons.phone_android, color:/* Colors.red[900]*/ Colors.grey),
                                      title: Text('MBWay', style:TextStyle( color:  Colors.grey,)),
                                      onTap: () {
                                        Navigator.pop(context);
                                        if (_sibsService != null) {
                                          _showUnavaiable();

                                          /*Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => MBWayPhoneNumberSaldoPage(
                                                sibsService: _sibsService!,
                                                onResult: (success, orderNumber) {
                                                  // Handle result if needed
                                                },
                                                onCancel: () {
                                                  Navigator.pop(context);
                                                },
                                              ),
                                            ),
                                          );*/
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Serviço de pagamento indisponível. Tente mais tarde.')),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.add_circle_outline),
                          label: Text('Carregar Saldo'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 6, 165, 139),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>  MovimentosPage(),
                              ),
                            );
                          },
                          icon: Icon(Icons.history),
                          label: Text('Ver Movimentos'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color.fromARGB(255, 246, 141, 45),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  

  Widget _buildEditableAddressCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: IntrinsicHeight(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
            mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                  Icon(Icons.home, size: 24, color: Color.fromARGB(255, 130, 201, 189)),
                SizedBox(width: 8),
                Text(
                  'Dados de Faturação',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Divider(),
            SizedBox(height: 8),
            _buildEditableFieldRow(
                'Endereço',
                _moradaController,
                _isEditingMorada,
                () => setState(() => _isEditingMorada = !_isEditingMorada),
                () => _saveUserInfo()),
            _buildEditableFieldRow(
                'Cidade',
                _cidadeController,
                _isEditingCidade,
                () => setState(() => _isEditingCidade = !_isEditingCidade),
                () => _saveUserInfo()),
            _buildEditableFieldRow(
                'Código Postal',
                _codigoPostalController,
                _isEditingCodigoPostal,
                () => setState(
                    () => _isEditingCodigoPostal = !_isEditingCodigoPostal),
                () => _saveUserInfo()),
          ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableFieldRow(
    String label,
    TextEditingController controller,
    bool isEditing,
    VoidCallback onEdit,
    VoidCallback onSave,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: isEditing
                ? TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.orange),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.orange, width: 2),
                      ),
                      hintText: label == 'Telefone' ? '9xxxxxxxx' : null,
                    ),
                    style: TextStyle(
                      fontSize: 14,
                    ),
                    keyboardType: label == 'Telefone'
                        ? TextInputType.phone
                        : TextInputType.text,
                    maxLength: label == 'Telefone' ? 9 : null,
                    buildCounter: label == 'Telefone'
                        ? (context,
                                {required currentLength,
                                required isFocused,
                                maxLength}) =>
                            null
                        : null,
                  )
                : Text(
                    controller.text.isEmpty ? 'N/A' : controller.text,
                    style: TextStyle(
                      fontWeight: FontWeight.w400,
                    ),
                  ),
          ),
          IconButton(
            icon: Icon(
              isEditing ? Icons.save : Icons.edit,
              color: isEditing ? Colors.green : Color.fromARGB(255, 246, 141, 45),
              size: 20,
            ),
            onPressed: isEditing ? onSave : onEdit,
            tooltip: isEditing ? 'Guardar' : 'Editar',
            padding: EdgeInsets.all(4),
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAutoBillNIFChange(bool value) async {
    if (value) {
      // Verificar se o NIF está preenchido
      final nif = _nifController.text.trim();
      if (nif.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preencha o NIF para ativar a faturação automática.')),
        );
        return;
      }
      // Verificar se o utilizador já existe na XD (query_param 2.1)
      final checkResponse = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPIXD_Post.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query_param': 2.1,
          'vat': nif,
        }),
      );
      final checkData = json.decode(checkResponse.body);
      if (checkData['success'] == true && checkData['customer'] != null && checkData['customer']['success'] == true) {
        setState(() {
          _autoBillNIF = true;
        });
        _saveUserInfo();
        return;
      }
      // Se não existe, verificar se todos os campos estão preenchidos
      final name = (userData['Nome'] ?? '').toString().trim();
      final email = (userData['Email'] ?? '').toString().trim();
      final phone = _tlfController.text.trim();
      final address = _moradaController.text.trim();
      final postalCode = _codigoPostalController.text.trim();
      final city = _cidadeController.text.trim();
      final country = 'PT';
      if ([name, nif, address, postalCode, city, country, email, phone].any((v) => v.isEmpty)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Preencha todos os campos de faturação para ativar a faturação automática.')),
        );
        return;
      }
      // Criar utilizador na XD
      final createResponse = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPIXD_Post.php'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query_param': 2,
          'name': name,
          'vat': nif,
          'address': address,
          'postalCode': postalCode,
          'city': city,
          'country': country,
          'email': email,
          'phone': phone,
        }),
      );
      final createData = json.decode(createResponse.body);
      if (createData['success'] == true) {
        setState(() {
          _autoBillNIF = true;
        });
        _saveUserInfo();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faturação automática ativada com sucesso!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao ativar faturação automática: ${createData['message'] ?? 'Erro desconhecido'}')),
        );
      }
    } else {
      setState(() {
        _autoBillNIF = false;
      });
      _saveUserInfo();
    }
  }
}
