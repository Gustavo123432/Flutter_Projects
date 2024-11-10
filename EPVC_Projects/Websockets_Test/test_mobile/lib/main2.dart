import 'dart:io';  // For WebSocket
import 'dart:convert';  // For jsonDecode and jsonEncode
import 'package:flutter/material.dart';

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
      home: const MyHomePage(title: 'WebSocket Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0; // Counter for the button clicks
  WebSocket? _webSocket; // WebSocket variable to hold connection
  int _webSocketData = 0; // Variable to hold WebSocket data

  @override
  void initState() {
    super.initState();
    _connectWebSocket(); // Initialize the WebSocket connection
  }

  void _connectWebSocket() async {
    try {
      // Connect to the WebSocket server
      _webSocket = await WebSocket.connect('ws://192.168.1.214:8081');
      print('Connected to WebSocket');

      // Listen for incoming messages from WebSocket
      _webSocket!.listen(
        (message) {
          print('Received message: $message');
          setState(() {
            _webSocketData = int.tryParse(message) ?? 0; // Update WebSocket data
          });
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Error connecting to WebSocket: $e');
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
      if (_counter % 10 == 0) {
        // Send notification through WebSocket every 10 increments
        if (_webSocket != null && _webSocket!.readyState == WebSocket.open) {
          String jsonMessage = jsonEncode({'Counter_reached': _counter.toString()});
          _webSocket!.add(jsonMessage); // Send message
          print('Notification sent: Counter reached $_counter');
        } else {
          print('WebSocket connection not open');
        }
      }
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
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            Text('WebSocket Data: $_webSocketData'), // Display WebSocket data
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
