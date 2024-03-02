import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GridView Example',
       theme: ThemeData(
    colorScheme: const ColorScheme.light().copyWith(
      primary: Colors.green[700],
      secondary: Colors.green[700],
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Theme.of(context).colorScheme.onPrimary,
      hintStyle: TextStyle(
        color: Colors.green[700],
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      foregroundColor: Colors.white,
    ),
  ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<int> _gridItems = [];

  void _addGridItem() {
    setState(() {
      _gridItems.add(_gridItems.length + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('GridView Example'),
      ),
      body: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 1.0,
          mainAxisSpacing: 1.0,
          childAspectRatio: 1.4,
        ),
        itemCount: _gridItems.length,
        itemBuilder: (BuildContext context, int index) {
          return GridItem(_gridItems[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addGridItem,
        child: Icon(Icons.add),
      ),
    );
  }
}

class GridItem extends StatelessWidget {
  final int number;

  GridItem(this.number);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(12),
      child: Center(
        child: Text(
          'Item $number',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
