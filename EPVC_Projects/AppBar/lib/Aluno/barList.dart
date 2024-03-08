import 'dart:async'; // Import Timer
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ListaProdutos extends StatefulWidget {
  @override
  _ListaProdutosState createState() => _ListaProdutosState();
}

class _ListaProdutosState extends State<ListaProdutos> {
  // List to hold items fetched from the API
  List<Map<String, dynamic>> items = [];

  // Function to fetch data from the API
  Future<void> fetchData() async {
    try {
      final response = await http.post(
        Uri.parse('http://api.gfserver.pt/appBarAPI_Post.php'),
        body: {
          'query_param': '4',
        },
      );
      if (response.statusCode == 200) {
        final dynamic responseData = json.decode(response.body);
     // Debugging: Print response data to console
        if (responseData is List<dynamic>) {
          setState(() {
            items = responseData.cast<Map<String, dynamic>>(); // Cast to List<Map<String, dynamic>>
          });
        } else {
          throw Exception('Response data is not a List<dynamic>');
        }
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print('Error fetching data: $e');
      // Handle error appropriately, e.g., show a snackbar
    }
  }

  @override
  void initState() {
    super.initState();
    fetchData(); // Call fetchData() when the widget is initialized
    // Start a timer to refresh the data every 30 seconds
    Timer.periodic(Duration(seconds: 1), (timer) {
      fetchData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("List of Items"),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (BuildContext context, int index) {
          // Decode Base64 image data
          Uint8List bytes = base64Decode(items[index]['Imagem']);

          return Card(
            child: ListTile(
              leading: CircleAvatar(
                // Use decoded image data
                backgroundImage: MemoryImage(bytes),
              ),
              title: Text(items[index]['Nome']),
              subtitle: Text(
                // Determine subtitle text based on item availability
                items[index]['Qtd'] == "1" ? "Disponível" : "Indisponível",
              ),
            ),
          );
        },
      ),
    );
  }
}
