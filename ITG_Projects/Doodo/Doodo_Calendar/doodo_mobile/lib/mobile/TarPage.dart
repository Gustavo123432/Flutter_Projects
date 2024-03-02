import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class TarPage extends StatefulWidget {
  dynamic id,
      title,
      subtitle,
      nomeC,
      dataM,
      horaM,
      dataF,
      horaF,
      dataI,
      horaI,
      localR,
      localE,
      coduser;
  final String pageOrigin;

  int numberOfButtons;
  final void Function() mainButtonCallback;
  final void Function() extraButtonCallback;

  TarPage({
    Key? key,
    required this.id,
    this.title,
    this.subtitle,
    this.nomeC,
    this.dataM,
    this.horaM,
    this.dataF,
    this.horaF,
    this.dataI,
    this.horaI,
    this.localR,
    this.localE,
    this.coduser,
    required this.pageOrigin,
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
        'https://services.interagit.com/API/api_Calendar.php?query_param=12&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  void IniTar(dynamic id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idu = prefs.getString("id");
    await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=16&idu=$idu&idt=$id'));
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

  bool showAdditionalText = false;

  void determineAdditionalText() {
    if (widget.pageOrigin == 'secondscreen') {
      setState(() {
        showAdditionalText = false;
      });
    } else if (widget.pageOrigin == 'finishedTar') {
      setState(() {
        showAdditionalText = true;
      });
    }
  }

  @override
  void initState() {
    getAllProduct();
    determineAdditionalText();
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
                    "Obeservações",
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
                        widget.nomeC,
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
                        widget.localR,
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
                        widget.localE,
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
                            widget.dataM,
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
                            widget.horaM,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Visibility(
                      visible: showAdditionalText,
                      child: Column(
                        children: [
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
                                  if (widget.dataI != null)
                                    Text(
                                      widget.dataI,
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
                                  if (widget.horaI != null)
                                    Text(
                                      widget.horaI,
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
                                  const Text(
                                    "Data Finalizada",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (widget.dataF != null)
                                    Text(
                                      widget.dataF,
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
                                    "Hora Finalizada",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  if (widget.horaF != null)
                                    Text(
                                      widget.horaF,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      )),
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
