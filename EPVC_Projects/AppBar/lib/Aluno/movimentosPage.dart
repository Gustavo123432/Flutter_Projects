import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:appbar_epvc/Aluno/drawerHome.dart';

class MovimentosPage extends StatefulWidget {
  @override
  _MovimentosPageState createState() => _MovimentosPageState();
}

class _MovimentosPageState extends State<MovimentosPage> {
  List<dynamic> users = [];
  List<dynamic> movements = [];
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchUserInfoAndMovements();
  }

  Future<void> fetchUserInfoAndMovements() async {
    await fetchUserInfo();
    if (users.isNotEmpty) {
      await fetchMovements();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> fetchUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var user = prefs.getString("username");

    if (user != null) {
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
      } else {
        print("Failed to load user info");
      }
    }
  }

  Future<void> fetchMovements() async {
    if (users.isNotEmpty) {
      var user = users[0]['Email'];

      final response = await http.get(
        Uri.parse(
            'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=34&user=$user'),
      );
      if (response.statusCode == 200) {
        setState(() {
          movements = json.decode(response.body);
           // Sort movements by date (most recent first)
          movements.sort((a, b) {
            try {
              DateTime aData = DateFormat('dd/MM/yyyy HH:mm:ss').parse(a['Data'].toString());
              DateTime bData = DateFormat('dd/MM/yyyy HH:mm:ss').parse(b['Data'].toString());
              return bData.compareTo(aData);
            } catch (e) {
              return 0;
            }
          });
        });
      } else {
        print("Failed to load movements");
      }
    }
  }

  Future<Map<String, dynamic>?> fetchOrderDetails(String orderNumber) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=35&npedido=$orderNumber'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data != null && data.isNotEmpty) {
          return data[0];
        }
      }
      return null;
    } catch (e) {
      print("Error fetching order details: $e");
      return null;
    }
  }

  String _getMovementTypeText(String type) {
    switch (type) {
      case '1':
        return 'Carregamento';
      case '2':
        return 'Compra';
      default:
        return 'Desconhecido';
    }
  }

  Color _getMovementTypeColor(String type) {
    switch (type) {
      case '1':
        return Colors.green;
      case '2':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Map<String, int> _groupItems(String description) {
    Map<String, int> groupedItems = {};
    if (description != null && description.isNotEmpty) {
      // Remove brackets and split by comma
      String cleanDesc = description.replaceAll('[', '').replaceAll(']', '');
      List<String> items = cleanDesc.split(',');
      
      // Count occurrences of each item
      for (String item in items) {
        String trimmedItem = item.trim();
        if (trimmedItem.isNotEmpty) {
          groupedItems[trimmedItem] = (groupedItems[trimmedItem] ?? 0) + 1;
        }
      }
    }
    return groupedItems;
  }

  void _showOrderDetails(String orderNumber) async {
    setState(() {
      isLoading = true;
    });

    // Fetch detailed order information
    final orderDetails = await fetchOrderDetails(orderNumber);
    
    setState(() {
      isLoading = false;
    });

    if (orderDetails == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível carregar os detalhes do pedido')),
      );
      return;
    }

    // Show order details dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Find the corresponding movement to get the full date
        final correspondingMovement = movements.firstWhere(
          (m) => m['Descricao'].toString().contains('Pedido Nº${orderDetails['NPedido']}'),
          orElse: () => null, // Return null if not found
        );

        return AlertDialog(
          title: Text(
            'Detalhes do Pedido ${orderDetails['NPedido']}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.black87,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Data: ${correspondingMovement != null ? correspondingMovement['Data'] : 'N/A'}'),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.15),
                        border: Border.all(color: Colors.blue),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pedido',
                        style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.person, size: 18, color: Colors.blueGrey),
                    SizedBox(width: 6),
                    Text('Quem pediu: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(child: Text(orderDetails['Qpediu'] ?? 'N/A')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.group, size: 18, color: Colors.blueGrey),
                    SizedBox(width: 6),
                    Text('Turma: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(child: Text(orderDetails['Turma'] ?? 'N/A')),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.description, size: 18, color: Colors.blueGrey),
                    SizedBox(width: 6),
                    Text('Descrição: ', style: TextStyle(fontWeight: FontWeight.w500)),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _groupItems(orderDetails['Descricao']?.toString() ?? '')
                            .entries
                            .map((entry) => Text(
                                  '• ${entry.value}x ${entry.key}',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ))
                            .toList(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                 if (orderDetails['Permissao'] != null) // Only show if permission is available
                  Row(
                    children: [
                      Icon(Icons.security, size: 18, color: Colors.blueGrey),
                      SizedBox(width: 6),
                      Text('Permissão: ', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text(
                        orderDetails['Permissao'].toString() ?? 'N/A',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  List<dynamic> get filteredMovements {
    if (_searchQuery.isEmpty) {
      return movements;
    }
    return movements.where((movement) {
      final description = movement['Descricao'].toString().toLowerCase();
      final date = movement['Data'].toString().toLowerCase();
      final searchLower = _searchQuery.toLowerCase();
      
      return description.contains(searchLower) ||
             date.contains(searchLower);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Meus Movimentos'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              fetchUserInfoAndMovements();
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Pesquisar por descrição ou data...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: filteredMovements.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum movimento encontrado',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredMovements.length,
                          itemBuilder: (context, index) {
                            final movement = filteredMovements[index];
                            final isCredit = movement['Tipo'] == '1';
                            final amount = double.parse(movement['Valor'].toString());
                            
                            // Check if description contains order number
                            String? orderNumber;
                            if (movement['Descricao'].toString().contains('Pedido Nº')) {
                              final match = RegExp(r'Pedido Nº(\d+)').firstMatch(movement['Descricao'].toString());
                              if (match != null) {
                                orderNumber = match.group(1);
                              }
                            }

                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: ListTile(
                                onTap: orderNumber != null ? () => _showOrderDetails(orderNumber!) : null,
                                leading: CircleAvatar(
                                  backgroundColor: _getMovementTypeColor(movement['Tipo'].toString()).withOpacity(0.2),
                                  child: Icon(
                                    isCredit ? Icons.add : Icons.remove,
                                    color: _getMovementTypeColor(movement['Tipo'].toString()),
                                  ),
                                ),
                                title: Text(
                                  _getMovementTypeText(movement['Tipo'].toString()),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getMovementTypeColor(movement['Tipo'].toString()),
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Data: ${movement['Data']}',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                    Text(
                                      movement['Descricao'],
                                      style: TextStyle(fontSize: 12),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  '${isCredit ? '+' : '-'}${NumberFormat.currency(locale: 'pt_PT', symbol: '€', decimalDigits: 2).format(amount)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _getMovementTypeColor(movement['Tipo'].toString()),
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
