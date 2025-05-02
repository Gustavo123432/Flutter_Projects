import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pudu_robot_model.dart';

class Destination {
  final String name;
  final String type;

  Destination({
    required this.name,
    required this.type,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    return Destination(
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }
}

class RobotStatus {
  final String chargeStage;
  final String moveState;
  final String robotState;
  final Map<String, dynamic> robotPose;
  final int robotPower;
  final List<Map<String, dynamic>> destinationQueue;

  RobotStatus({
    required this.chargeStage,
    required this.moveState,
    required this.robotState,
    required this.robotPose,
    required this.robotPower,
    required this.destinationQueue,
  });

  factory RobotStatus.empty() {
    return RobotStatus(
      chargeStage: 'Unknown',
      moveState: 'Unknown',
      robotState: 'Unknown',
      robotPose: {'x': 0.0, 'y': 0.0, 'angle': 0.0},
      robotPower: 0,
      destinationQueue: [],
    );
  }

  String get formattedLocation {
    final x = robotPose['x']?.toStringAsFixed(2) ?? '0.00';
    final y = robotPose['y']?.toStringAsFixed(2) ?? '0.00';
    return 'X: $x, Y: $y';
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
  RobotStatus robotStatus = RobotStatus.empty();
  Timer? _statusRefreshTimer;
  
  // Debug information to display
  String debugInfo = '';

  @override
  void initState() {
    super.initState();
    _checkRobotIdAndFetchDestinations();
    _fetchRobotStatus();
    
    // Set up a timer to refresh status every 5 seconds
    _statusRefreshTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchRobotStatus();
    });
  }
  
  @override
  void dispose() {
    _statusRefreshTimer?.cancel();
    super.dispose();
  }
  
  void _checkRobotIdAndFetchDestinations() {
    // Check if robotIdd is missing or empty
    if (widget.robot.robotIdd.isEmpty) {
      setState(() {
        debugInfo = 'Robot ID is missing. IP: ${widget.robot.ip}, Device ID: ${widget.robot.idDevice}';
        error = 'Robot ID is missing. Please update robot information.';
        isLoading = false;
      });
      
      // Show error message
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Robot ID is missing. Please update robot information.'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      });
    } else {
      // If robotIdd is available, fetch destinations
      _fetchDestinations();
    }
  }

  Future<void> _fetchRobotStatus() async {
    if (widget.robot.robotIdd.isEmpty || widget.robot.idDevice.isEmpty) {
      return;
    }
    
    try {
      setState(() {
        debugInfo = 'Fetching robot status...';
      });

      final response = await http.get(
        Uri.parse('http://${widget.robot.ip}:5000/api/robot/status?device_id=${widget.robot.idDevice}&robot_id=${widget.robot.robotIdd}'),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout connecting to server');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['code'] == 0 && responseData['data'] != null) {
          final data = responseData['data'];
          setState(() {
            robotStatus = RobotStatus(
              chargeStage: data['chargeStage']?.toString() ?? 'Unknown',
              moveState: data['moveState']?.toString() ?? 'Unknown',
              robotState: data['robotState']?.toString() ?? 'Unknown',
              robotPose: data['robotPose'] is Map ? 
                Map<String, dynamic>.from(data['robotPose']) : 
                {'x': 0.0, 'y': 0.0, 'angle': 0.0},
              robotPower: data['robotPower'] is int ? 
                data['robotPower'] : 
                (data['robotPower'] is String ? int.tryParse(data['robotPower']) ?? 0 : 0),
              // Keep destination queue for future API updates
              destinationQueue: data['destinationQueue'] is List ? 
                List<Map<String, dynamic>>.from(data['destinationQueue']) : 
                [],
            );
            debugInfo = 'Robot status updated successfully';
          });
        } else {
          debugInfo = 'Error parsing robot status: ${responseData['msg']}';
        }
      } else {
        debugInfo = 'Error ${response.statusCode} fetching robot status';
      }
    } catch (e) {
      debugInfo = 'Error fetching robot status: ${e.toString()}';
      // Don't show snackbar for status errors to avoid spamming the user
    }
  }
  
  String _translateMovementState(String state) {
    switch (state.toLowerCase()) {
      case 'idle':
        return 'Parado';
      case 'moving':
      case 'move':
        return 'Em movimento';
      case 'charging':
      case 'charge':
        return 'Carregando';
      case 'waiting':
      case 'wait':
        return 'Aguardando';
      case 'delivering':
      case 'deliver':
        return 'Entregando';
      case 'returning':
      case 'return':
        return 'Retornando';
      case 'arrive':
        return 'Chegou ao destino';
      default:
        return state.isNotEmpty ? state : 'Desconhecido';
    }
  }

