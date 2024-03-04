import 'package:flutter/material.dart';


/*class home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Comprado Recentemente',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: homeAluno(),
    );
  }
}*/

class homeAluno extends StatefulWidget {
  @override
  _homeAlunoState createState() => _homeAlunoState();
}

class _homeAlunoState extends State<homeAluno> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey[900],
        title: Text(
          'Comprado Recentemente',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                buildProductSection(
                  imagePath: 'path/to/pepsi_image.jpg',
                  title: 'Pepsi',
                  price: '5.55',
                ),
                buildProductSection(
                  imagePath: 'path/to/coffee_image.jpg',
                  title: 'Café',
                  price: '5.55',
                ),
              ],
            ),
            // Add more product sections here if needed
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey[900],
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home, color: Colors.white),
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.notifications, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProductSection({
    required String imagePath,
    required String title,
    required String price,
  }) {
    return Container(
      width: MediaQuery.of(context).size.width / 2 - 24, // Adjust width as needed
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2.0,
            blurRadius: 4.0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset(imagePath, height: 80.0), // Adjust image height as needed
            Text(
              title,
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'R\$',
                  style: TextStyle(fontSize: 14.0),
                ),
                Text(
                  price,
                  style: TextStyle(fontSize: 16.0),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}