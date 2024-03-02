// ignore_for_file: camel_case_types, use_key_in_widget_constructors, file_names, non_constant_identifier_names, no_leading_underscores_for_local_identifiers, deprecated_member_use
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:todo_itg/Componentes/drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../login.dart';
import '../Secundarias/Tarefas/createTar.dart';

class defaultTar extends StatefulWidget {
  @override
  State<defaultTar> createState() => defaultTarState();
}

class defaultTarState extends State<defaultTar> {
  final CalendarController _calendarController = CalendarController();
  final CalendarController _calendarController2 = CalendarController();
  final CalendarController _calendarController3 = CalendarController();
  final List<Event> _events = [];
  final TextEditingController _controller = TextEditingController();

  List Users = [];
  dynamic tar;
  dynamic length;
  bool isCheckedAdditional = false; 

  getAllProducts() async {
    dynamic response = await http.get(Uri.parse(
        "https://services.interagit.com/API/api_Calendar.php?query_param=11"));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());

      for (int i = 0; i < length; i++) {
        _createEvent(
            int.parse(tar[i]['idtarefa']),
            tar[i]['titulo'],
            tar[i]['Descrip'],
            tar[i]['color'],
            tar[i]['LocI'],
            tar[i]['LocF'],
            tar[i]['NameCliente'],
            tar[i]['Name'],
            DateTime.parse(tar[i]['DataM'] + ' ' + tar[i]['TempM']),
            DateTime.parse(tar[i]['DateEnd'] + ' ' + tar[i]['TempEnd']),
            int.parse(tar[i]['CodUser']));
      }
      
    }
  }

  Dnd(String DateM, String TempM, String DateEnd, String TempEnd,
      int Id) async {

    dynamic response = await http.get(Uri.parse(
        "https://services.interagit.com/API/api_Calendar.php?query_param=17&id=$Id&dm=$DateM&tm=$TempM&de=$DateEnd&te=$TempEnd;"));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
        getAllProducts();
      });
    }
  }

  @override
  void initState() {
    getAllProducts();
    super.initState();
    _controller.text = "0";
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
      ),
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
        appBar: AppBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Calendário",
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
        body: Row(
          children: [
            // Coluna para os dois primeiros calendários
            Card(
              elevation: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    child: SizedBox(
                      height: 350,
                      width: 290, // Defina a altura desejada
                      child: SfCalendar(
                          view: CalendarView.month,
                          controller: _calendarController2,
                          onSelectionChanged: wtf2,
                          //showNavigationArrow: true,
                          dataSource: _getCalendarDataSource(),
                          initialSelectedDate: DateTime.now(),
                          monthViewSettings: const MonthViewSettings(
                              showTrailingAndLeadingDates: false,
                              appointmentDisplayMode:
                                  MonthAppointmentDisplayMode.appointment)),
                    ),
                  ),
                  Container(
                    height: 1,
                    width: 270,
                    color: Colors.black,
                    margin: const EdgeInsets.symmetric(vertical: 10),
                  ),
                  Expanded(
                    child: SizedBox(
                      height: 350,
                      width: 290, // Defina a altura desejada
                      child: SfCalendar(
                          view: CalendarView.month,
                          controller: _calendarController3,
                          onSelectionChanged: wtf2,
                          //showNavigationArrow: true,
                          initialDisplayDate: DateTime.now().month > 9
                              ? DateTime.parse(
                                  "${DateTime.now().year}-${DateTime.now().month + 1}-01")
                              : DateTime.parse(
                                  "${DateTime.now().year}-0${DateTime.now().month + 1}-01"),
                          monthViewSettings: const MonthViewSettings(
                              showTrailingAndLeadingDates: false,
                              appointmentDisplayMode:
                                  MonthAppointmentDisplayMode.appointment)),
                    ),
                  ),
                ],
              ),
            ),

            Flexible(
              child: SfCalendar(
                view: CalendarView.week,
                controller: _calendarController,
                allowedViews: const <CalendarView>[
                  CalendarView.day,
                  CalendarView.week,
                  CalendarView.workWeek,
                  CalendarView.month,
                ],
                onSelectionChanged: wtf,
                showDatePickerButton: true,
                allowDragAndDrop: true,
                showNavigationArrow: true,
                dragAndDropSettings:
                    const DragAndDropSettings(allowNavigation: true),
                dataSource: _getCalendarDataSource(),
                initialSelectedDate: DateTime.now(),
                onDragEnd: dragEnd,
                appointmentBuilder:
                    (BuildContext context, CalendarAppointmentDetails details) {
                  String subject = details.appointments.first.subject;
                  String notes = details.appointments.first.notes ?? '';
                  String startTime = details.appointments.first.startTime
                          .toString()
                          .substring(0, 10) ??
                      '';
                  String endTime = details.appointments.first.endTime
                          .toString()
                          .substring(11) ??
                      '';

                  return Container(
                    color: details.appointments.first.color,
                    padding: const EdgeInsets.all(8.0),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Text(subject,
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(notes),
                        Text(startTime),
                        Text(endTime),
                      ],
                    ),
                  );
                },
                selectionDecoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                      color: const Color.fromARGB(255, 0, 140, 255), width: 2),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  shape: BoxShape.rectangle,
                ),
                onTap: (CalendarTapDetails details) {
                  if (details.targetElement == CalendarElement.appointment) {
                    _showAppointmentDetails(context, details.appointments![0]);
                  }
                },
                monthViewSettings: const MonthViewSettings(
                    showAgenda: true,
                    agendaItemHeight: 100,
                    dayFormat: 'EEE',
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.appointment),
                timeSlotViewSettings: const TimeSlotViewSettings(
                  timeFormat: "HH:mm",
                ),
              ),
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateTar(),
                ));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }








