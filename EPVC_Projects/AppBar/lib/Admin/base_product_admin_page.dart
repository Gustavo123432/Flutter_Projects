import 'package:appbar_epvc/login.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/base_product_manager_widget.dart';
import '../widgets/auto_base_product_detector.dart';
import 'drawerAdmin.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class BaseProductAdminPage extends StatefulWidget {
  @override
  _BaseProductAdminPageState createState() => _BaseProductAdminPageState();
}

class _BaseProductAdminPageState extends State<BaseProductAdminPage> {
  List<Product> allProducts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_Post.php'),
        body: {
          'query_param': '4',
        },
      );

      if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);
        List<Product> fetchedProducts = responseBody.map((productData) {
          return Product.fromJson(productData);
        }).toList();

        setState(() {
          allProducts = fetchedProducts;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load products');
      }
    } catch (e) {
      print('Error loading products: $e');
      setState(() {
        isLoading = false;
      });
    }
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
                  MaterialPageRoute(
                    builder: (BuildContext ctx) => LoginForm(),
                  ),
                );
                ModalRoute.withName('/');
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Gestão de Produtos Base'),
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => logout(context),
            icon: Icon(Icons.logout, color: Colors.white),
          ),
        ],
      ),
      drawer: DrawerAdmin(),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Header with info
                Container(
                  padding: EdgeInsets.all(16),
                  color: Colors.orange.shade50,
                  child: Column(
                    children: [
                      Text(
                        'Sistema de Produtos Base',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Gerencie produtos base e suas variações para controlo de inventário unificado',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                
                // Quick actions
                Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showAutoDetector(),
                          icon: Icon(Icons.auto_awesome),
                          label: Text('Detector Automático'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _showManualManager(),
                          icon: Icon(Icons.manage_accounts),
                          label: Text('Gestão Manual'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Product summary
                Expanded(
                  child: _buildProductSummary(),
                ),
              ],
            ),
    );
  }

  Widget _buildProductSummary() {
    // Count base products and variations
    int baseProductCount = allProducts.where((p) => p.isBaseProduct).length;
    int variationCount = allProducts.where((p) => p.isVariation).length;
    int totalProducts = allProducts.length;

    return Card(
      margin: EdgeInsets.all(16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumo do Sistema',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildSummaryRow('Total de Produtos', totalProducts.toString(), Icons.inventory),
            _buildSummaryRow('Produtos Base', baseProductCount.toString(), Icons.star, Colors.orange),
            _buildSummaryRow('Variações', variationCount.toString(), Icons.link, Colors.blue),
            _buildSummaryRow('Produtos Independentes', (totalProducts - baseProductCount - variationCount).toString(), Icons.category, Colors.grey),
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Produtos Base Detectados:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            ..._getBaseProductList().map((product) => 
              Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.star, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(product.name),
                    Spacer(),
                    Text('(${product.quantity} disponível)', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, IconData icon, [Color? color]) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          SizedBox(width: 12),
          Text(label),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _getBaseProductList() {
    return allProducts.where((p) => p.isBaseProduct).toList();
  }

  void _showAutoDetector() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AutoBaseProductDetector(
          allProducts: allProducts,
          onRelationshipsUpdated: _loadProducts,
        ),
      ),
    );
  }

  void _showManualManager() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BaseProductManagerWidget(
          allProducts: allProducts,
        ),
      ),
    );
  }
} 