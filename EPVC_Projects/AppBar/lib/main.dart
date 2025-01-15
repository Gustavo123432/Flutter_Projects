import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'login.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    // Request Wi-Fi permissions
    var status = await Permission.location.request(); // Request location permission for Wi-Fi scanning
    if (status.isGranted) {
      // If permission is granted, navigate to the login screen
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoginForm()));
    } else {
      // Handle the case when permission is denied
      // You can show a message or navigate to a different screen
      // For now, we will just show a message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Location permission is required for Wi-Fi access.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // You may optionally display a loading indicator or message here
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}