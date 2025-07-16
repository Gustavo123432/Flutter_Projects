import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:appbar_epvc/Admin/drawerAdmin.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:appbar_epvc/login.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../config/app_config.dart';

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
  Map<String, String> formattedSalesData =
      {}; // For display (formatted strings)
  String formattedTotalRevenue = '€0,00'; // Formatted total
  double numericTotalRevenue = 0.0; // Numeric total
  Map<String, String> displayData = {}; // For display
  String selectedTimeRange = 'Hoje';
  
  // Payment statistics
  int mbwayCount = 0;
  int cashCount = 0;
  int totalPaymentCount = 0;

  @override
  void initState() {
    super.initState();
    // Force load sample data immediately to ensure UI displays
    _loadSampleData();
    fetchDashboardData();
    fetchPaymentStats();
  }

  Future<void> fetchDashboardData() async {
    setState(() {
      isLoading = true;
    });

  
    
      setState(() {
        _loadSampleData();
        isLoading = false;
      });
      
    
  }

  Future<void> fetchPaymentStats() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=32'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          mbwayCount = data['mbway_count'] ?? 0;
          cashCount = data['cash_count'] ?? 0;
          totalPaymentCount = data['total_count'] ?? 0;
        });
      } else {
        print("Error fetching payment stats: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching payment stats: $e");
    }
  }

  void fetchQuantidadeClientes() {
    http
        .get(Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=2'))
        .then((response) {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalUsers = int.parse(data['clients_count']) ?? 0;
        });
      } else {
        print("Erro ao obter quantidade de clientes: ${response.statusCode}");
      }
    }).catchError((error) {
      print("Erro ao obter quantidade de clientes: $error");
    });
  }

  void fetchQuantidadeProdutos() {
    http
        .get(Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=25'))
        .then((response) {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalProducts = int.parse(data['product_count']) ?? 0;
        });
      } else {
        print("Erro ao obter quantidade de produtos: ${response.statusCode}");
      }
    }).catchError((error) {
      print("Erro ao obter quantidade de produtos: $error");
    });
  }

  void fetchQuantidadePedidos() {
    http
        .get(Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=26'))
        .then((response) {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalOrders = int.parse(data['orders_count']) ?? 0;
        });
      } else {
        print("Erro ao obter quantidade de pedidos: ${response.statusCode}");
      }
    }).catchError((error) {
      print("Erro ao obter quantidade de pedidos: $error");
    });
  }

  void fetchAnualReceita() {
    http
        .get(Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=27'))
        .then((response) {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          totalRevenue = double.parse(data['annual_total']) ?? 0.0;
        });
      } else {
        print("Erro ao obter quantidade de pedidos: ${response.statusCode}");
      }
    }).catchError((error) {
      print("Erro ao obter quantidade de pedidos: $error");
    });
  }

  void fetchMonthTotalValue() {
    http
        .get(Uri.parse(
            '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=28'))
        .then((response) {
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          final monthlyData = data['monthly_breakdown'] as List;

          // Setup Euro formatter
          final NumberFormat euroFormat = NumberFormat.currency(
            locale: 'pt_PT',
            symbol: '€',
            decimalDigits: 2,
          );

          // For chart data (keep numeric values)
          final Map<String, double> numericSalesData = {};
          // For display (formatted strings)
          final Map<String, String> formattedSalesData = {};
          double total = 0;

          for (var month in monthlyData) {
            final monthNumber = month['month_number']?.toString() ?? '';
            final value = (month['monthly_total'] as num).toDouble();
            if (monthNumber.isNotEmpty) {
              numericSalesData[monthNumber] = value;
              formattedSalesData[monthNumber] = euroFormat.format(value);
              total += value;
            }
          }

          // Format the total
          final formattedTotal = euroFormat.format(total);

          // Update state
          salesData = Map.fromEntries(numericSalesData.entries.toList()..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key))));
          displayData = Map.fromEntries(formattedSalesData.entries.toList()..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key))));

        });
      } else {
        print("Error fetching orders: ${response.statusCode}");
      }
    }).catchError((error) {
      print("Error fetching orders: $error");
    });
  }

  Future<void> fetchRecentOrders() async {
    try {
      final response = await http.get(Uri.parse(
          '${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=29'));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);

        setState(() {
          recentOrders = data.map((order) {
            return {
              'NPedido': order['NPedido'].toString(),
              'QPediu': order['QPediu'],
              'Data': order['Data'],
              'Total': double.parse(order['Total']).toStringAsFixed(2),
              'Estado': order['Estado'].toString(),
            };
          }).toList();
        });
      } else {
        throw Exception('Failed to load orders');
      }
    } catch (e) {
      print('Error fetching orders: $e');
      // Fallback to sample data if API fails
      setState(() {
        recentOrders = [
          {
            'NPedido': '1001',
            'QPediu': 'João Silva',
            'Data':
                DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
            'Total': '12.50',
            'Estado': '2',
          },
          // ... other sample data
        ];
      });
    }
  }
