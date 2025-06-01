import 'dart:typed_data';

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

  bool? reservas = false;

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
          var responseBody = json.decode(response.body);
          if (responseBody.isEmpty) {
            reservas = false; // No reservations found
            reservations = [];
          } else {
            reservas = true; // Reservations found
            reservations = responseBody;
          }
        });
      } else {
        throw Exception('Failed to load reservations');
      }
    } catch (e) {
      print('Error fetching reservations: $e');
    }
  }

  bool? state = false;
  Future<void> fetchMenuItems() async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'query_param': '4'},
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (mounted) {
          setState(() {
            if (responseBody is List) {
              // Normal case: API returned a list of menu items
              if (responseBody.isEmpty) {
                menuItems = [];
                state = true; // No items available
              } else {
                menuItems = responseBody;
                state = false; // Items found
              }
            } else if (responseBody is Map && responseBody.containsKey('message')) {
              // API returned a message instead of a list
              menuItems = [];
              state = true;
            } else {
              // Fallback case: unexpected format
              menuItems = [];
              state = true;
            }
          });
        }
      } else {
        throw Exception('Failed to load menu items');
      }
    } catch (e) {
      print('Error fetching menu items: $e');
    }
  }

//falta imagem
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
          'query_param': '7',
          'id': id,
        },
      );
      if (response.statusCode == 200) {
        setState(() {
          fetchMenuItems(); // Refresh the menu items
        });
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Prato apagado com Sucesso')));
      } else {
        throw Exception('Error 02. Por Favor contacte o Administrador');
      }
    } catch (e) {
      print('Erro ao apagar prato: $e');
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
                decoration: InputDecoration(labelText: 'Nome do Prato'),
              ),
              TextField(
                controller: _menuDescriptionController,
                decoration: InputDecoration(labelText: 'Ingredientes'),
              ),
              TextField(
                controller: _menuPriceController,
                decoration: InputDecoration(labelText: 'Preço do Prato'),
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

  Future<void> toggleMenuItemStatus(String id, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': '5',
          'id': id,
          'status': newStatus,
        },
      );
      if (response.statusCode == 200) {
        if (newStatus == '1') {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Prato Ativado com Sucesso')));
        } else if (newStatus == '0') {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Prato Desativado com Sucesso')));
        }
        setState(() {
          fetchMenuItems();
        });
      } else {
        throw Exception(
            'Erro ao mudar o estado do prato. Por favor contacte o administrador');
      }
    } catch (e) {
      print(
          'Erro ao mudar o estado do prato. Por favor contacte o administrador: $e');
    }
  }

  void showConfirmationDialog(BuildContext context, String id, bool isEnabled) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar Alteração"),
          content: Text(
            isEnabled
                ? "Tem certeza de que deseja desativar este prato?"
                : "Tem certeza de que deseja ativar este prato?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Cancelar"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                toggleMenuItemStatus(
                    id, isEnabled ? "0" : "1");
              },
              child: Text("Confirmar"),
            ),
          ],
        );
      },
    );
  }

  void showDeleteMenuItemDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Selecione o prato para excluir'),
          content: Container(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final prato = menuItems[index];
                return ListTile(
                  title: Text(prato['nome']),
                  trailing: IconButton(
                    icon: Icon(Icons.delete, color: Colors.red),
                    onPressed: () => confirmDelete(context, prato['id']),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void confirmDelete(BuildContext context, String pratoId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Confirmar Eliminação"),
        content: Text("Tem certeza que deseja excluir este prato?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancelar"),
          ),
          TextButton(
            onPressed: () {
              deleteMenuItem(pratoId);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text("Excluir", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> updateReservationState(String id, String newState) async {
    try {
      final response = await http.post(
        Uri.parse('https://appbar.epvc.pt/API/appBarMonteAPI_Post.php'),
        body: {
          'query_param': '5.1',
          'id': id,
          'status': newState,
        },
      );

      if (response.statusCode == 200) {
        print('Reservation state updated');
      } else {
        throw Exception('Failed to update reservation state');
      }
    } catch (e) {
      print('Error updating reservation state: $e');
    }
  }

  Future<void> showConfirmationReservationDialog(
      BuildContext context, String id, bool isEnabled) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirm Action'),
          content: Text(isEnabled
              ? 'Tem a certeza que quer remover a reserva?'
              : 'Tem a certeza que já confirmou a reserva?'),
          actions: <Widget>[
            TextButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context)
                    .pop();
              },
            ),
            TextButton(
              child: Text('Confirmar'),
              onPressed: () async {
                String newState = isEnabled ? "0" : "1";
                await updateReservationState(id, newState);
                await fetchReservations();
                Navigator.of(context).pop();
              },
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
        child: reservas == false
            ? Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Reservas',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            Text("Sem Reservas."),
            SizedBox(
              height: 32,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Pratos',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            state == true
                ? Column(
              children: [
                Text("\t\t\tSem Pratos. Adicione um prato"),
                SizedBox(
                  height: 32,
                )
              ],
            ) // Shows the message when no items
                : GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                Uint8List imageBytes = base64Decode(item['imagem']);
                bool isEnabled = item['estado'] ==
                    "1"; // Convert from string if needed

                return GestureDetector(
                  onTap: () => showConfirmationDialog(
                      context, item['id'], isEnabled),
                  child: Card(
                    color: isEnabled
                        ? Colors.green
                        : Colors.white, // Change color when enabled
                    elevation: 4,
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8)),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          Text(
                            '${item['nome']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isEnabled
                                  ? Colors.white
                                  : Colors
                                  .black, // Change text color
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${item['ingredientes']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isEnabled
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${double.parse(item['preco']).toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isEnabled
                                  ? Colors.white
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ) // Shows the message when no items
            : Column(
          children: [
            // Reservations Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Reservas',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // Number of cards per row
                crossAxisSpacing: 8, // Horizontal space between cards
                mainAxisSpacing: 8, // Vertical space between cards
                childAspectRatio: 1.0, // Width/height ratio of cards
              ),
              itemCount: reservations.length,
              itemBuilder: (context, index) {
                final reservation = reservations[index];
                bool isEnabled = reservation['estado'] ==
                    '1'; // Check if the reservation is enabled (state = 1)

                // Card color based on the state
                Color cardColor = isEnabled ? Colors.green : Colors.white;

                return GestureDetector(
                  onTap: () {
                    // Show confirmation dialog before changing state
                    showConfirmationReservationDialog(
                        context, reservation['id'], isEnabled);
                  },
                  child: Card(
                    elevation: 4, // Shadow on the card
                    margin: const EdgeInsets.all(
                        8), // Spacing around the card
                    color: cardColor, // Set card color based on state
                    child: Padding(
                      padding: const EdgeInsets.all(
                          16), // Internal padding of the card
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${reservation['name']} - ${reservation['description']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isEnabled
                                  ? Colors.white
                                  : Colors
                                  .black, // Adjust text color based on card state
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Date: ${reservation['date']} - Time: ${reservation['time']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isEnabled
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Pratos',
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            state == true
                ? Column(
              children: [
                Text("Sem Pratos. Adicione um prato"),
                SizedBox(
                  height: 32,
                )
              ],
            ) // Shows the message when no items
                : GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate:
              SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                Uint8List imageBytes = base64Decode(item['imagem']);
                bool isEnabled = item['estado'] ==
                    "1"; // Convert from string if needed

                return GestureDetector(
                  onTap: () => showConfirmationDialog(
                      context, item['id'], isEnabled),
                  child: Card(
                    color: isEnabled
                        ? Colors.green
                        : Colors.white, // Change color when enabled
                    elevation: 4,
                    margin: const EdgeInsets.all(8),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(8)),
                              child: Image.memory(
                                imageBytes,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),
                          Text(
                            '${item['nome']}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isEnabled
                                  ? Colors.white
                                  : Colors
                                  .black, // Change text color
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${item['ingredientes']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isEnabled
                                  ? Colors.white70
                                  : Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${double.parse(item['preco']).toStringAsFixed(2)}€',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isEnabled
                                  ? Colors.white
                                  : Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Adicionar Prato',
            onTap: () => showAddMenuItemDialog(context),
          ),
          SpeedDialChild(
            child: Icon(Icons.delete),
            label: 'Eliminar Prato',
            backgroundColor: Colors.red,
            onTap: () => showDeleteMenuItemDialog(context),
          ),
        ],
      ),
    );
  }
}
