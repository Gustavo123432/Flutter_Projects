import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_charts/sparkcharts.dart';
import 'package:flutter/material.dart';

import '../../../Componentes/drawer.dart';
import '../../../Componentes/drawerWidget.dart';
import '../../../Componentes/logout.dart';
import '../../../Paginas/tablet/Secundárias/criarmaterial.dart';
import '../../../Responsive/responsive_Layout.dart';

class TarefasMPage extends StatelessWidget {
  List<String> items = List.generate(50, (index) => 'Item ${index + 1}');
  List<_SalesData> data = [
    _SalesData('Janeiro', 35),
    _SalesData('Feb', 28),
    _SalesData('Mar', 34),
    _SalesData('Apr', 32),
    _SalesData('Maio', 40)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text("Tarefas"),
            VerticalDivider(
              color: Colors.black, // Cor da barra
              thickness: 10, // Espessura da barra
              width: 20, // Largura da barra
              endIndent: 80, // Espaço entre a barra e o próximo widget
              indent: 8, // Espaço entre a barra e o widget anterior
            ),
            TextButton(
              onPressed: () {
                // Ação para o primeiro botão
              },
              child: Text(
                'Por começar',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                // Ação para o segundo botão
              },
              child: Text(
                'Começadas',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                // Ação para o terceiro botão
              },
              child: Text(
                'Terminadas',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                // Ação para o quarto botão
              },
              child: Text(
                'Todas',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
        elevation: 2,
        shadowColor: Theme.of(context).shadowColor,
        actions: [
          GestureDetector(
            onTap: () {
              LogoutDialog();
            },
            child: const Icon(
              Icons.exit_to_app,
              size: 26.0,
            ),
          ),
        ],
      ),
           drawer: DrawerWidget(),
      body: Row(
        children: [
      
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    width: double.maxFinite,
                    height: double.infinity,
                    child: Card(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          return Container(
                            height: 75,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                side: const BorderSide(
                                  color: Color.fromARGB(255, 255, 160, 160),
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(10.0),
                              ),
                              color: Colors.white,
                              elevation: 0,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    child: Text(
                                      items[index],
                                      style: TextStyle(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesData {
  _SalesData(this.year, this.sales);

  final String year;
  final double sales;
}
