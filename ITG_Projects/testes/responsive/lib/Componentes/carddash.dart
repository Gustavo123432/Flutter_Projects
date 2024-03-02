import 'package:flutter/material.dart';

class CardWithCustomBorder extends StatelessWidget {
  final String name;
  final String location;
  final String startDate;
  final String endDate;

  CardWithCustomBorder({
    required this.name,
    required this.location,
    required this.startDate,
    required this.endDate,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          padding: EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8.0),
            border: Border(
              top: BorderSide(
                color: Colors.blue, // Cor da borda superior
                width: 15.0, // Largura da borda superior
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nome: $name',
                style: TextStyle(fontSize: 20.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Localização: $location',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Data de Início: $startDate',
                style: TextStyle(fontSize: 16.0),
              ),
              SizedBox(height: 8.0),
              Text(
                'Data de Término: $endDate',
                style: TextStyle(fontSize: 16.0),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
