import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Aluno/drawerHome.dart';
import 'package:appbar_epvc/Aluno/home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:appbar_epvc/config/app_config.dart';

class PedidosPageAlunos extends StatefulWidget {
  @override
  _PedidosPageAlunosState createState() => _PedidosPageAlunosState();
}

class _PedidosPageAlunosState extends State<PedidosPageAlunos> {
  List<dynamic> users = [];
  List<dynamic> orders = [];
  bool isLoading = true;
  String? activeFilter; // 'pendentes', 'concluidos', or null for all

  @override
  void initState() {
    super.initState();
    fetchUserInfoAndOrders();
  }

  Future<void> fetchUserInfoAndOrders() async {
    await fetchUserInfo();
    if (users.isNotEmpty) {
      await fetchPurchaseOrders();
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
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_Post.php'),
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

  Future<void> fetchPurchaseOrders() async {
    if (users.isNotEmpty) {
      var nome = users[0]['Nome'];
      var apelido = users[0]['Apelido'];
      var user = '$nome $apelido';

      final response = await http.get(
        Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=13&nome=$user'),
      );
      if (response.statusCode == 200) {
        setState(() {
          orders = json.decode(response.body);
          
          // Ordenar pedidos do mais recente para o mais antigo (apenas por data)
          orders.sort((a, b) {
            try {
              // Converter formato dd/MM/yyyy para objetos DateTime
              DateTime aData = DateFormat('dd/MM/yyyy').parse(a['Data'].toString());
              DateTime bData = DateFormat('dd/MM/yyyy').parse(b['Data'].toString());
              
              // Comparar datas (ordem decrescente - mais recente primeiro)
              return bData.compareTo(aData);
            } catch (e) {
              // Se não conseguir ordenar pela data, mantém a ordem original
              return 0;
            }
          });
        });
      } else {
        print("Failed to load orders");
      }
    }
  }

  String _getStatusColor(String status) {
    if (status == '0') return 'pendente';
    return 'concluído';
  }

  Color _getStatusColorCode(String status) {
    if (status == '0') return Colors.orange;
    return Colors.green;
  }

  List<dynamic> get filteredOrders {
    if (activeFilter == null) return orders;
    if (activeFilter == 'pendentes') {
      return orders.where((order) => order['Estado'] == '0').toList();
    }
    if (activeFilter == 'concluidos') {
      return orders.where((order) => order['Estado'] != '0').toList();
    }
    return orders;
  }

  Map<String, int> _groupProducts(String description) {
    Map<String, int> groupedProducts = {};
    // Remove brackets and split by comma
    String cleanDesc = description.replaceAll('[', '').replaceAll(']', '');
    List<String> products = cleanDesc.split(',');
    
    for (String product in products) {
      product = product.trim();
      if (product.isNotEmpty) {
        groupedProducts[product] = (groupedProducts[product] ?? 0) + 1;
      }
    }
    return groupedProducts;
  }

  void _showOrderDetailsDialog(Map<String, dynamic> order) {
    Map<String, int> groupedProducts = _groupProducts(order['Descricao']);
    String status = order["Estado"] == '0' ? 'pendente' : 'concluído';
    Color statusColor = _getStatusColorCode(order["Estado"]);
    var formattedTotal = "";
    try {
      formattedTotal = double.parse(order['Total'])
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    } catch (e) {
      formattedTotal = 'Inválido';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          order["Estado"] == '0' 
                            ? Icons.pending_actions 
                            : Icons.check_circle,
                          color: statusColor,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Pedido #${order["NPedido"]}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Data e Hora
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          '${order["Data"]}',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                        SizedBox(width: 4),
                        Text(
                          '${order["Hora"]}',
                          style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Produtos agrupados
                Text(
                  'Produtos:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(height: 8),
                Container(
                  constraints: BoxConstraints(maxHeight: 200),
                  child: SingleChildScrollView(
                    child: Column(
                      children: groupedProducts.entries.map((entry) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${entry.value}x',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total: ',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$formattedTotal€',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                // Botão de fechar
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Fechar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Meus Pedidos', 
          style: TextStyle(fontWeight: FontWeight.bold)
        ),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              fetchUserInfoAndOrders();
            },
            icon: Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HomeAlunoMain(),
                ),
              );
            },
            icon: Icon(Icons.home),
          ),
        ],
      ),
      drawer: DrawerHome(),
      body: Column(
        children: [
          // Header com estatísticas
          Container(
            padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            
            child: Column(
              children: [
                Text(
                  'Meu Histórico de Pedidos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                  
                    _buildStatCard(
                      'Pendentes', 
                      '${orders.where((order) => order['Estado'] == '0').length}',
                      Icons.pending_actions,
                      Colors.orange,
                      'pendentes'
                    ),
                    _buildStatCard(
                      'Concluídos', 
                      '${orders.length - orders.where((order) => order['Estado'] == '0').length}',
                      Icons.check_circle_outline,
                      Colors.green,
                      'concluidos'
                    ),
                      _buildStatCard(
                      'Total', 
                      '${orders.length}',
                      Icons.receipt_long,
                      Colors.blue,
                      'total'
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Lista de pedidos
          Expanded(
            child: isLoading
              ? Center(child: CircularProgressIndicator())
              : filteredOrders.isNotEmpty
                ? ListView.builder(
                    padding: EdgeInsets.only(top: 12),
                    itemCount: filteredOrders.length,
                    itemBuilder: (context, index) {
                      var order = filteredOrders[index];
                      var formattedTotal = "";
                      try {
                        formattedTotal = double.parse(order['Total'])
                            .toStringAsFixed(2)
                            .replaceAll('.', ',');
                      } catch (e) {
                        formattedTotal = 'Inválido';
                      }

                      String status = order["Estado"] == '0' ? 'pendente' : 'concluído';
                      Color statusColor = _getStatusColorCode(order["Estado"]);

                      return GestureDetector(
                        onTap: () => _showOrderDetailsDialog(order),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: statusColor.withOpacity(0.5),
                              width: 1,
                            ),
                          ),
                          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: Column(
                            children: [
                              // Header do pedido
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    topRight: Radius.circular(12),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          order["Estado"] == '0' 
                                            ? Icons.pending_actions 
                                            : Icons.check_circle,
                                          color: statusColor,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Pedido #${order["NPedido"]}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: statusColor,
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: statusColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Detalhes do pedido
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Produtos
                                    Text(
                                      'Produtos:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey[700],
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: _groupProducts(order['Descricao'])
                                            .entries
                                            .map((entry) => Padding(
                                                  padding: EdgeInsets.symmetric(vertical: 2),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                        padding: EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: Colors.blue.withOpacity(0.1),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          '${entry.value}x',
                                                          style: TextStyle(
                                                            fontWeight: FontWeight.bold,
                                                            color: Colors.blue,
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(width: 8),
                                                      Expanded(
                                                        child: Text(
                                                          entry.key,
                                                          style: TextStyle(fontSize: 13),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ))
                                            .toList(),
                                      ),
                                    ),
                                    SizedBox(height: 12),
                                    
                                    // Informações de tempo e valor
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Text(
                                              '${order["Data"]}',
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                                            SizedBox(width: 4),
                                            Text(
                                              '${order["Hora"]}',
                                              style: TextStyle(
                                                color: Colors.grey[800],
                                                fontSize: 13,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 12),
                                    
                                    // Valor total
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          'Total: ',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          '$formattedTotal€',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
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
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Você ainda não fez nenhum pedido",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Os seus pedidos aparecerão aqui",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatCard(String title, String value, IconData icon, Color color, String filterType) {
    bool isActive = activeFilter == filterType;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          if (activeFilter == filterType) {
            activeFilter = null; // Desativa o filtro se já estiver ativo
          } else {
            activeFilter = filterType;
          }
        });
      },
      child: Card(
        elevation: isActive ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: isActive ? BorderSide(color: color, width: 2) : BorderSide.none,
        ),
        child: Container(
          width: 100,
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 28),
              SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18, 
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