void fetchPopularProducts() {
  http.get(
    Uri.parse('${AppConfig.apiBaseUrl}/appBarAPI_GET.php?query_param=30')
  ).then((response) {
    if (response.statusCode == 200) {
      try {
        final data = json.decode(response.body);
        setState(() {
          popularProducts = List<Map<String, dynamic>>.from(data.map((product) {
            return {
              'Nome': product['Nome']?.toString() ?? '',
              'quantidade_vendida': (product['quantidade_vendida'] is int 
                  ? product['quantidade_vendida'] 
                  : int.tryParse(product['quantidade_vendida']?.toString() ?? '0') ?? 0),
              'Preco': (product['Preco'] is double
                  ? product['Preco']
                  : double.tryParse(product['Preco']?.toString() ?? '0') ?? 0.0),
              'Qtd': product['Qtd']?.toString() ?? '0',
            };
          }));
        });
      } catch (e) {
        print('Error parsing products: $e');
        setState(() {
          popularProducts = [];
        });
      }
    } else {
      print("Erro ao obter produtos populares: ${response.statusCode}");
    }
  }).catchError((error) {
    print("Erro ao obter produtos populares: $error");
    setState(() {
      popularProducts = [];
    });
  });
}

  void _loadSampleData() {
    // Sample statistics
    fetchQuantidadeClientes();
    fetchQuantidadeProdutos();
    fetchQuantidadePedidos();
    fetchAnualReceita();
    fetchMonthTotalValue();
    fetchRecentOrders();
    fetchPopularProducts();
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
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isSmallScreen = constraints.maxWidth < 600;
        bool isMediumScreen = constraints.maxWidth >= 600 && constraints.maxWidth < 1200;

        return Scaffold(
         
          body: isLoading
              ? Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      _buildResponsiveStatisticsCards(isSmallScreen),
                      SizedBox(height: 24),
                      _buildResponsiveCharts(isSmallScreen, isMediumScreen),
                      SizedBox(height: 24),
                      _buildResponsiveRecentOrdersTable(isSmallScreen),
                      SizedBox(height: 24),
                      _buildResponsivePopularProductsTable(isSmallScreen),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildResponsiveStatisticsCards(bool isSmallScreen) {
    return GridView.count(
      crossAxisCount: isSmallScreen ? 2 : 4,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      childAspectRatio: isSmallScreen ? 1 : 1.2,
      children: [
        _buildStatCard(
          title: 'Clientes',
          value: totalUsers.toString(),
          icon: Icons.people,
          color: Colors.blue,
          isSmallScreen: isSmallScreen,
        ),
        _buildStatCard(
          title: 'Produtos',
          value: totalProducts.toString(),
          icon: Icons.shopping_bag,
          color: Colors.green,
          isSmallScreen: isSmallScreen,
        ),
        _buildStatCard(
          title: 'Pedidos',
          value: totalOrders.toString(),
          icon: Icons.shopping_cart,
          color: Colors.orange,
          isSmallScreen: isSmallScreen,
        ),
        _buildStatCard(
          title: 'Receita Anual',
          value: '${totalRevenue.toStringAsFixed(2).replaceAll('.', ',')}€',
          icon: Icons.euro,
          color: Colors.orange,
          isSmallScreen: isSmallScreen,
        ),
      ],
    );
  }

  Widget _buildResponsiveCharts(bool isSmallScreen, bool isMediumScreen) {
    if (isSmallScreen) {
      return Column(
        children: [
          _buildBasicSalesChart(),
          SizedBox(height: 16),
          _buildPaymentMethodsChart(),
        ],
      );
    } else if (isMediumScreen) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _buildBasicSalesChart(),
              ),
              SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: _buildPaymentMethodsChart(),
              ),
            ],
          ),
        ],
      );
    } else {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: _buildBasicSalesChart(),
          ),
          SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: _buildPaymentMethodsChart(),
          ),
        ],
      );
    }
  }

  Widget _buildResponsiveRecentOrdersTable(bool isSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 400) {
          // Full width, sem scroll horizontal
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
                  _buildBasicRecentOrdersTable(),
                ],
              ),
            ),
          );
        } else {
          // Scroll horizontal para telas pequenas
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 600,
                      ),
                      child: _buildBasicRecentOrdersTable(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildResponsivePopularProductsTable(bool isSmallScreen) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 400) {
          // Full width, sem scroll horizontal
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
                  _buildBasicPopularProductsTable(),
                ],
              ),
            ),
          );
        } else {
          // Scroll horizontal para telas pequenas
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: 600,
                      ),
                      child: _buildBasicPopularProductsTable(),
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isSmallScreen = false,
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
            padding: EdgeInsets.all(isSmallScreen ? 10 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: color,
                  size: isSmallScreen ? 40 : 48,
                ),
                SizedBox(height: isSmallScreen ? 8 : 16),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 4 : 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
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
  // Portuguese month names
  final Map<int, String> portugueseMonths = {
    1: 'Janeiro',
    2: 'Fevereiro',
    3: 'Março',
    4: 'Abril',
    5: 'Maio',
    6: 'Junho',
    7: 'Julho',
    8: 'Agosto',
    9: 'Setembro',
    10: 'Outubro',
    11: 'Novembro',
    12: 'Dezembro',
  };

  return Card(
    elevation: 4,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendas por Mês',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 2,
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  'Vendas Mensais',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                SizedBox(height: 8),
                Expanded(
                  child: salesData.isEmpty
                      ? Center(
                          child: Text(
                            'Sem dados de vendas disponíveis',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.orange[300],
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  final monthNumber = group.x.toInt();
                                  final monthName = portugueseMonths[monthNumber] ?? 'Mês $monthNumber';
                                  final value = salesData[monthNumber.toString()] ?? 0.0;
                                  return BarTooltipItem(
                                    '$monthName\n€${value.toStringAsFixed(2).replaceAll('.', ',')}',
                                    TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (value, meta) {
                                    final monthName = portugueseMonths[value.toInt()] ?? 'Mês ${value.toInt()}';
                                    return Padding(
                                      padding: EdgeInsets.only(top: 8),
                                      child: Text(
                                        monthName,
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 40,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      '${value.toInt()}€',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.grey[200],
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border(
                                bottom: BorderSide(
                                  color: Colors.grey[300]!,
                                  width: 1,
                                ),
                              ),
                            ),
                            barGroups: salesData.entries.map((entry) {
                              final monthNumber = int.parse(entry.key);
                              return BarChartGroupData(
                                x: monthNumber,
                                barRods: [
                                  BarChartRodData(
                                    toY: entry.value,
                                    color: Colors.orange[400],
                                    width: 16,
                                    borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(4)),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                ),
                if (salesData.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      'Total: ${totalRevenue.toStringAsFixed(2).replaceAll('.', ',')}€',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[800],
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
    ),
  );
}

  Widget _buildBasicRecentOrdersTable() {
    return Table(
      border: TableBorder.all(
        color: Colors.grey.shade300,
        width: 1,
        style: BorderStyle.solid,
      ),
      columnWidths: {
        0: FractionColumnWidth(0.1), // Nº
        1: FractionColumnWidth(0.3), // Cliente
        2: FractionColumnWidth(0.25), // Data
        3: FractionColumnWidth(0.15), // Total
        4: FractionColumnWidth(0.2), // Estado
      },
      children: [
        TableRow(
          decoration: BoxDecoration(color: Colors.grey.shade200),
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Nº',
                    style:
                        TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Cliente',
                    style:
                        TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Data',
                    style:
                        TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Total',
                    style:
                        TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Estado',
                    style:
                        TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
        ...recentOrders.map((order) {
          String status = '';
          Color statusColor = Colors.grey;

          switch (order['Estado']?.toString() ?? '0') {
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

          // Corrige a formatação do valor total
          final totalValue = double.tryParse(
                  order['Total']?.toString() ?? '0') ??
              0;
          final formattedTotal = NumberFormat.currency(
            symbol: '€',
            decimalDigits: 2,
            locale: 'pt_PT',
          ).format(totalValue);

          return TableRow(
            children: [
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(order['NPedido']?.toString() ?? ''),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(order['QPediu']?.toString() ?? ''),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    order['Data'] != null
                        ? DateFormat('dd/MM/yyyy').format(
                            DateTime.tryParse(
                                    order['Data'].toString()) ??
                                DateTime.now())
                        : 'N/A',
                  ),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(formattedTotal),
                ),
              ),
              TableCell(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
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
    );
  }

Widget _buildBasicPopularProductsTable() {
  return Table(
    border: TableBorder.all(
      color: Colors.grey.shade300,
      width: 1,
      style: BorderStyle.solid,
    ),
    columnWidths: {
      0: FractionColumnWidth(0.4), // Produto
      1: FractionColumnWidth(0.2), // Vendidos
      2: FractionColumnWidth(0.2), // Receita
      3: FractionColumnWidth(0.2), // Disponível
    },
    children: [
      TableRow(
        decoration: BoxDecoration(color: Colors.grey.shade200),
        children: [
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Produto',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Vendidos',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Receita',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          TableCell(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text('Disponível',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      ...popularProducts.map((product) {
        // Fix: Ensure values are properly typed
        final vezesPedido = int.tryParse(product['quantidade_vendida']?.toString() ?? '0') ?? 0;
        final preco = double.tryParse(product['Preco']?.toString() ?? '0') ?? 0.0;
        final receitaTotal = vezesPedido * preco;
        final isAvailable = product['Qtd']?.toString() == '1';

        return TableRow(
          children: [
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(product['Nome']?.toString() ?? ''),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  vezesPedido.toString(),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  '${receitaTotal.toStringAsFixed(2).replaceAll('.', ',')}€',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            TableCell(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAvailable
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isAvailable
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  child: Text(
                    isAvailable ? 'Sim' : 'Não',
                    style: TextStyle(
                      color: isAvailable
                          ? Colors.green
                          : Colors.red,
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
  );
}

Widget _buildPaymentMethodsChart() {
  return Card(
    elevation: 4,
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Métodos de Pagamento',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Container(
            height: 220,
            child: PieChart(
              PieChartData(
                sections: [
                  PieChartSectionData(
                    value: mbwayCount.toDouble(),
                    title: 'MBWay\n${((mbwayCount / totalPaymentCount) * 100).toStringAsFixed(1)}%',
                    color: Colors.red[800],
                    radius: 80,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: cashCount.toDouble(),
                    title: 'Dinheiro\n${((cashCount / totalPaymentCount) * 100).toStringAsFixed(1)}%',
                    color: Colors.green[700],
                    radius: 80,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  PieChartSectionData(
                    value: (totalPaymentCount - mbwayCount - cashCount).toDouble(),
                    title: 'Saldo\n${(((totalPaymentCount - mbwayCount - cashCount) / totalPaymentCount) * 100).toStringAsFixed(1)}%',
                    color: Colors.orange[400],
                    radius: 80,
                    titleStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
                sectionsSpace: 2,
                centerSpaceRadius: 40,
              ),
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem('MBWay', Colors.red[800]!),
              SizedBox(width: 16),
              _buildLegendItem('Dinheiro', Colors.green[700]!),
              SizedBox(width: 16),
              _buildLegendItem('Saldo', Colors.orange[400]!),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildLegendItem(String label, Color color) {
  return Row(
    children: [
      Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 8),
      Text(label),
    ],
  );
}
}
