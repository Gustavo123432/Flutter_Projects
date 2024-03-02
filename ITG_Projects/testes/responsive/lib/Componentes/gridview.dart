import 'package:flutter/material.dart';

class GridItem extends StatelessWidget {
  final int number;

  GridItem(this.number);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'titulo: ',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Localização: ',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Data de Início: ',
            style: TextStyle(fontSize: 18),
          ),
          SizedBox(height: 8),
          Text(
            'Data de Término: ',
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}