void _createEvent(
    int id,
    String subject,
    String descrip,
    String color,
    String LocI,
    String LocF,
    String NameMot,
    String namecliente,
    DateTime start,
    DateTime end,
    int uid,
  ) {
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
        IdUser: uid,
        locF: LocF,
        locI: LocI,
        nameMot: NameMot,
        nameCliente: namecliente);
    setState(() {
      _events.add(newEvent);
    });
  }

  void wtf(CalendarSelectionDetails aaaa) {
    _calendarController2.selectedDate = aaaa.date;
    int mes = int.parse(_calendarController2.displayDate!.month.toString()) + 1;
    //print(mes);
    if (aaaa.date?.month.toInt() == mes) {
      _calendarController3.selectedDate = aaaa.date;
    } else {
      _calendarController3.selectedDate = null;
    }
  }

  void wtf2(CalendarSelectionDetails aaaa) {
    _calendarController.selectedDate = aaaa.date;
    _calendarController.displayDate = aaaa.date;
  }

  _AppointmentDataSource _getCalendarDataSource() {
    return _AppointmentDataSource(_events);
  }

  void dragEnd(AppointmentDragEndDetails appointmentDragEndDetails) {
    dynamic appointment = appointmentDragEndDetails.appointment!;
    Dnd(
      appointment.startTime.toString().substring(0, 10),
      appointment.startTime.toString().substring(11),
      appointment.endTime.toString().substring(0, 10),
      appointment.endTime.toString().substring(11),
      appointment.id,
    );
  }
}

_showAppointmentDetails(BuildContext context, Appointment appointment) {
    Object nameCliente = appointment.resourceIds![0];
    Object locF = appointment.resourceIds![1];
    Object locI = appointment.resourceIds![2];
    Object nameMot = appointment.resourceIds![3];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Detalhes Tarefas'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Título: ${appointment.subject ?? ''}'),
              Text('Nome Cliente: $nameCliente'),
              Text('Local Início: $locI'),
              Text('Local Fim: $locF'),
              Text('Nome Motorista: $nameMot'),
              Text('Hora Marcada: ${appointment.startTime.toString().substring(0, 10) ?? ''}'),
              Text('Data Marcada: ${appointment.endTime.toString().substring(11) ?? ''}'),
            
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  


class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Event> source) {
    appointments = source.map((event) {
      return Appointment(
        id: event.id,
        subject: event.subject,
        resourceIds: [
          event.nameCliente,
          event.locF,
          event.locI,
          event.nameMot,
        ],
        notes: event.content,
        startTime: event.startTime,
        endTime: event.endTime,
        color: event.color,
      );
    }).toList();
  }
}

class Event {
  final int id;
  final String subject;
  final String content;
  final String locI;
  final String locF;
  final String nameMot;
  final String nameCliente;
  final Color color;
  final DateTime startTime;
  final DateTime endTime;
  final int IdUser;

  Event({
    required this.id,
    required this.subject,
    required this.content,
    required this.color,
    required this.startTime,
    required this.endTime,
    required this.IdUser,
    required this.locI,
    required this.locF,
    required this.nameMot,
    required this.nameCliente,
  });
}

