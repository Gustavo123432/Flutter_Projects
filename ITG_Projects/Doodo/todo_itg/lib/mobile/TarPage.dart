import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class TarPage extends StatefulWidget {
  dynamic id,
      title,
      subtitle,
      datainicio,
      datafim,
      horainicio,
      horafim,
      coduser,
      prioo;
  int numberOfButtons;
  dynamic det;
  final void Function() mainButtonCallback;
  final void Function() extraButtonCallback;

  TarPage({
    Key? key,
    required this.id,
    this.title,
    this.subtitle,
    this.datainicio,
    this.datafim,
    this.horainicio,
    this.horafim,
    this.det,
    this.coduser,
    this.prioo,
    this.numberOfButtons = 1,
    required this.mainButtonCallback,
    this.extraButtonCallback = _defaultExtraButtonCallback,
  });

  static void _defaultExtraButtonCallback() {
    // Implemente uma ação padrão para o botão extra, ou deixe vazio
  }

  @override
  _TarPageState createState() => _TarPageState();
}

class _TarPageState extends State<TarPage> {
  dynamic tar;
  int length = 0;

  getAllProduct() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=2&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  void IniTar(dynamic id) async {
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
  }

  void EndTar(dynamic id, String det) async {
    await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=7&det=$det&id=$id'));
    getAllProduct();
    setState(() {});
  }

  @override
  void initState() {
    getAllProduct();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tarefa'),
      ),
      backgroundColor: Colors.blueGrey[50],
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Card(
            elevation: 4,
            child: Container(
              color: Colors.white,
              width: 500,
              height: 450,
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
                          widget.id.toString(),
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
                            widget.title,
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
                    "Descrição",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(
                    height: 50,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            "Hora Inicio",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.horainicio != null &&
                                    widget.horainicio != "null"
                                ? widget.horainicio
                                : "Sem hora de inicio",
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
                            "Hora Fim",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.horafim != null && widget.horafim != "null"
                                ? widget.horafim
                                : "Sem hora de fim",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 12),
                          const Text(
                            "Data Inicio",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.datainicio != null &&
                                    widget.datainicio != "null"
                                ? widget.datainicio
                                : "Sem data de inicio",
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
                            "Data Fim",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.datafim != null && widget.datafim != "null"
                                ? widget.datafim
                                : "Sem data de fim",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Column(
                    children: <Widget>[
                      if (widget.numberOfButtons == 1)
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  widget.mainButtonCallback();
                                },
                                child: Text('Começar'),
                              ),
                            ],
                          ),
                        ),
                      if (widget.numberOfButtons == 2)
                        Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  widget.mainButtonCallback();
                                },
                                child: Text('Terminar'),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  widget.extraButtonCallback();
                                },
                                child: Text('Cancelar'),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
