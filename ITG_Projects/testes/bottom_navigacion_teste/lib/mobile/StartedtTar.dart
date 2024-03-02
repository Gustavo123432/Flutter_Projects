import 'dart:convert';
import 'package:bottom_navigacion_teste/mobile/FinishedTar.dart';

import '../bottom_navigation_bar.dart';
import '/mobile/secondScreen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class StartedtTar extends StatefulWidget {
  @override
  _StartedtTarState createState() => _StartedtTarState();
}

class _StartedtTarState extends State<StartedtTar> {
  dynamic tar;
  int length = 0;

  getProduct() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=13&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());

      return tar;
    }
  }

/*  void IniTar(dynamic id) async {
    await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=5&id=$id'));
    getAllProduct();
    setState(() {});
  }

  void CancelTar(dynamic id) async {
    await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=6&id=$id'));
    getAllProduct();
    setState(() {});
  }*/

  void EndTar(dynamic id) async {
    await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=18&id=$id'));
    getProduct();
    setState(() {});
  }

  /*bool showAdditionalText = false;
  String additionalText = '';
    void determineAdditionalText() {
    if (widget.pageOrigin == 'secondscreen') {
      setState(() {
        showAdditionalText = true;
        additionalText = 'Texto exclusivo da Página SecondScreen';
      });
    } else if (widget.pageOrigin == 'startedTar') {
      setState(() {
        showAdditionalText = true;
        additionalText = 'Texto exclusivo da Página StartedTar';
      });
    }
  }*/

  @override
  void initState() {
    getProduct();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
             appBar: AppBar(
        title: Text("Em Progresso"),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                //  _showAlertDialog(context);
                },
                child: const Icon(
                  Icons.exit_to_app,
                  size: 26.0,
                ),
              )),
        ],
      ),
      backgroundColor: Colors.blueGrey[50],
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: length == 0
            ? Center(
                child: Text("Neste Momento não existem tarefas Terminadas"),
              )
            : Center(
                child: Card(
                  elevation: 4,
                  child: Container(
                    color: Colors.white,
                    width: 500,
                    height: 500,
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 35,
                              backgroundColor: Colors.blue,
                              child: Text(
                                tar[0]['idtarefa'],
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                ),
                              ),
                            ),
                            const SizedBox(
                              width: 8,
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Titulo",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  tar[0]['titulo'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Obeservações",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tar[0]['descrip'],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 25),
                        Row(
                          children: [
                            Text(
                              "Nome Cliente: ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              tar[0]['namecliente'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              "Local de Recolha: ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              tar[0]['loci'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Text(
                              "Local de Entrega: ",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              tar[0]['locf'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  "Data Marcada",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  tar[0]['datam'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 12),
                                const Text(
                                  "Hora Marcada",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  tar[0]['tempm'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  "Data Iniciada",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  tar[0]['dataini'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const SizedBox(height: 12),
                                const Text(
                                  "Hora Iniciada",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  tar[0]['tempini'],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Center(
                          child: ElevatedButton(
                            onPressed: () {
                              EndTar(tar[0]['idtarefa']);
                              Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  FinishedTar()));
                            },
                            child: Text('Terminar'),
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ),
      ),
      bottomNavigationBar: CustomBottomNavigationBar(initialIndex: 1),
    );
  }
}
