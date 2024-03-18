import 'package:flutter/material.dart';
import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: false,
      ),
      home: Scaffold(
        body: PermissionRequestWidget(),
      ),
    );
  }
}

class PermissionRequestWidget extends StatefulWidget {
  const PermissionRequestWidget({Key? key}) : super(key: key);

  @override
  _PermissionRequestWidgetState createState() => _PermissionRequestWidgetState();
}

class _PermissionRequestWidgetState extends State<PermissionRequestWidget> {
  @override
  void initState() {
    super.initState();
    // No need to request storage permission on web
    // Simply proceed to the login screen
    Future.delayed(Duration.zero, () {
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginForm()));
    });
  }

  @override
  Widget build(BuildContext context) {
    // You may optionally display a loading indicator or message here
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}
