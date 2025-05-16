import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:my_flutter_project/Admin/drawerAdmin.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_flutter_project/login.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Statistics data
  int totalUsers = 0;
  int totalProducts = 0;
  int totalOrders = 0;
  double totalRevenue = 0.0;
  List<Map<String, dynamic>> recentOrders = [];
  List<Map<String, dynamic>> popularProducts = [];
  Map<String, double> salesData = {};
  bool isLoading = true;
  String selectedTimeRange = 'Hoje';

  @override
  void initState() {
    super.initState();
    // Force load sample data immediately to ensure UI displays
    _loadSampleData();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Fetch dashboard statistics
      final response = await http.get(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=30&time_range=$selectedTimeRange'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        print("Dashboard API response: $data"); // Debug print
        
        setState(() {
          totalUsers = data['total_users'] ?? 0;
          totalProducts = data['total_products'] ?? 0;
          totalOrders = data['total_orders'] ?? 0;
          totalRevenue = double.parse((data['total_revenue'] ?? '0').toString());
          
          // Parse recent orders
          if (data['recent_orders'] != null) {
            recentOrders = List<Map<String, dynamic>>.from(data['recent_orders']);
          }
          
          // Parse popular products
          if (data['popular_products'] != null) {
            popularProducts = List<Map<String, dynamic>>.from(data['popular_products']);
          }
          
          // Parse sales data for chart
          if (data['sales_data'] != null) {
            final Map<String, dynamic> rawSalesData = data['sales_data'];
            salesData = Map<String, double>.from(
              rawSalesData.map((key, value) => MapEntry(key, double.parse(value.toString())))
            );
          }
          
          // If no data was received, use sample data for demonstration
          if (totalUsers == 0 && totalProducts == 0 && totalOrders == 0 && 
              totalRevenue == 0 && recentOrders.isEmpty && popularProducts.isEmpty) {
            _loadSampleData();
          }
          
          isLoading = false;
        });
      } else {
        print("API Error: ${response.statusCode} - ${response.body}"); // Debug print
        setState(() {
          _loadSampleData();
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: ${response.statusCode} - usando dados de exemplo')),
        );
      }
    } catch (e) {
      print("Exception: $e"); // Debug print
      setState(() {
        _loadSampleData();
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar dados: $e - usando dados de exemplo')),
      );
    }
  }

  void _loadSampleData() {
    // Sample statistics
    totalUsers = 124;
    totalProducts = 37;
    totalOrders = 256;
    totalRevenue = 1285.50;
    
    // Sample sales data
    salesData = {
      'Jan': 120.5,
      'Fev': 150.2,
      'Mar': 200.8,
      'Abr': 180.3,
      'Mai': 210.5,
      'Jun': 250.0,
    };
    
    // Sample recent orders
    recentOrders = [
      {
        'NPedido': '1001',
        'QPediu': 'João Silva',
        'Data': DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
        'Total': '12.50',
        'Estado': '2',
      },
      {
        'NPedido': '1002',
        'QPediu': 'Maria Oliveira',
        'Data': DateTime.now().subtract(Duration(hours: 3)).toIso8601String(),
        'Total': '8.75',
        'Estado': '1',
      },
      {
        'NPedido': '1003',
        'QPediu': 'Carlos Santos',
        'Data': DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
        'Total': '15.30',
        'Estado': '0',
      },
    ];
    
    // Sample popular products
    popularProducts = [
      {
        'Nome': 'Café',
        'Imagem': '',
        'quantidade_vendida': '42',
        'Preco': '1.20',
        'Qtd': '1',
      },
      {
        'Nome': 'Croissant',
        'Imagem': '',
        'quantidade_vendida': '38',
        'Preco': '1.50',
        'Qtd': '1',
      },
      {
        'Nome': 'Água',
        'Imagem': '',
        'quantidade_vendida': '65',
        'Preco': '0.80',
        'Qtd': '1',
      },
      {
        'Nome': 'Sandes Mista',
        'Imagem': '',
        'quantidade_vendida': '29',
        'Preco': '2.50',
        'Qtd': '0',
      },
    ];
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Pretende fazer Log Out?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (ctx) => LoginForm()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Simpler layout that will definitely display
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard Admin'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchDashboardData,
            tooltip: 'Atualizar dados',
          ),
          IconButton(
            onPressed: () {
              logout(context);
            },
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      drawer: DrawerAdmin(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Visão Geral - $selectedTimeRange',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildStatisticsCards(),
                  SizedBox(height: 24),
                  _buildBasicSalesChart(),
                  SizedBox(height: 24),
                  _buildBasicRecentOrdersTable(),
                  SizedBox(height: 24),
                  _buildBasicPopularProductsTable(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatisticsCards() {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard(
          title: 'Usuários',
          value: totalUsers.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        _buildStatCard(
          title: 'Produtos',
          value: totalProducts.toString(),
          icon: Icons.shopping_bag,
          color: Colors.green,
        ),
        _buildStatCard(
          title: 'Pedidos',
          value: totalOrders.toString(),
          icon: Icons.shopping_cart,
          color: Colors.orange,
        ),
        _buildStatCard(
          title: 'Receita',
          value: '${totalRevenue.toStringAsFixed(2).replaceAll('.', ',')}€',
          icon: Icons.euro,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: 48,
                ),
                SizedBox(height: 16),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicSalesChart() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendas ($selectedTimeRange)',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Container(
              height: 200,
              child: salesData.isEmpty 
                ? Center(child: Text('Sem dados de vendas disponíveis'))
                : Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: salesData.values.reduce((a, b) => a > b ? a : b) * 1.2,
                        barTouchData: BarTouchData(enabled: true),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < salesData.keys.length) {
                                  var keys = salesData.keys.toList();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      keys[value.toInt()],
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  );
                                }
                                return Text('');
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                return Text('${value.toInt()}€', 
                                  style: TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        ),
                        gridData: FlGridData(show: false),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          salesData.length,
                          (index) {
                            var keys = salesData.keys.toList();
                            var values = salesData.values.toList();
                            return BarChartGroupData(
                              x: index,
                              barRods: [
                                BarChartRodData(
                                  toY: values[index],
                                  color: Colors.blue,
                                  width: 20,
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
                                )
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicRecentOrdersTable() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedidos Recentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            recentOrders.isEmpty
                ? Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text('Sem pedidos recentes'),
                  )
                : Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                    columnWidths: {
                      0: FractionColumnWidth(0.1),  // Nº
                      1: FractionColumnWidth(0.3),  // Cliente
                      2: FractionColumnWidth(0.25), // Data
                      3: FractionColumnWidth(0.15), // Total
                      4: FractionColumnWidth(0.2),  // Estado
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Nº', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Cliente', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Data', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Estado', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      ...recentOrders.map((order) {
                        String status = '';
                        Color statusColor = Colors.grey;
                        
                        switch (order['Estado'].toString()) {
                          case '0':
                            status = 'Pendente';
                            statusColor = Colors.orange;
                            break;
                          case '1':
                            status = 'Em Preparação';
                            statusColor = Colors.blue;
                            break;
                          case '2':
                            status = 'Concluído';
                            statusColor = Colors.green;
                            break;
                          default:
                            status = 'Desconhecido';
                        }
                        
                        return TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(order['NPedido'].toString()),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(order['QPediu'].toString()),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  order['Data'] != null 
                                    ? DateFormat('dd/MM/yyyy').format(
                                        DateTime.parse(order['Data'].toString())
                                      )
                                    : 'N/A'
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${double.parse(order['Total'].toString()).toStringAsFixed(2).replaceAll('.', ',')}€'
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicPopularProductsTable() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Produtos Populares',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            popularProducts.isEmpty
                ? Container(
                    height: 100,
                    alignment: Alignment.center,
                    child: Text('Sem dados de produtos'),
                  )
                : Table(
                    border: TableBorder.all(
                      color: Colors.grey.shade300,
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                    columnWidths: {
                      0: FractionColumnWidth(0.4),  // Produto
                      1: FractionColumnWidth(0.2),  // Vendidos
                      2: FractionColumnWidth(0.2),  // Receita
                      3: FractionColumnWidth(0.2),  // Disponível
                    },
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade200),
                        children: [
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Produto', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Vendidos', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Receita', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          TableCell(
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text('Disponível', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      ...popularProducts.map((product) {
                        bool isAvailable = product['Qtd'] == '1';
                        
                        return TableRow(
                          children: [
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(product['Nome'].toString()),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  product['quantidade_vendida'].toString(),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  '${(double.parse(product['Preco'].toString()) * int.parse(product['quantidade_vendida'].toString())).toStringAsFixed(2).replaceAll('.', ',')}€',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                            TableCell(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isAvailable ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isAvailable ? Colors.green : Colors.red,
                                    ),
                                  ),
                                  child: Text(
                                    isAvailable ? 'Sim' : 'Não',
                                    style: TextStyle(
                                      color: isAvailable ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
} 