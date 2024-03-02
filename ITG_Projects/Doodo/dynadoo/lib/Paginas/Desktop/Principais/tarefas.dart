import 'package:flutter/material.dart';
import '../../../Componentes/drawerWidget.dart';
import '../../../Componentes/logout.dart';


// ignore: must_be_immutable
class TarefasDPage extends StatelessWidget {
  List<String> items = List.generate(50, (index) => 'Item ${index + 1}');
  // ignore: library_private_types_in_public_api
  List<_SalesData> data = [
    _SalesData('Janeiro', 35),
    _SalesData('Feb', 28),
    _SalesData('Mar', 34),
    _SalesData('Apr', 32),
    _SalesData('Maio', 40)
  ];

  TarefasDPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            const Text("Tarefas"),
            const VerticalDivider(
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
              child: const Text(
                'Por começar',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                // Ação para o segundo botão
              },
              child: const Text(
                'Começadas',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                // Ação para o terceiro botão
              },
              child: const Text(
                'Terminadas',
                style: TextStyle(color: Colors.black),
              ),
            ),
            TextButton(
              onPressed: () {
                // Ação para o quarto botão
              },
              child: const Text(
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
      body: Row(
        children: [
      DrawerWidget(),
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
                                      style: const TextStyle(),
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
