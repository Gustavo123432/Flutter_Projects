import 'package:flutter/material.dart';
import 'package:appbar_epvc/Aluno/home.dart';

class OrderDeclinedSaldoPage extends StatelessWidget {
  final double amount;
  final String? reason;

  const OrderDeclinedSaldoPage({
    Key? key,
    required this.amount,
    required this.reason,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Prevent navigating back
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Carregamento Recusado', style: TextStyle(color: Colors.black),),
          backgroundColor: Colors.white,
          automaticallyImplyLeading: false,
        ),
        body: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 25.0),
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
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.red, width: 2),
                  ),
                  padding: EdgeInsets.all(25),
                  margin: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: Colors.red,
                        size: 80,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'O teu pedido foi recusado',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 10),
                      if (reason != null && reason!.isNotEmpty)
                        Text(
                          'Motivo: ${reason}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      if (reason == null || reason!.isEmpty)
                        Text(
                          'O pagamento não foi processado.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[800],
                          ),
                        ),
                      SizedBox(height: 20),
                      Text(
                        'Valor: ${amount.toStringAsFixed(2).replaceAll('.', ',')}€',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => HomeAlunoMain()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    padding:
                        EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                    backgroundColor: Colors.red[800],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Voltar ao Início',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
