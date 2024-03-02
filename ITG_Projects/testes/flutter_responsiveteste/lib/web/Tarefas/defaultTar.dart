// ignore_for_file: camel_case_types, use_key_in_widget_constructors, file_names, non_constant_identifier_names, no_leading_underscores_for_local_identifiers, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_responsiveteste/web/web.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:convert';
import 'createTar.dart';


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
  String selectedOption = '1';
  bool isRecurrentChecked = false;
  OverlayEntry? overlayEntry;
  dynamic tar;
  dynamic length;
  bool isChecked1 = false;
  bool isChecked2 = false;
  bool isChecked3 = false;
  bool isChecked4 = false;
  bool isChecked5 = false;
  bool isChecked6 = false;
  bool isChecked7 = false;
  bool isChecked8 = false;
  bool isChecked10 = false;
  bool isChecked11 = true;
  bool isChecked12 = false;
  bool isChecked13 = false;
  List<String> order = <String>[
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sabado',
    'Domingo'
  ];
  dynamic orderv = 'Segunda';
  bool isCheckedAdditional = false; // Nova variável para a nova checkbox
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController NameClientController = TextEditingController();
  final TextEditingController LocRController = TextEditingController();
  final TextEditingController LocEController = TextEditingController();
  DateTime selectedStartDate = DateTime.now();
  TimeOfDay selectedStartTime = TimeOfDay.now();
  DateTime selectedEndDate = DateTime.now();
  TimeOfDay selectedEndTime = TimeOfDay.now();
  dynamic selectedColor = Colors.blue;
  String formattedStartDate = '';

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
            tar[i]['Color'],
            DateTime.parse(tar[i]['DataIni'] + ' ' + tar[i]['TempIni']),
            DateTime.parse(tar[i]['DateEnd'] + ' ' + tar[i]['TempEnd']));
      }
      //return tar;
    }
  }

  createTar(String title, String descrip, String dataini, String tempini,
      String dateend, String tempend, String selectedColor, int id) async {
    dynamic response = await http.get(Uri.parse(
        "https://services.interagit.com/API/api_Calendar.php?query_param=15&Titulo=$title&Descrip=$descrip&DataIni=$dataini&TempIni=$tempini&TempEnd=$tempend&DateEnd=$dateend&Color=$selectedColor&id=$id"));
    if (response.statusCode == 200) {
      setState(() {
        //print('Feito?');
      });
    }

    getAllProducts();
  }
    getUserList() async {
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=4'));
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
    getAllProducts();
    super.initState();
      _controller.text = "0";
    getUserList();
  }

  void changeColor(Color color) {
    setState(() {
      selectedColor = color;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
          theme: ThemeData(
        useMaterial3: true,
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
                      width: 290, 
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
                          initialDisplayDate: DateTime.parse(
                              "${DateTime.now().year}-${DateTime.now().month + 1}-01"),
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
                     appointmentBuilder: (BuildContext context, CalendarAppointmentDetails details) {

        return Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue, //cor da appoitement
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
 
     
              //MOdify Agenda VIew :)
            ],
          ),
        );
      },

  
                initialSelectedDate: DateTime.now(),
                onDragEnd: dragEnd,
                selectionDecoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.blue, width: 2),
                  borderRadius: const BorderRadius.all(Radius.circular(4)),
                  shape: BoxShape.rectangle,
                ),
                monthViewSettings: const MonthViewSettings(
                    showAgenda: true,
                    agendaItemHeight: 70,
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
           // _showEventCreationDialog(context);
                   Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>  CreateTar(),
            ));
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }



  void _showColorPickerDialog(StateSetter setStatee) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color pickedColor =
            selectedColor; // Initialize pickedColor with selectedColor

        return AlertDialog(
          title: const Text('Selecione uma Cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setStatee(() {
                  pickedColor = color; // Update pickedColor when color changes
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the AlertDialog
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setStatee(() {
                  selectedColor =
                      pickedColor; // Update selectedColor with pickedColor
                });
                Navigator.of(context).pop(); // Close the AlertDialog
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  void emptyFields() async {
    final title = _titleController.text;
    final descri = _descriptionController.text;
    final nomeC = NameClientController.text;
    final LocR = LocRController.text;
    final LocE = LocEController.text;

    final color = selectedColor.toString().substring(10, 16);

    //print(color);

    if (title.isEmpty ||
        descri.isEmpty ||
        nomeC.isEmpty ||
        LocE.isEmpty ||
        LocR.isEmpty ||
        color.isEmpty) {
          
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text(
          'Preencha todos os campos',
          style: TextStyle(
            fontSize: 16, // Customize font size
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
        backgroundColor: Colors.red, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
    Future.delayed(Duration.zero, () {
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
});

    } else {
      //print(title);
      //print(color);

      createTar(
        _titleController.text,
        _descriptionController.text,
        '${selectedStartDate.year}-${selectedStartDate.month}-${selectedStartDate.day}',
        '${selectedStartTime.hour}:${selectedStartTime.minute}:00',
        '${selectedEndDate.year}-${selectedEndDate.month}-${selectedEndDate.day}',
        '${selectedEndTime.hour}:${selectedEndTime.minute}:00',
        '$selectedColor',
        int.parse(selectedOption),
      );
      print(selectedOption);
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const WebPage(title: 'Calendário'),
          ));
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text(
          'Tarefa criada',
          style: TextStyle(
            fontSize: 16, // Customize font size
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
        backgroundColor: Colors.green, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
    Future.delayed(Duration.zero, () {
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
});

    }
  }
  void _createEvent(
      int id, String subject, String color, DateTime start, DateTime end) {
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
      content: 'Teste',
      color: Color(cor),
      startTime: start,
      endTime: end,
    );
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
    //dynamic appointment = appointmentDragEndDetails.appointment;
    setState(() {
      _getCalendarDataSource();
    });

    //print(_getCalendarDataSource());
    //print(appointment);
  }
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Event> source) {
    appointments = source.map((event) {
      return Appointment(
        id: event.id,
        subject: event.subject,
        notes: 'Teste',
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
