import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Timer Example',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  dynamic imageBlob; 
  dynamic Users;
  dynamic length;
  getUserList(String id) async {
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=20&id=$id'));
    if (response.statusCode == 200) {
      setState(() {
        Users = jsonDecode(response.body) as List;
      });
      length = int.parse(Users.length.toString());
      print(Users);

      return Users;
    }
  }

  @override
  void initState() {
    super.initState();
    getUserList("0");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter Timer Example'),
      ),
      body: Center(
        child: Users != null
            ? Image.memory(base64Decode(Users[0]['UImage'].toString()))
            : Text("Bruh"),
      ),
    );
  }
}
