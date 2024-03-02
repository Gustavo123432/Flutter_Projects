import 'package:flutter/material.dart';
import 'package:help_center_itgdoodo/fornewupdate/createEmpresa.dart';
import 'package:help_center_itgdoodo/fornewupdate/detailsEmpresa.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:collection/collection.dart';

class PricePoints {
  final double x;
  final double y;
  PricePoints({required this.x, required this.y});
}

List<PricePoints> get pricepoints {
  final data = <double>[2, 4, 6, 11, 15];
  return data
      .mapIndexed(
          (index, element) => PricePoints(x: index.toDouble(), y: element))
      .toList();
}

List<PricePoints> get pricepointss {
  final data2 = <double>[3, 6, 8, 15];
  return data2
      .mapIndexed(
          (index, element) => PricePoints(x: index.toDouble(), y: element))
      .toList();
}

List<PricePoints> get pricepointsss {
  final data3 = <double>[2, 4, 6, 8, 15];
  return data3
      .mapIndexed(
          (index, element) => PricePoints(x: index.toDouble(), y: element))
      .toList();
}

class empresadPage extends StatefulWidget {
  @override
  _empresadPage createState() => _empresadPage();
}

class _empresadPage extends State<empresadPage> {
  dynamic t1, t2, t3;
  dynamic l1 = 0, l2 = 0, l3 = 0;
  late String tex;

  dynamic orderv;

  void getTickets() async {
    dynamic tar;
    dynamic response1 = await http.get(Uri.parse(
        "http://192.168.1.159:8080/Todo/api_To-Do.php?query_param=20"));

    if (response1.statusCode == 200) {
      setState(() {
        t2 = json.decode(response1.body);
        l2 = int.parse(t2.length.toString());
      });
    }

    print(int.parse(t2.length.toString()));
    return tar;
  }

  @override
  void initState() {
    getTickets();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dividindo a Tela em 4 Partes'),
      ),
      body: Row(
        children: <Widget>[
          // Duas partes menores à esquerda
          Expanded(
            flex: 1,
            child: Column(children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => empresadPage(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 5,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/logo_empresa.png', // Substitua pelo caminho da imagem do logotipo
                            height: 100,
                          ),
                        ),
                        const Divider(
                          color: Colors.grey,
                        ),
                        const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: Text(
                            'Nome Empresa',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Text(
                          'Equipa Responsável',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Tickets em Aberto: XX', // Substitua XX pela quantidade real de tickets em aberto
                        ),
                        const Text(
                          'Nome Responsável: Nome do Responsável',
                        ),
                        const Text(
                          'Contato Responsável: contato@empresa.com', // Substitua pelo contato real
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 400,
                child: Container(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: l2 > 0 ? l2 : 1,
                    // Replace with the actual number of tasks
                    itemBuilder: (context, index) {
                      return l2 > 0
                          ? Container(
                              height: 75,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: t2[index]['Prioridade'] == '2'
                                        ? Colors.red
                                        : t2[index]['Prioridade'] == '1'
                                            ? Colors.yellow
                                            : Color.fromARGB(
                                                255, 170, 170, 170),
                                    width: 3, //<-- SEE HERE
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                color: Colors.white,
                                elevation: 10,
                                child: ListTile(
                                  title: Text(
                                    l2 > 0 ? t2[index]['Titulo'] : 'Nada',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      l2 > 0 ? t2[index]['Descricao'] : 'Nada'),
                                  onTap: () {},
                                ),
                              ),
                            )
                          : Container(
                              height: 75,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: const BorderSide(
                                    color: Color.fromARGB(255, 255, 160, 160),
                                    width: 3, //<-- SEE HERE
                                  ),
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                color: Colors.white,
                                elevation: 0,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Container(
                                      child: Text("Não há Tickets Iniciados",
                                          style: TextStyle(
                                              //fontWeight: FontWeight.bold
                                              )),
                                    )
                                  ],
                                ),
                              ),
                            );
                    },
                  ),
                ),
              ),
            ]),
          ),
          // Duas partes à direita
          Expanded(
            flex: 2,
            child: Container(
              child: GestureDetector(
                onTap: () {
                  // Adicione ação de toque, se necessário
                },
                child: Card(
                  child: Container(
                      height: 815,
                      padding: const EdgeInsets.all(20),
                      child: Container(
                        child: LineChartWidget(
                            pricepoints, pricepointss, pricepointsss),
                      )),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

class CardWithHoverEffect extends StatefulWidget {
  final Widget child;

  CardWithHoverEffect({required this.child});

  @override
  _CardWithHoverEffectState createState() => _CardWithHoverEffectState();
}

class _CardWithHoverEffectState extends State<CardWithHoverEffect> {
  bool isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: Card(
        elevation: isHovered ? 11.0 : 4.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: widget.child,
      ),
    );
  }

  void _onHover(bool hovering) {
    setState(() {
      isHovered = hovering;
    });
  }
}

class LineChartWidget extends StatelessWidget {
  final List<PricePoints> points, pointss, pointsss;

  const LineChartWidget(this.points, this.pointss, this.pointsss, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(235),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: pricepoints
                  .map((point) => FlSpot(point.x, point.y))
                  .toList(), // Gere 10 pontos de dados
              isCurved: true,
              color: Colors.yellow, // Use 'color' para definir a cor da linha
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: pricepointss
                  .map((point) => FlSpot(point.x, point.y))
                  .toList(), // Gere 10 pontos de dados
              isCurved: true,
              color: Color.fromARGB(
                  255, 255, 0, 0), // Use 'color' para definir a cor da linha
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
            LineChartBarData(
              spots: pricepointsss
                  .map((point) => FlSpot(point.x, point.y))
                  .toList(), // Gere 10 pontos de dados
              isCurved: true,
              color: Color.fromARGB(
                  255, 136, 0, 255), // Use 'color' para definir a cor da linha
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: false),
            ),
          ],
        ),
      ),
    );
  }
}
