import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appbar_epvc/Bar/drawerBar.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:appbar_epvc/widgets/loading_overlay.dart';
import 'package:appbar_epvc/config/app_config.dart';

class SaldoPage extends StatefulWidget {
  @override
  _SaldoPageState createState() => _SaldoPageState();
}

class _SaldoPageState extends State<SaldoPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _authorizedUsers = [];
  List<String> _turmas = [];
  String? _selectedTurma;
  List<Map<String, dynamic>> _studentsByTurma = [];
  Uint8List? _selectedImage;
  String? _base64Image;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchAuthorizedUsers();
    _fetchTurmas();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _fetchAuthorizedUsers() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_Post.php'),
        body: {
          'query_param': '13',
         
        },
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _authorizedUsers = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load authorized users');
      }
    } catch (e) {
      print('Error fetching authorized users: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar utilizadores autorizados')),
      );
    }
  }
  
  Future<void> _fetchTurmas() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=20'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          // Ensure unique turma values by converting to Set and back to List
          _turmas = data.map<String>((item) => item['Turma'] as String)
                      .toSet().toList();
        });
      } else {
        throw Exception('Failed to load turmas');
      }
    } catch (e) {
      print('Error fetching turmas: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar turmas')),
      );
    }
  }
  
  Future<void> _fetchStudentsByTurma(String turma) async {
    setState(() {
      _isLoading = true;
      _studentsByTurma = []; // Clear previous results
    });
    
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=2.3&op=$turma'),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _studentsByTurma = List<Map<String, dynamic>>.from(data);
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      print('Error fetching students by turma: $e');
      setState(() {
        _isLoading = false;
        _studentsByTurma = []; // Ensure empty list on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar alunos')),
      );
    }
  }
  
  Future<void> _authorizeUser(String userId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      print('Attempting to authorize user with ID: $userId'); // Debug print
      
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=33&op=0&id=$userId'),
      );
      
      print('Authorization response status: ${response.statusCode}'); // Debug print
      print('Authorization response body: ${response.body}'); // Debug print
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Utilizador autorizado com sucesso')),
        );
        // Refresh both lists
        await _fetchAuthorizedUsers();
        if (_selectedTurma != null) {
          final String turmaName = _selectedTurma!.split(':').last;
          await _fetchStudentsByTurma(turmaName);
        }
      } else {
        throw Exception('Failed to authorize user: ${response.statusCode}');
      }
    } catch (e) {
      print('Error authorizing user: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao autorizar utilizador: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Future<void> _revokeAuthorization(String userId) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=33&op=1&id=$userId'),
      );
      
      print('Revoke response: ${response.body}'); // Debug print
      
      if (response.statusCode == 200) {
        String responseBody = response.body.trim();
        if (responseBody == "Saldo Desautorizado com sucesso.") {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Autorização revogada com sucesso')),
          );
          // Refresh both lists
          await _fetchAuthorizedUsers();
          if (_selectedTurma != null) {
            final String turmaName = _selectedTurma!.split(':').last;
            await _fetchStudentsByTurma(turmaName);
          }
        } else {
          throw Exception(responseBody);
        }
      } else {
        throw Exception('Failed to revoke authorization: ${response.statusCode}');
      }
    } catch (e) {
      print('Error revoking authorization: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao revogar autorização: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  
  Future<void> _pickImage() async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        final imageBytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImage = imageBytes;
          _base64Image = base64Encode(imageBytes);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagem carregada com sucesso')),
        );
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar imagem')),
      );
    }
  }
  
  Future<void> _uploadImageToServer(String userId) async {
    if (_base64Image == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selecione uma imagem primeiro')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_Post.php'),
        body: {
          'query_param': '22', // Assuming this is the endpoint to update user image
          'userId': userId,
          'imagem': _base64Image,
        },
      );
      
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imagem enviada com sucesso')),
        );
        setState(() {
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to upload image');
      }
    } catch (e) {
      print('Error uploading image: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao enviar imagem')),
      );
    }
  }
  
  Future<void> _addSaldo(String userId, String userName) async {
    TextEditingController _saldoController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Saldo'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Adicionar saldo para $userName'),
              SizedBox(height: 16),
              TextField(
                controller: _saldoController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[,|\.]?\d*')),
                ],
                decoration: InputDecoration(
                  labelText: 'Valor',
                  hintText: 'Ex: 10.00',
                  prefixText: '€ ',
                  border: OutlineInputBorder(),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Color.fromARGB(255, 246, 141, 45),
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                if (_saldoController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Por favor, insira um valor')),
                  );
                  return;
                }
                
                Navigator.pop(context);
                _processSaldoAddition(userId, _saldoController.text);
              },
              child: Text('Adicionar'),
              style: TextButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 246, 141, 45),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processSaldoAddition(String userId, String amount) async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Convert comma to dot if necessary
      String formattedAmount = amount.replaceAll(',', '.');
      
      // Generate a unique transaction ID using timestamp and random number
      String transactionId = DateTime.now().millisecondsSinceEpoch.toString() + 
                           (1000 + (DateTime.now().microsecond % 9000)).toString();
      
      // Update balance and record transaction in one call
      final response = await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_Post.php'),
        body: {
          'query_param': '9',
          'email': userId,
          'amount': formattedAmount,
          'transaction_id': transactionId,
          'type': '1', // 1 for credit/load
          'description': 'Carregamento Manual',
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Saldo adicionado com sucesso')),
          );
          setState(() {
            _isLoading = false;
          });
          // Refresh the list after adding saldo
          _fetchAuthorizedUsers();
        } else {
          throw Exception('Failed to process balance update: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else {
        throw Exception('Failed to process balance update: ${response.statusCode}');
      }
    } catch (e) {
      print('Error adding saldo: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao adicionar saldo: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return LoadingOverlay(
      isLoading: _isLoading,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Gestão de Saldo'),
          backgroundColor: Color.fromARGB(255, 246, 141, 45),
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: 'Utilizadores Autorizados'),
              Tab(text: 'Adicionar Autorização'),
            ],
          ),
        ),
        drawer: DrawerBar(),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildAuthorizedUsersTab(),
            _buildAddAuthorizationTab(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAuthorizedUsersTab() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(
        color: Color.fromARGB(255, 246, 141, 45),
      ));
    }
    
    if (_authorizedUsers.isEmpty) {
      return Center(child: Text('Não há utilizadores autorizados'));
    }
    
    return RefreshIndicator(
      onRefresh: _fetchAuthorizedUsers,
      color: Color.fromARGB(255, 246, 141, 45),
      child: ListView.builder(
        itemCount: _authorizedUsers.length,
        itemBuilder: (context, index) {
          final user = _authorizedUsers[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              onTap: () => _addSaldo(user['Email'], user['Nome']),
              leading: user['Imagem'] != null && user['Imagem'].toString().isNotEmpty
                ? Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      border: Border.all(color: Color.fromARGB(255, 246, 141, 45)),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: _buildUserImage(user['Imagem']),
                    ),
                  )
                : Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Icon(
                      Icons.person,
                      color: Colors.grey[600],
                    ),
                  ),
              title: Row(
                children: [
                  Text('${user['Nome']}'),
                  SizedBox(width: 8),
                  Icon(
                    Icons.add_circle_outline,
                    size: 16,
                    color: Color.fromARGB(255, 246, 141, 45),
                  ),
                  Text(
                    ' Adicionar Saldo',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color.fromARGB(255, 246, 141, 45),
                    ),
                  ),
                ],
              ),
              subtitle: Text('${user['Email']} - Turma: ${user['Turma']}'),
             /* trailing: IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () {
                  // Show confirmation dialog before revoking
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('Revogar Autorização'),
                      content: Text('Tem certeza que deseja revogar a autorização de saldo para este utilizador?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancelar'),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _revokeAuthorization(user['IdUser']);
                          },
                          child: Text('Revogar'),
                          style: TextButton.styleFrom(
                            foregroundColor: Color.fromARGB(255, 246, 141, 45),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),*/
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildUserImage(String base64String) {
    try {
      // Cleaning the base64 string to handle potential issues
      String cleaned = base64String.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
      // Ensure the string length is a multiple of 4
      while (cleaned.length % 4 != 0) {
        cleaned += '=';
      }
      
      // Decode the base64 string
      Uint8List imageBytes = base64Decode(cleaned);
      
      return Image.memory(
        imageBytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image: $error');
          return Center(
            child: Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),
          );
        },
      );
    } catch (e) {
      print('Exception when decoding image: $e');
      return Center(
        child: Icon(
          Icons.broken_image,
          size: 50,
          color: Colors.grey,
        ),
      );
    }
  }
  
  Widget _buildAddAuthorizationTab() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecione uma turma:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Turma',
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: Color.fromARGB(255, 246, 141, 45),
                        width: 2.0,
                      ),
                    ),
                  ),
                  dropdownColor: Colors.white,
                  value: _selectedTurma,
                  items: _turmas.asMap().entries.map((entry) {
                    // Use index to ensure uniqueness in case there are duplicate turma names
                    final int index = entry.key;
                    final String turma = entry.value;
                    return DropdownMenuItem<String>(
                      value: "$index:$turma", // Prefix with index to ensure uniqueness
                      child: Text(turma),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedTurma = newValue;
                      if (newValue != null) {
                        // Extract the actual turma name without the index prefix
                        final String turmaName = newValue.split(':').last;
                        _fetchStudentsByTurma(turmaName);
                      }
                    });
                  },
                ),
                SizedBox(height: 24),
                Text(
                  'Alunos da Turma:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Container(
            height: 400,
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildStudentsList(),
          ),
        ],
      ),
    );
  }
  
  
  Widget _buildStudentsList() {
    if (_selectedTurma == null) {
      return Center(child: Text('Selecione uma turma para ver os alunos'));
    }
    
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Color.fromARGB(255, 246, 141, 45),
        ),
      );
    }
    
    if (_studentsByTurma.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.no_accounts,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Não foram encontrados alunos nesta turma',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      itemCount: _studentsByTurma.length,
      itemBuilder: (context, index) {
        final student = _studentsByTurma[index];
        print('Student ${student['Nome']} - AutorizadoSaldo: ${student['AutorizadoSaldo']}');
        
        final bool isAuthorized = student['AutorizadoSaldo'] == '1' || student['AutorizadoSaldo'] == 1;
        final double saldo = double.tryParse(student['Saldo'].toString()) ?? 0.0;
        
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          child: ListTile(
            title: Text('${student['Nome']} ${student['Apelido']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student['Email']),
              ],
            ),
            trailing: ElevatedButton(
              onPressed: () {
                if (isAuthorized) {
                  if (saldo > 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Não é possível revogar autorização. O utilizador ainda tem saldo disponível.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } else {
                    _revokeAuthorization(student['IdUser'].toString());
                  }
                } else {
                  _authorizeUser(student['IdUser'].toString());
                }
              },
              child: Text(isAuthorized ? 'Não Autorizar' : 'Autorizar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isAuthorized 
                  ? Colors.red[400] 
                  : Color.fromARGB(255, 246, 141, 45),
                foregroundColor: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showStudentSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecione um Estudante'),
          content: Container(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _studentsByTurma.length,
              itemBuilder: (context, index) {
                final student = _studentsByTurma[index];
                return ListTile(
                  title: Text('${student['Nome']} ${student['Apelido']}'),
                  subtitle: Text(student['Email']),
                  onTap: () {
                    Navigator.pop(context);
                    _uploadImageToServer(student['IdUser']);
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }
} 