  String _translateRobotState(String state) {
    switch (state.toLowerCase()) {
      case 'free':
        return 'Livre';
      case 'busy':
        return 'Ocupado';
      case 'charging':
        return 'Carregando';
      case 'error':
        return 'Erro';
      default:
        return state.isNotEmpty ? state : 'Desconhecido';
    }
  }

  String _translateChargeStage(String stage) {
    switch (stage.toLowerCase()) {
      case 'idle':
        return 'Não carregando';
      case 'charging':
        return 'Carregando';
      case 'fully_charged':
      case 'full':
        return 'Completamente carregado';
      case 'low_battery':
      case 'low':
        return 'Bateria baixa';
      default:
        return stage.isNotEmpty ? stage : 'Desconhecido';
    }
  }

  Color _getStateColor(RobotStatus status) {
    // First check if charging
    if (status.chargeStage.toLowerCase().contains('charg')) {
      return Colors.blue;
    }
    
    // Then check movement state
    final moveState = status.moveState.toLowerCase();
    if (moveState == 'idle') {
      return Colors.grey;
    } else if (moveState.contains('mov')) {
      return Colors.green;
    } else if (moveState == 'arrive') {
      return Colors.amber;
    }
    
    // Check robot state if no specific movement state
    final robotState = status.robotState.toLowerCase();
    if (robotState == 'busy') {
      return const Color(0xFFFF8C42); // Orange
    } else if (robotState == 'error') {
      return Colors.red;
    }
    
    // Default color
    return const Color(0xFFFF8C42);
  }

