import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// ignore: must_be_immutable
class finishedTarDetails extends StatefulWidget {
  dynamic id,
      title,
      subtitle,
      datainicio,
      datafim,
      horainicio,
      horafim,
      coduser,
      tipoTarefa,
      prioo;

  int numberOfButtons;
  dynamic det;
  final void Function() mainButtonCallback;
  final void Function() extraButtonCallback;
  finishedTarDetails({
    super.key,
    required this.id,
    this.title,
    this.subtitle,
    this.datainicio,
    this.datafim,
    this.horainicio,
    this.horafim,
    this.coduser,
    this.tipoTarefa,
    this.prioo,
    this.numberOfButtons = 1,
    required this.mainButtonCallback,
    this.extraButtonCallback = _defaultExtraButtonCallback,
  });

  static void _defaultExtraButtonCallback() {
    // Implemente uma ação padrão para o botão extra, ou deixe vazio
  }

  @override
  // ignore: library_private_types_in_public_api
  _finishedTarDetailsState createState() => _finishedTarDetailsState();
}

// ignore: camel_case_types
class _finishedTarDetailsState extends State<finishedTarDetails> {
  dynamic user, nome = 'Nome';
  late String texReopen;
  getUser(dynamic id) async {
    dynamic response = await http.get(Uri.parse(
        'http://192.168.1.159:8080/ToDo/api_To-Do.php?query_param=13&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        user = json.decode(response.body);
      });
      nome = user[0]['Name'];
      return user;
    }
  }

  _verifyPrio() {
    print(widget.prioo);
  }

  final TextEditingController ObController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarefa'),
      ),
      backgroundColor: Colors.blueGrey[50],
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 3,
                child: Container(
                  color: Colors.white,
                  width: 500,
                  height: 500,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Wrap the CircleAvatar and Title in a Row
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.blue,
                            child: Text(
                              widget.id,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          const SizedBox(
                              width:
                                  8), // Add spacing between CircleAvatar and Title
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
                      const SizedBox(
                        height: 8,
                      ),
                      const Text(
                        "Descrição:",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      Text(
                        widget.subtitle,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),
                      const Divider(
                        height: 40,
                      ),
                      Row(children: [
                        const Text(
                          "Hora Inicio:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                        const SizedBox(width: 12),
                        const Text(
                          "Hora Fim:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.horafim != null && widget.horafim != "null"
                              ? widget.horafim
                              : "Sem hora de fim",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Text(
                            "Data Inicio:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
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
                          const SizedBox(width: 12),
                          const Text(
                            "Data Fim:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
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

                      const SizedBox(
                        height: 8,
                      ),
                      // ignore: prefer_interpolation_to_compose_strings
                      Text("Atribuida a :" + nome),
                      Text(
                        widget.prioo == '0'
                            ? 'Normal'
                            : widget.prioo == '1'
                                ? 'Prioritário'
                                : 'Urgente',
                      ),

                      Column(
                        children: <Widget>[
                          if (widget.numberOfButtons == 1)
                            ElevatedButton(
                              onPressed: () {
                                widget.mainButtonCallback();
                              },
                              child: Text(
                                widget.tipoTarefa == 0
                                    ? 'Iniciar Tarefa'
                                    : widget.tipoTarefa == 1
                                        ? 'Reabrir'
                                        : 'Error 44',
                              ),
                            ),
                          if (widget.numberOfButtons == 2)
                            Column(
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    widget.mainButtonCallback();
                                  },
                                  child: Text('Confirmar'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    widget.extraButtonCallback();
                                  },
                                  child: Text('Cancelar'),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    getUser(widget.coduser);
    _verifyPrio();
    super.initState();
  }
}
