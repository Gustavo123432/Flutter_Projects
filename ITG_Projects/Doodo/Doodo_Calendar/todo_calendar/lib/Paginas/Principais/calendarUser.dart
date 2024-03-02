// ignore_for_file: file_names, library_private_types_in_public_api, camel_case_types, use_key_in_widget_constructors, non_constant_identifier_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:todo_itg/Componentes/drawer.dart';

import '../../login.dart';

class calendarUsersPage extends StatefulWidget {
  @override
  _CalendarUsersPageState createState() => _CalendarUsersPageState();
}

class _CalendarUsersPageState extends State<calendarUsersPage> {
  dynamic tar;
  dynamic Users;
  int length = 0, lengtht = 0;
  final List<Event> _events = [];
  dynamic type = 'all';
  List<String> order = <String>['Numero', 'Nome', 'Tipo de User'];
  dynamic orderv;

  getAllProducts() async {
    dynamic response = await http.get(Uri.parse(
        "https://services.interagit.com/API/api_Calendar.php?query_param=11"));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      lengtht = int.parse(tar.length.toString());
      //print(tar);
      for (int i = 0; i < lengtht; i++) {
        _createEvent(
            int.parse(tar[i]['CodUser']),
            tar[i]['titulo'],
            tar[i]['Descrip'],
            tar[i]['color'],
            DateTime.parse(tar[i]['DataM']),
            DateTime.parse(tar[i]['DateEnd']));
      }
      //return tar;
    }
  }

  getUserList(String order) async {
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=4&order=$order'));
    if (response.statusCode == 200) {
      setState(() {
        Users = jsonDecode(response.body) as List;
      });
      length = int.parse(Users.length.toString());

      return Users;
    }
  }

  @override
  void initState() {
    getUserList('all');
    getAllProducts();
    super.initState();
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
                        builder: (BuildContext ctx) =>  const LoginForm()));
              },
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          useMaterial3: false,
        ),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          SfGlobalLocalizations.delegate
        ],
        supportedLocales: const [
          Locale('pt', ''),
        ],
        locale: const Locale('pt', ''),
        home: Scaffold(
               appBar:  AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Calendários User",
              style: TextStyle(color: Colors.white),
            ),
            SizedBox(
              width: 25,
            ),
          ],
        ),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 20.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    _showAlertDialog(context);
                  },
                  child: const Icon(
                    Icons.exit_to_app,
                    size: 26.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
          drawer: const MyDrawer(),
            body: Container(
          child: SfCalendar(
            view: CalendarView.timelineMonth,
            allowedViews: const <CalendarView>[
              CalendarView.timelineDay,
              CalendarView.timelineMonth,
              CalendarView.timelineWeek,
              CalendarView.timelineWorkWeek,
            ],
            resourceViewSettings: const ResourceViewSettings(
              // Other settings...
              size: 135,
              showAvatar: true,
            ),
            cellEndPadding: 15,
            dataSource: _getCalendarDataSource(),
            showDatePickerButton: true,
            showNavigationArrow: true,
            initialSelectedDate: DateTime.now(),
            timeSlotViewSettings: const TimeSlotViewSettings(
              timeFormat: "HH:mm",
            ),
          ),
        )));
  }

  void _createEvent(int id, String subject, String descrip, String color,
      DateTime start, DateTime end) {
    //color = '#$color';
    int cor = 0xFF000000;
    try {
      cor = int.parse(color, radix: 16) + 0xFF000000;
    } catch (e) {
      //print("Erro na cor");
    }
    //print(cor);
    final newEvent = Event(
      id: id,
      subject: subject,
      content: descrip,
      color: Color(cor),
      startTime: start,
      endTime: end,
    );
    setState(() {
      _events.add(newEvent);
    });
  }

  DataSource _getCalendarDataSource() {
    List<Appointment> appointments = [];

    for (int i = 0; i < _events.length; i++) {
      appointments.add(Appointment(
        startTime: _events[i].startTime,
        endTime: _events[i].endTime,
        subject: _events[i].subject,
        color: _events[i].color,
        notes: _events[i].content,
        isAllDay: false,
        resourceIds: <Object>[_events[i].id.toString()],
      ));
    }

    List<CalendarResource> resources = <CalendarResource>[];
    for (int i = 0; i < length; i++) {
      if (Users[i]['UImage'].toString() != "null") {
        List<int> bytes = base64.decode(Users[i]['UImage'].toString());

        resources.add(CalendarResource(
          displayName: Users[i]['Name'],
          image: MemoryImage(Uint8List.fromList(bytes)),
          id: Users[i]['IdUser'],
          color: (Color(int.parse(Users[i]['Color'], radix: 16) + 0xFF000000)
              .withOpacity(1.0)),
        ));
      } else {
        resources.add(CalendarResource(
          displayName: Users[i]['Name'],
          id: Users[i]['IdUser'],
          color: (Color(int.parse(Users[i]['Color'], radix: 16) + 0xFF000000)
              .withOpacity(1.0)),
        ));
      }
    }

    return DataSource(appointments, resources);
  }
}

class DataSource extends CalendarDataSource {
  DataSource(List<Appointment> source, List<CalendarResource> resourceColl) {
    appointments = source;
    resources = resourceColl;
  }
}

class Event {
  final int id;
  final String subject;
  final String content;
  final Color color;
  final DateTime startTime;
  final DateTime endTime;

  Event({
    required this.id,
    required this.subject,
    required this.content,
    required this.color,
    required this.startTime,
    required this.endTime,
  });
}
