// ignore_for_file: file_names
import 'dart:convert';
import 'package:bottom_navigacion_teste/login.dart';
import 'package:bottom_navigacion_teste/mobile/StartedtTar.dart';
import '../bottom_navigation_bar.dart';
import '/mobile/StartedtTar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'TarPage.dart';
import 'FinishedTar.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class SecondScreen extends StatefulWidget {
  const SecondScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  dynamic tar;
  int length = 0;

  getAllProduct(String order) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    dynamic id = prefs.getString('id');
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=12&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
        //print(tar);
      });
      length = int.parse(tar.length.toString());
      return tar;
    }
  }

  int _selectedIndex = 0;

  List<String> order = <String>['N Tarefa', 'Titulo', 'Prioridade'];
  dynamic orderv;


  String _pageTitle = "Tarefas";

  @override
  void initState() {
    getAllProduct(order.toString());
    super.initState();

    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    var initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) async {
        if (payload != null) {
          await onSelectNotification(payload);
        }
      },
    );
  }

  Future<void> _showNotification() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'your_channel_id',
      'your_channel_name',
      channelDescription: 'your_channel_description',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    var platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      0,
      'Isto é um teste',
      'Finalmente',
      platformChannelSpecifics,
      payload: 'item x',
    );
  }

  Future<void> onSelectNotification(String payload) async {
    // handle notification tapped logic here
    print('Notification Tapped: $payload');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Tarefas"),
        automaticallyImplyLeading: false,
        actions: <Widget>[
          Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: GestureDetector(
                onTap: () {
                  _showAlertDialog(context);
                },
                child: const Icon(
                  Icons.exit_to_app,
                  size: 26.0,
                ),
              )),
        ],
      ),

      body:  Expanded(
              child: length == 0
                  ? Center(
                      child: Text("Neste Momento não existem tarefas Inicias"),
                    )
                  : ListView.builder(
                      itemCount: length,
                      itemBuilder: (context, index) => Card(
                            elevation: 2,
                            color: Colors.white,
                            child: Slidable(
                              endActionPane: ActionPane(
                                motion: const ScrollMotion(),
                                children: [
                                  SlidableAction(
                                    onPressed: (context) {
                                      IniTar(tar[index]['idtarefa']);
                                      setState(() {
                                        getAllProduct(order.toString());
                                      });
                                      Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  StartedtTar()));
                                    },
                                    backgroundColor: Colors.green,
                                    icon: Icons.start_sharp,
                                    label: 'Começar',
                                  ),
                                ],
                              ),
                              child: ListTile(
                                leading: Row(
                                  mainAxisSize: MainAxisSize
                                      .min, // Ensure minimal horizontal space
                                  children: [
                                    CircleAvatar(
                                        child: Text(tar[index]['idtarefa'])),
                                  ],
                                ),
                                title: Text(
                                  tar[index]['titulo'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      tar[index]['descrip'].length > 33
                                          ? '${tar[index]['descrip'].substring(0, 30)}. . .'
                                          : tar[index]['descrip'],
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                    Text(
                                      tar[index]['namecliente'],
                                      style: TextStyle(
                                        color: Colors.grey,
                                      ),
                                    ),
                                    SizedBox(
                                      height: 5,
                                    ),
                                  ],
                                ),
                                trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        tar[index]['datam'],
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        tar[index]['tempm']
                                            .toString()
                                            .substring(0, 5),
                                        style: TextStyle(
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ]),
                                onTap: () {
                                  Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => TarPage(
                                      id: tar[index]['idtarefa'],
                                      title: tar[index]['titulo'],
                                      subtitle: tar[index]['descrip'],
                                      nomeC: tar[index]['namecliente'],
                                      dataM: tar[index]['datam'],
                                      horaM: tar[index]['tempm'],
                                      dataF: tar[index]['dateend'],
                                      horaF: tar[index]['tempend'],
                                      dataI: tar[index]['dataini'],
                                      horaI: tar[index]['tempini'],
                                      localR: tar[index]['loci'],
                                      localE: tar[index]['locf'],
                                      pageOrigin: 'secondscreen',
                                      numberOfButtons: 1,
                                      mainButtonCallback: () {
                                        IniTar(tar[index]['idtarefa']);
                                        setState(() {
                                          getAllProduct(order.toString());
                                        });
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (context) =>
                                                  StartedtTar()));

                                        _showNotification();
                                      },
                                      extraButtonCallback: () {},
                                    ),
                                  ));
                                },
                              ),
                            ),
                          ))),
    bottomNavigationBar: CustomBottomNavigationBar(initialIndex: 0),
    );
  }

  void _showAlertDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Pretende fazer Log Out?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                prefs.remove('id');
                // ignore: use_build_context_synchronously
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (BuildContext ctx) => const LoginForm()));
              },
            ),
          ],
        );
      },
    );
  }

  // ignore: non_constant_identifier_names
  void IniTar(dynamic id) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var idu = prefs.getString("id");
    await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=16&idu=$idu&idt=$id'));
    getAllProduct(order.toString());
    setState(() {});
  }

  Future<void> _refreshData() async {
    await getAllProduct(orderv.toString());
  }



}
