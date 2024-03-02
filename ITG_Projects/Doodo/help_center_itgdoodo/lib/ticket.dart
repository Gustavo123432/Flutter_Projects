// ignore_for_file: file_names

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ticketsPage extends StatefulWidget {
  @override
  _TicketsPageState createState() => _TicketsPageState();
}

class _TicketsPageState extends State<ticketsPage> {
  final TextEditingController ReopenController = TextEditingController();
  dynamic t1, t2, t3;
  dynamic l1 = 0, l2 = 0, l3 = 0;
  late String tex;

  dynamic orderv;

  void getTickets() async {
    dynamic tar;
    dynamic response0 = await http.get(Uri.parse(
        "http://192.168.1.159:8080/Todo/api_To-Do.php?query_param=19&type=0"));
    dynamic response1 = await http.get(Uri.parse(
        "http://192.168.1.159:8080/Todo/api_To-Do.php?query_param=19&type=1"));
    dynamic response2 = await http.get(Uri.parse(
        "http://192.168.1.159:8080/Todo/api_To-Do.php?query_param=19&type=2"));
    if (response0.statusCode == 200) {
      setState(() {
        t1 = json.decode(response0.body);
        l1 = int.parse(t1.length.toString());
      });

      if (response1.statusCode == 200) {
        setState(() {
          t2 = json.decode(response1.body);
          l2 = int.parse(t2.length.toString());
        });
      }
      if (response2.statusCode == 200) {
        setState(() {
          t3 = json.decode(response2.body);
          l3 = int.parse(t3.length.toString());
        });
      }

      print(int.parse(t2.length.toString()));
      return tar;
    }
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
        title: const Text('Tickets'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                SizedBox(
                  height: 20,
                ),
                const Text("Tickets",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(
                  height: 20,
                ),
                Container(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: l1 > 0 ? l1 : 1,
                    // Replace with the actual number of tasks
                    itemBuilder: (context, index) {
                      return l1 > 0
                          ? Container(
                              height: 75,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: t1[index]['Prioridade'] == '2'
                                        ? Colors.red
                                        : t1[index]['Prioridade'] == '1'
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
                                    l1 > 0 ? t1[index]['Titulo'] : 'Nada',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      l1 > 0 ? t1[index]['Descricao'] : 'Nada'),
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
                                      child: Text("Não há Tickets Começados",
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
                SizedBox(
                  height: 20,
                ),
                Text("Tickets em Andamento",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 20,
                ),
                Container(
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
                                    l2 > 0 ? t1[index]['Titulo'] : 'Nada',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      l2 > 0 ? t1[index]['Descricao'] : 'Nada'),
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
                SizedBox(
                  height: 20,
                ),
                Text("Ticket´s Finalizados",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(
                  height: 20,
                ),
                Container(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: l3 > 0 ? l3 : 1,
                    // Replace with the actual number of tasks
                    itemBuilder: (context, index) {
                      return l3 > 0
                          ? Container(
                              height: 75,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: BorderSide(
                                    color: t3[index]['Prioridade'] == '2'
                                        ? Colors.red
                                        : t3[index]['Prioridade'] == '1'
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
                                    l3 > 0 ? t3[index]['Titulo'] : 'Nada',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                      l3 > 0 ? t1[index]['Descricao'] : 'Nada'),
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
                                      child: Text("Não há Tickets Finalizados",
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
