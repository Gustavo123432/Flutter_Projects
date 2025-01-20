import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
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
          'query_param': '4', // Adjust this according to your API
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

  void showAddMenuItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Adicionar Prato'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                addMenuItem();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Adicionar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
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

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Pratos',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            // Display Menu Items
    
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Colors.blue,
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Adicionar Prato',
            onTap: () => showAddMenuItemDialog(context),
          ),
          // You can add more SpeedDialChild items here if needed
        ],
      ),
    );
  }
}
