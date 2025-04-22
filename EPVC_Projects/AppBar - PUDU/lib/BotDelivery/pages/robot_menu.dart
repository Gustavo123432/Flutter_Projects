import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pudu_robot_model.dart';

class Destination {
  final String id;
  final String name;
  final String description;

  Destination({
    required this.id,
    required this.name,
    required this.description,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      id: json['id'].toString(),
      name: json['name'].toString(),
      description: json['description'].toString(),
    );
  }
}

class RobotMenu extends StatefulWidget {
  final PuduRobot robot;

  const RobotMenu({super.key, required this.robot});

  @override
  State<RobotMenu> createState() => _RobotMenuState();
}

class _RobotMenuState extends State<RobotMenu> {
  String? selectedDestination;
  bool isConnected = false;
  bool isLoading = true;
  String? error;
  List<Destination> destinations = [];

  @override
  void initState() {
    super.initState();
    _fetchDestinations();
  }

   Future<void> addRobot() async {
   
    try {
      // First, add the device to the server
      final response = await http.get(
        Uri.parse('http://${widget.robot.ip}:5000/api/destinations?device=${widget.robot.idDevice}&robot_id=${widget.robot.robotIdd}&page_size=200&page_index=1'),
     
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout ao conectar com o servidor');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['code'] == 0 && responseBody['data']['success'] == true) {
          // If device is added successfully, get the robot group
        } else {
          throw Exception('Falha ao adicionar o robô: ${responseBody['msg'] ?? 'Erro desconhecido'}');
        }
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _fetchDestinations() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // TODO: Implement your API call here
      // Example of how the API call should be implemented:
      /*
      final response = await http.get(Uri.parse('YOUR_API_ENDPOINT/destinations'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          destinations = data.map((json) => Destination.fromJson(json)).toList();
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load destinations');
      }
      */

      // Temporary mock data - Replace this with your API implementation
      await Future.delayed(const Duration(seconds: 1)); // Simulating API call
      setState(() {
        destinations = [
          Destination(id: '1', name: 'Cozinha', description: 'Área da cozinha'),
          Destination(id: '2', name: 'Bar', description: 'Área do bar'),
          Destination(id: '3', name: 'Mesa 1', description: 'Mesa 1'),
          Destination(id: '4', name: 'Mesa 2', description: 'Mesa 2'),
        ];
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar destinos: $e')),
        );
      }
    }
  }

  void _showDestinationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecione o Destino',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (isLoading)
                const Center(child: CircularProgressIndicator())
              else if (error != null)
                Center(
                  child: Column(
                    children: [
                      Text('Erro: $error'),
                      ElevatedButton(
                        onPressed: _fetchDestinations,
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              else if (destinations.isEmpty)
                const Center(child: Text('Nenhum destino disponível'))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: destinations.length,
                    itemBuilder: (context, index) {
                      final destination = destinations[index];
                      return ListTile(
                        title: Text(destination.name),
                        subtitle: Text(destination.description),
                        onTap: () {
                          setState(() {
                            selectedDestination = destination.name;
                          });
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo and Title
                const Row(
                  children: [
                    Text(
                      'Bot',
                      style: TextStyle(
                        fontSize: 28,
                        color: Color(0xFF7FCFCF),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Delivery',
                      style: TextStyle(
                        fontSize: 28,
                        color: Color(0xFFFF8C42),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 40),

                // Robot Selection
                const Text(
                  'Robot Selecionado:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF8C42),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.robot.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Destination Selection
                const Text(
                  'Selecione o destino:',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showDestinationPicker,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF8C42),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDestination ?? 'Selecione um destino',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          const Icon(
                            Icons.arrow_drop_down,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Robot Status
                const Text(
                  'Status do Robot:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Status de movimento:',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text('Desconhecido'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Localização atual:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Desconhecido'),
                          SizedBox(height: 8),
                          Text(
                            'Fila de destinos:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text('Vazia'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C42),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: selectedDestination == null
                            ? null
                            : () {
                                // TODO: Implement start route
                              },
                        child: const Text('INICIAR PERCURSO'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('CANCELAR PERCURSO'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8C42),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('VOLTAR PARA DASHBOARD ROBOT'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isConnected ? Colors.red : const Color(0xFFFF8C42),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () {
                    setState(() {
                      isConnected = !isConnected;
                    });
                  },
                  child: Text(isConnected
                      ? 'DESCONECTAR ${widget.robot.name.toUpperCase()}'
                      : 'CONECTAR AO ${widget.robot.name.toUpperCase()}'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
