import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Aluno/drawerHome.dart';

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

  // Controllers for editable fields
  final TextEditingController _nifController = TextEditingController();
  final TextEditingController _moradaController = TextEditingController();
  final TextEditingController _cidadeController = TextEditingController();
  final TextEditingController _codigoPostalController = TextEditingController();

  // State for editable fields
  bool _isEditingNif = false;
  bool _isEditingMorada = false;
  bool _isEditingCidade = false;
  bool _isEditingCodigoPostal = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nifController.dispose();
    _moradaController.dispose();
    _cidadeController.dispose();
    _codigoPostalController.dispose();
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
    } catch (e) {
      
    } finally {
      setState(() {
        _isLoading = false;
      });
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

  void _validateNIF() {
    final nif = _nifController.text;
    final result = validatePortugueseNIF(nif);

    setState(() {
      _isValid = result.$1;
      _validationMessage = result.$2;
    });
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
      _validateNIF();
      if (_isValid) {
        // Make API call to update user information
        final response = await http.post(
          Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
          body: {
            'query_param':
                '1.1', // This should be the correct query parameter for updating user info
            'user': user,
            'nif': _nifController.text,
            'morada': _moradaController.text,
            'cidade': _cidadeController.text,
            'codigo_postal': _codigoPostalController.text,
          },
        );

        if (response.statusCode == 200) {
          // Update local userData
          setState(() {
            userData['NIF'] = _nifController.text;
            userData['Morada'] = _moradaController.text;
            userData['Cidade'] = _cidadeController.text;
            userData['CodigoPostal'] = _codigoPostalController.text;

            // Reset all editing states
            _isEditingNif = false;
            _isEditingMorada = false;
            _isEditingCidade = false;
            _isEditingCodigoPostal = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Informações atualizadas com sucesso!')),
          );
        } else {
          throw Exception('Failed to update user info: ${response.statusCode}');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_validationMessage}')),
        );
      }
    } catch (e) {
      print('Error saving user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar dados: $e')),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Definições'),
      ),
      drawer: DrawerHome(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildUserInfoCard(),
                  SizedBox(height: 16),
                  if (userData['AutorizadoSaldo'] == '1' || userData['AutorizadoSaldo'] == 1)
                    _buildFinancialInfoCard(),
                  if (userData['AutorizadoSaldo'] == '1' || userData['AutorizadoSaldo'] == 1)
                    SizedBox(height: 16),
                  _buildEditableAddressCard(),
                ],
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, size: 24, color: Colors.blueGrey),
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
                'NIF',
                _nifController,
                _isEditingNif,
                () => setState(() => _isEditingNif = !_isEditingNif),
                () => _saveUserInfo()),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      color: Colors.green[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.account_balance_wallet,
                    size: 24, color: Colors.green[700]),
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
            Divider(color: Colors.green[200]),
            SizedBox(height: 16),
            Center(
              child: Column(
                children: [
                  Text(
                    'Saldo Disponível',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${_balance.replaceAll('.', ',')}€',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
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
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, size: 24, color: Colors.blueGrey),
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
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 14,
                    ),
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
              color: isEditing ? Colors.green : Colors.blue,
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
}