  Future<void> _fetchDestinations() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
        debugInfo = 'Fetching destinations from: http://${widget.robot.ip}:5000/api/destinations?device=${widget.robot.idDevice}&robot_id=${widget.robot.robotIdd}&page_size=200&page_index=1';
      });

      final response = await http.get(
        Uri.parse('http://${widget.robot.ip}:5000/api/destinations?device=${widget.robot.idDevice}&robot_id=${widget.robot.robotIdd}&page_size=200&page_index=1'),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout connecting to server. Please check network connectivity.');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['code'] == 0 && responseData['data'] != null) {
          final data = responseData['data'];
          
          if (data['destinations'] != null && data['destinations'] is List) {
            final List<dynamic> destinationList = data['destinations'];
            
            setState(() {
              destinations = destinationList
                  .map((item) => Destination.fromJson(item))
                  .toList();
              isLoading = false;
              debugInfo = 'Successfully loaded ${destinations.length} destinations';
            });
          } else {
            throw Exception('Invalid destinations format');
          }
        } else {
          throw Exception('Error loading destinations: ${responseData['msg']}');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || errorMessage.contains('No route to host')) {
        errorMessage = 'Cannot connect to robot. Please check if the robot is on and connected to the network.';
      }
      
      setState(() {
        error = errorMessage;
        isLoading = false;
        debugInfo = 'Error: $errorMessage';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _sendToDestination() async {
    if (selectedDestination == null) return;
    
    try {
      setState(() {
        isLoading = true;
        debugInfo = 'Sending robot to destination: $selectedDestination';
      });
      
      // Find the selected destination's full data including type
      final selectedDestinationData = destinations.firstWhere(
        (dest) => dest.name == selectedDestination,
        orElse: () => Destination(name: selectedDestination!, type: 'table'), // Default to table if not found
      );
      
      // Prepare the request body in the correct format
      final requestBody = {
        'deviceId': widget.robot.idDevice,
        'robotId': widget.robot.robotIdd,
        'destination': {
          'name': selectedDestinationData.name,
          'type': selectedDestinationData.type
        }
      };
      
      debugInfo += '\nRequest body: ${json.encode(requestBody)}';
      
      final response = await http.post(
        Uri.parse('http://${widget.robot.ip}:5000/api/robot/call'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout connecting to server');
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['code'] == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Robot sent successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Fetch status immediately after sending
            _fetchRobotStatus();
          }
        } else {
          throw Exception('Error sending robot: ${responseData['msg']}');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || errorMessage.contains('No route to host')) {
        errorMessage = 'Cannot connect to robot. Please check if the robot is on and connected to the network.';
      }
      
      setState(() {
        debugInfo = 'Error sending robot: $errorMessage';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending robot: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _cancelToDestination() async {
    if (selectedDestination == null) return;
    
    try {
      setState(() {
        isLoading = true;
        debugInfo = 'Cancel robot to destination: $selectedDestination';
      });
      
      // Find the selected destination's full data including type
      final selectedDestinationData = destinations.firstWhere(
        (dest) => dest.name == selectedDestination,
        orElse: () => Destination(name: selectedDestination!, type: 'table'), // Default to table if not found
      );
      
      // Prepare the request body in the correct format
      final requestBody = {
        'deviceId': widget.robot.idDevice,
        'robotId': widget.robot.robotIdd,
        'destination': {
          'name': selectedDestinationData.name,
          'type': selectedDestinationData.type
        }
      };
      
      debugInfo += '\nRequest body: ${json.encode(requestBody)}';
      
      final response = await http.post(
        Uri.parse('http://${widget.robot.ip}:5000/api/robot/cancel/call'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout connecting to server');
        },
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['code'] == 0) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Robot cancellation successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Fetch status immediately after cancellation
            _fetchRobotStatus();
          }
        } else {
          throw Exception('Error sending robot: ${responseData['msg']}');
        }
      } else {
        throw Exception('Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('SocketException') || errorMessage.contains('No route to host')) {
        errorMessage = 'Cannot connect to robot. Please check if the robot is on and connected to the network.';
      }
      
      setState(() {
        debugInfo = 'Error sending robot: $errorMessage';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending robot: $errorMessage'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showDestinationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          height: MediaQuery.of(context).size.height * 0.6,
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
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchDestinations,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8C42),
                        ),
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
                        subtitle: Text(_formatDestinationType(destination.type)),
                        trailing: selectedDestination == destination.name
                            ? const Icon(Icons.check_circle, color: Color(0xFFFF8C42))
                            : null,
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

  String _formatDestinationType(String type) {
    switch (type) {
      case 'table':
        return 'Mesa';
      case 'dining_outlet':
        return 'Área de Refeição';
      default:
        return type.isNotEmpty ? type[0].toUpperCase() + type.substring(1) : '';
    }
  }

  Widget _buildQueueList() {
    if (robotStatus.destinationQueue.isEmpty) {
      return const Text('Nenhum destino na fila');
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: robotStatus.destinationQueue.map((destination) {
        final name = destination['name'] ?? 'Unknown';
        final type = destination['type'] ?? '';
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: Color(0xFFFF8C42)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$name (${_formatDestinationType(type)})',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
        );
      }).toList(),
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

                // Debug information - Only show in debug mode
               /* if (debugInfo.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[400]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Debug Information:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text('Robot ID: ${widget.robot.robotIdd}'),
                        Text('Device ID: ${widget.robot.idDevice}'),
                        Text('IP: ${widget.robot.ip}'),
                        const SizedBox(height: 4),
                        Text(debugInfo, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],*/

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
                                Row(
                                  children: [
                                    Container(
                                      width: 10,
                                      height: 10,
                                      margin: const EdgeInsets.only(right: 6),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _getStateColor(robotStatus),
                                      ),
                                    ),
                                    Text(_translateMovementState(robotStatus.moveState)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Bateria:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Row(
                                children: [
                                  Icon(
                                    robotStatus.robotPower > 80 ? Icons.battery_full :
                                    robotStatus.robotPower > 50 ? Icons.battery_5_bar :
                                    robotStatus.robotPower > 20 ? Icons.battery_3_bar :
                                    Icons.battery_1_bar,
                                    color: robotStatus.robotPower > 20 ? Colors.green : Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text('${robotStatus.robotPower}%'),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Estado do robô:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(_translateRobotState(robotStatus.robotState)),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Estado de carga:',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(_translateChargeStage(robotStatus.chargeStage)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Localização atual:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(robotStatus.formattedLocation),
                          const SizedBox(height: 16),
                          const Text(
                            'Fila de destinos:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          _buildQueueList(),
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
                        onPressed: selectedDestination == null || widget.robot.robotIdd.isEmpty
                            ? null
                            : _sendToDestination,
                        child: isLoading 
                          ? const SizedBox(
                              width: 20, 
                              height: 20, 
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            )
                          : const Text('INICIAR PERCURSO'),
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
                        onPressed: _cancelToDestination,
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
