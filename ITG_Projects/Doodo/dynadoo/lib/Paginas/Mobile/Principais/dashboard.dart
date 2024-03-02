


import '../../../Componentes/carddash.dart';
import '../../../Componentes/drawerWidget.dart';
import '../../../Componentes/logout.dart';
import 'package:flutter/material.dart';

class DashboardMPage extends StatelessWidget {

  List<String> items = List.generate(50, (index) => 'Item ${index + 1}');
  List<_SalesData> data = [
    _SalesData('Janeiro', 35),
    _SalesData('Feb', 28),
    _SalesData('Mar', 34),
    _SalesData('Apr', 32),
    _SalesData('Maio', 40)
  ];
  String _descricaoItem = '';
  double _materialItem = 0.0;
  double _maoObraItem = 0.0;
  double totalMaterialCost = 0.0;
  double totalLaborCost = 0.0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: Text('Dashboard'),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CardWithCustomBorder(
                            name: 'Evento de Exemplo',
                            location: 'Localização de Exemplo',
                            startDate: '01/01/2024',
                            endDate: '31/01/2024',
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CardWithCustomBorder(
                            name: 'AQui irá mudar ',
                            location: 'para um controlar do lucro ',
                            startDate: '01/01/2024',
                            endDate: '31/01/2024',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 75,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Descrição do Item'),
                        onChanged: (value) {},
                      ),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Custo de Material'),
                        onChanged: (value) {},
                      ),
                    ),
                    SizedBox(
                      width: 15,
                    ),
                    Expanded(
                      child: TextFormField(
                        decoration:
                            InputDecoration(labelText: 'Custo de Mão de Obra'),
                        onChanged: (value) {},
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(Icons.add),
                    ),
                  ],
                ),
                SizedBox(
                  height: 15,
                ),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text("Lista despesas:"),
                    Divider(),
                  ],
                ),
                Expanded(
                  child: Container(
                    width: double.maxFinite,
                    height: 85,
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

  Widget _buildInfoField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
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
