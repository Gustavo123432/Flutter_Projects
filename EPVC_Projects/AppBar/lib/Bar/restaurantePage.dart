import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:my_flutter_project/Bar/drawerBar.dart';

class RestaurantePage extends StatefulWidget {
  @override
  _RestaurantePageState createState() => _RestaurantePageState();
}

class _RestaurantePageState extends State<RestaurantePage> {
  List<dynamic> reservations = [];
  List<dynamic> menuItems = [];
  final TextEditingController _menuNameController = TextEditingController();
  final TextEditingController _menuDescriptionController =
      TextEditingController();
  final TextEditingController _menuPriceController = TextEditingController();
  String? _selectedMenuItemId;

  @override
  void initState() {
    super.initState();
    fetchReservations();
    fetchMenuItems();
  }

  Future<void> fetchReservations() async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': '3', // Adjust this according to your API
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          reservations = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load reservations');
      }
    } catch (e) {
      print('Error fetching reservations: $e');
    }
  }

  Future<void> fetchMenuItems() async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': 'get_menu_items', // Adjust this according to your API
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          menuItems = json.decode(response.body);
        });
      } else {
        throw Exception('Failed to load menu items');
      }
    } catch (e) {
      print('Error fetching menu items: $e');
    }
  }

  Future<void> addMenuItem() async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': 'add_menu_item',
          'name': _menuNameController.text,
          'description': _menuDescriptionController.text,
          'price': _menuPriceController.text,
        },
      );
      if (response.statusCode == 200) {
        fetchMenuItems(); // Refresh the menu items
        _menuNameController.clear();
        _menuDescriptionController.clear();
        _menuPriceController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Menu item added successfully!')));
      } else {
        throw Exception('Failed to add menu item');
      }
    } catch (e) {
      print('Error adding menu item: $e');
    }
  }

  Future<void> deleteMenuItem(String id) async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': 'delete_menu_item',
          'id': id,
        },
      );
      if (response.statusCode == 200) {
        fetchMenuItems(); // Refresh the menu items
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Menu item deleted successfully!')));
      } else {
        throw Exception('Failed to delete menu item');
      }
    } catch (e) {
      print('Error deleting menu item: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        title: Text(
          'Restaurante',
          style: TextStyle(color: Colors.white),
        ),
        actions: [],
      ),
      drawer: DrawerBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Reservations Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Reservas',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Número de cards por linha
                crossAxisSpacing: 8, // Espaçamento horizontal entre os cards
                mainAxisSpacing: 8, // Espaçamento vertical entre os cards
                childAspectRatio: 1.0, // Proporção largura/altura dos cards
              ),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                return Card(
                  elevation: 4, // Sombra no card
                  margin:
                      const EdgeInsets.all(8), // Espaçamento ao redor do card
                  child: Padding(
                    padding:
                        const EdgeInsets.all(16), // Espaçamento interno do card
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${reservation['name']} - ${reservation['description']}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Date: ${reservation['date']} - Time: ${reservation['time']}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Menu Management Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Gerir Pratos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            TextField(
              controller: _menuNameController,
              decoration: InputDecoration(labelText: 'Menu Item Name'),
            ),
            TextField(
              controller: _menuDescriptionController,
              decoration: InputDecoration(labelText: 'Menu Item Description'),
            ),
            TextField(
              controller: _menuPriceController,
              decoration: InputDecoration(labelText: 'Menu Item Price'),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: addMenuItem,
              child: Text('Adicionar Prato'),
            ),

            // Display Menu Items
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final menuItem = menuItems[index];
                return ListTile(
                  title: Text(menuItem['name']),
                  subtitle: Text(menuItem['description']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete),
                    onPressed: () {
                      deleteMenuItem(menuItem['id']);
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
