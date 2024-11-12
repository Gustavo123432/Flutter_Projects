import 'dart:convert';  // For jsonDecode and jsonEncode
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebSocketPage(title: 'WebSocket Data Display'),
    );
  }
}

class WebSocketPage extends StatefulWidget {
  const WebSocketPage({super.key, required this.title});

  final String title;

  @override
  State<WebSocketPage> createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  String _webSocketData = "0";
  WebSocketChannel? _channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _connectWebSocket();
  }

  // Initialize local notifications
  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  // Show notification
  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'websocket_channel', 'WebSocket Notifications',
      channelDescription: 'Notifications from WebSocket messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New WebSocket Message',
      message,
      platformChannelSpecifics,
      payload: 'WebSocket message received',
    );
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://10.5.48.156:1000'), // Replace with your WebSocket URL
    );

    _channel!.stream.listen((event) {
      try {
        Map<String, dynamic> data = jsonDecode(event);
        if (data.containsKey('Counter_reached')) {
          setState(() {
            _webSocketData = data['Counter_reached'].toString();
          });

          // Show notification when data is received
          _showNotification('Counter reached: $_webSocketData');
        }
      } catch (e) {
        print('Error decoding WebSocket data: $e');
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('WebSocket Data Received:'),
            Text(
              '$_webSocketData',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close(); // Close WebSocket connection when widget is disposed
    super.dispose();
  }
}
//IOS Code
/*import 'dart:convert';  // For jsonDecode and jsonEncode
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const WebSocketPage(title: 'WebSocket Data Display'),
    );
  }
}

class WebSocketPage extends StatefulWidget {
  const WebSocketPage({super.key, required this.title});

  final String title;

  @override
  State<WebSocketPage> createState() => _WebSocketPageState();
}

class _WebSocketPageState extends State<WebSocketPage> {
  int _webSocketData = 0;
  WebSocketChannel? _channel;
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  @override
  void initState() {
    super.initState();
    _initializeNotifications();
    _connectWebSocket();
  }

  // Initialize local notifications and request iOS permissions
  void _initializeNotifications() {
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize settings for Android
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Initialize settings for iOS
    const IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid, iOS: initializationSettingsIOS);

    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request permission on iOS
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  // Show notification
  Future<void> _showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'websocket_channel', 'WebSocket Notifications',
      channelDescription: 'Notifications from WebSocket messages',
      importance: Importance.high,
      priority: Priority.high,
    );
    const IOSNotificationDetails iosPlatformChannelSpecifics =
        IOSNotificationDetails();

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(
            android: androidPlatformChannelSpecifics, iOS: iosPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0,
      'New WebSocket Message',
      message,
      platformChannelSpecifics,
      payload: 'WebSocket message received',
    );
  }

  void _connectWebSocket() {
    _channel = WebSocketChannel.connect(
      Uri.parse('ws://192.168.1.166:8080'), // Replace with your WebSocket URL
    );

    _channel!.stream.listen((event) {
      try {
        Map<String, dynamic> data = jsonDecode(event);
        if (data.containsKey('Counter_reached')) {
          setState(() {
            _webSocketData = int.parse(data['Counter_reached']);
          });

          // Show notification when data is received
          _showNotification('Counter reached: $_webSocketData');
        }
      } catch (e) {
        print('Error decoding WebSocket data: $e');
      }
    }, onError: (error) {
      print('WebSocket error: $error');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('WebSocket Data Received:'),
            Text(
              '$_webSocketData',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _channel?.sink.close(); // Close WebSocket connection when widget is disposed
    super.dispose();
  }
}
 */