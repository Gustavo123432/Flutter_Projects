import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TransactionDetailsPage extends StatefulWidget {
  @override
  _TransactionDetailsPageState createState() => _TransactionDetailsPageState();
}

class _TransactionDetailsPageState extends State<TransactionDetailsPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _fetchTransactions();
      setState(() {
        _transactions = transactions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar movimentos')),
      );
    }
  }

  Future<List<Map<String, dynamic>>> _fetchTransactions() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? user = prefs.getString("username");

      if (user == null) {
        throw Exception('No user logged in');
      }

      final response = await http.get(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=34&user=${user}'),
 
      );

      if (response.statusCode == 200) {
        List<dynamic> transactions = json.decode(response.body);
        return transactions.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load transactions');
      }
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
      return Scaffold(
      appBar: AppBar(
          title: Text('Movimentos'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () async {
                Navigator.pop(context);
              
            },
          ),
        ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
              ? Center(
                  child: Text(
                    'Sem movimentos recentes',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTransactions,
                  child: ListView.builder(
                    padding: EdgeInsets.all(16),
                    itemCount: _transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = _transactions[index];
                      final isCredit = transaction['Tipo'].toString() == '1';
                      final amount = double.tryParse(transaction['Valor'].toString()) ?? 0.0;
                      DateTime? date;
                      try {
                         date = DateTime.parse(transaction['Data'].toString());
                      } catch (e) {
                          print('Error parsing date for transaction: ${transaction['Id']}');
                          date = DateTime.now();
                      }

                      final formattedDate = date != null ? '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}' : 'Data inválida';
                      
                      return Card(
                        margin: EdgeInsets.only(bottom: 8),
                        color: transaction['Tipo'].toString() == '2' ? Colors.red[50] : null,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isCredit ? Colors.green[100] : Colors.red[100],
                            child: Icon(
                              isCredit ? Icons.add : Icons.remove,
                              color: isCredit ? Colors.green : Colors.red,
                            ),
                          ),
                          title: Text(
                            transaction['Descricao'] ?? (isCredit ? 'Carregamento' : 'Compra'),
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              color: transaction['Tipo'].toString() == '2' ? Colors.red[900] : null,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                formattedDate,
                                style: TextStyle(
                                  color: transaction['Tipo'].toString() == '2' ? Colors.red[700] : null,
                                ),
                              ),
                              if (transaction['local'] != null)
                                Text(
                                  'Local: ${transaction['local']}',
                                  style: TextStyle(
                                    color: transaction['Tipo'].toString() == '2' ? Colors.red[700] : Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          trailing: Text(
                            '${isCredit ? '+' : '-'}${amount.toStringAsFixed(2)}€',
                            style: TextStyle(
                              color: transaction['Tipo'].toString() == '2' ? Colors.red[900] : (isCredit ? Colors.green : Colors.red),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
