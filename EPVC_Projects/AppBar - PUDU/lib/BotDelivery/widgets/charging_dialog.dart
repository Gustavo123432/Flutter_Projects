import 'package:flutter/material.dart';

class ChargingDialog extends StatelessWidget {
  final String chargeStage;
  final int robotPower;
  final VoidCallback onDisconnect;

  const ChargingDialog({
    Key? key,
    required this.chargeStage,
    required this.robotPower,
    required this.onDisconnect,
  }) : super(key: key);

  // Method to determine charging progress widget
  Widget _buildChargingProgressWidget() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 120,
          width: 120,
          child: CircularProgressIndicator(
            value: robotPower / 100,
            strokeWidth: 8,
            backgroundColor: Colors.grey.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(
              robotPower > 80 ? Colors.green :
              robotPower > 50 ? Colors.blue :
              robotPower > 20 ? Colors.orange : Colors.red,
            ),
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              robotPower > 80 ? Icons.battery_full :
              robotPower > 50 ? Icons.battery_5_bar :
              robotPower > 20 ? Icons.battery_3_bar :
              Icons.battery_1_bar,
              size: 40,
              color: robotPower > 80 ? Colors.green : 
                     robotPower > 50 ? Colors.blue :
                     robotPower > 20 ? Colors.orange : Colors.red,
            ),
            Text(
              '$robotPower%',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: robotPower > 80 ? Colors.green : 
                       robotPower > 50 ? Colors.blue :
                       robotPower > 20 ? Colors.orange : Colors.red,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.electrical_services, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(child: Text('Robot em Carregamento')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChargingProgressWidget(),
          SizedBox(height: 20),
          Text(
            chargeStage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          Text(
            robotPower < 20 
              ? 'A bateria está baixa. Deixe carregando até ficar completa.'
              : robotPower < 90
                ? 'O robot está carregando. Por favor, aguarde.'
                : 'O robot está com a bateria completa.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14),
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: onDisconnect,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('SAIR', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
} 