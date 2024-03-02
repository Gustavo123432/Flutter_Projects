// ignore_for_file: file_names, library_private_types_in_public_api, camel_case_types, use_key_in_widget_constructors, non_constant_identifier_names
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';

class calendarUsersPage extends StatefulWidget {
  @override
  _CalendarUsersPageState createState() => _CalendarUsersPageState();
}

class _CalendarUsersPageState extends State<calendarUsersPage> {
  dynamic tar;
  dynamic Users;
  int length = 0;
  dynamic type = 'all';

  getAllProducts() async {
    dynamic response = await http.get(Uri.parse(
        "https://services.interagit.com/API/api_Calendar.php?query_param=11"));
    if (response.statusCode == 200) {
      setState(() {
        tar = json.decode(response.body);
      });
      length = int.parse(tar.length.toString());
      return tar;
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
    _fetchAllImageData();
    getUserList('all');
    super.initState();
  }

  dynamic U_Image;

  Future<void> _fetchAllImageData() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://services.interagit.com/API/api_Calendar.php?query_param=8'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> imageList = json.decode(response.body);

        setState(() {
          U_Image = List<Map<String, dynamic>>.from(imageList);
        });
      } else {
        //print('Failed to load image data. Error ${response.statusCode}');
      }
    } catch (e) {
      //print('Error fetching image data: $e');
    }
  }

  List<String> order = <String>['Numero', 'Nome', 'Tipo de User'];
  dynamic orderv;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
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
            dataSource: _getCalendarDataSource(Users, length, U_Image),
            showDatePickerButton: true,
            showNavigationArrow: true,
            initialSelectedDate: DateTime.now(),
            monthViewSettings: const MonthViewSettings(
              dayFormat: 'EEE',
            ),
            timeSlotViewSettings: const TimeSlotViewSettings(
              timeFormat: "HH:mm",
            ),
          ),
        )));
  }
}

class DataSource extends CalendarDataSource {
  DataSource(List<Appointment> source, List<CalendarResource> resourceColl) {
    appointments = source;
    resources = resourceColl;
  }
}

DataSource _getCalendarDataSource(dynamic Users, int n, dynamic U_image) {
  List<Appointment> appointments = <Appointment>[];

  List<CalendarResource> resources = <CalendarResource>[];

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

  for (int i = 0; i < n; i++) {
    if (U_image != null &&
        U_image.length > i &&
        U_image[i]['imageData'] != null) {
      List<int> bytes = base64.decode(U_image[i]['imageData']);

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
