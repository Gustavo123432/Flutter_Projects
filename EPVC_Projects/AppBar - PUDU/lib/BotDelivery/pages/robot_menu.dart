import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/pudu_robot_model.dart';
import '../entities/robot_state_query_response.dart';
import '../widgets/charging_dialog.dart';

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
  
  // Current location tracking
  String _currentLocation = "Desconhecido";
  Destination? _currentDestination;
  
  // Debug information to display
  String debugInfo = '';
  
  // Charging dialog
  bool _isChargingDialogShowing = false;

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
              isConnected: true,
              chargeStage: data['chargeStage']?.toString() ?? 'Unknown',
              moveState: data['moveState']?.toString() ?? 'Unknown',
              robotState: data['robotState']?.toString() ?? 'Unknown',
              robotId: widget.robot.robotIdd,
              robotPose: data['robotPose'] is Map 
                ? RobotPose.fromJson(Map<String, dynamic>.from(data['robotPose'])) 
                : RobotPose(0.0, 0.0, 0.0),
              robotPower: data['robotPower'] is int 
                ? data['robotPower'] 
                : (data['robotPower'] is String ? int.tryParse(data['robotPower']) ?? 0 : 0),
              destinationQueue: data['destinationQueue'] is List 
                ? List<Map<String, dynamic>>.from(data['destinationQueue']) 
                : [],
            );
            
            // Update current location based on robot status
            _updateCurrentLocation();
            
            debugInfo = 'Robot status updated successfully';
            
            // Check if robot is in special status
            _checkRobotStatusForSpecialConditions();
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
  
  // Method to update the current location display based on robot status
  void _updateCurrentLocation() {
    if (robotStatus.chargeStage == CHARGING_STATE || 
        robotStatus.chargeStage == CHARGE_FULL_STATE) {
      _currentLocation = 'Estação de carregamento';
    } else if (robotStatus.moveState == MOVING_STATE && 
              _currentDestination != null) {
      _currentLocation = 'Indo para ${_currentDestination!.name}';
    } else if (robotStatus.moveState == ARRIVED_STATE || 
              robotStatus.moveState == ARRIVE_STATE) {
      if (_currentDestination != null) {
        _currentLocation = _currentDestination!.name;
      } else {
        _currentLocation = 'Chegou ao destino';
      }
    } else if (robotStatus.moveState == IDLE_STATE) {
      final nearestDestination = _findNearestDestination();
      _currentLocation = nearestDestination ?? 'Aguardando';
    } else {
      _currentLocation = _translateMovementState(robotStatus.moveState);
    }
  }
  
  // Method to find the nearest destination based on coordinates
  String? _findNearestDestination() {
    // This would require more complex logic to determine the nearest location
    // For now, return null which will display "Aguardando"
    return null;
  }
  
  void _showLocationDialog(String location) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Localização atual'),
          content: Text('O robot está em: $location'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Add a method to check for special conditions based on robot status
  void _checkRobotStatusForSpecialConditions() {
    // Check for charging state
    if (robotStatus.chargeStage == CHARGING_STATE || 
        robotStatus.chargeStage == CHARGE_FULL_STATE) {
      // Robot is charging, show the charging dialog
      debugInfo += '\nRobot is currently charging';
      
      // Show charging dialog if not already showing
      if (!_isChargingDialogShowing && mounted) {
        _showChargingDialog();
      } else if (_isChargingDialogShowing && mounted) {
        // Update the existing dialog with new data
        Navigator.of(context).pop(); // Close current dialog
        _showChargingDialog(); // Show updated dialog
      }
    } else {
      // If robot is no longer charging, dismiss dialog if showing
      if (_isChargingDialogShowing && mounted) {
        Navigator.of(context).pop();
        _isChargingDialogShowing = false;
      }
    }
    
    // Check if robot has arrived at destination
    if (robotStatus.moveState == ARRIVED_STATE || 
        robotStatus.moveState == ARRIVE_STATE) {
      // Robot has arrived, could show notification or update UI
      debugInfo += '\nRobot has arrived at destination';
      
      // Could enable/disable buttons based on this state
      setState(() {
        // Update UI based on arrived state
      });
    }
    
    // Check if robot is idle and available
    if (robotStatus.moveState == IDLE_STATE && 
        robotStatus.robotState == FREE_STATE) {
      // Robot is available for new tasks
      debugInfo += '\nRobot is available for new tasks';
    }
  }
  
  void _showChargingDialog() {
    setState(() {
      _isChargingDialogShowing = true;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return WillPopScope(
          onWillPop: () async => false,
          child: ChargingDialog(
            chargeStage: _translateChargeStage(robotStatus.chargeStage),
            robotPower: robotStatus.robotPower,
            onDisconnect: () {
              setState(() {
                _isChargingDialogShowing = false;
                isConnected = false;
              });
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to dashboard
            },
          ),
        );
      },
    ).then((_) {
      setState(() {
        _isChargingDialogShowing = false;
      });
    });
  }

  String _translateMovementState(String state) {
    return translateMoveState(state);
  }

  String _translateRobotState(String state) {
    return translateRobotState(state);
  }

  String _translateChargeStage(String stage) {
    return translateChargeStage(stage);
  }

  Color _getStateColor(RobotStatus status) {
    // First check if charging
    if (status.chargeStage.toLowerCase().contains('charg')) {
      return Colors.blue;
    }
    
    // Then check movement state
    final moveState = status.moveState.toLowerCase();
    if (moveState == IDLE_STATE.toLowerCase()) {
      return Colors.grey;
    } else if (moveState.contains(MOVING_STATE.toLowerCase())) {
      return Colors.green;
    } else if (moveState == ARRIVE_STATE.toLowerCase() || moveState == ARRIVED_STATE.toLowerCase()) {
      return Colors.amber;
    }
    
    // Check robot state if no specific movement state
    final robotState = status.robotState.toLowerCase();
    if (robotState == BUSY_STATE.toLowerCase()) {
      return const Color(0xFFFF8C42); // Orange
    } else if (robotState == ERROR_ROBOT_STATE.toLowerCase()) {
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
      
      // Store the current destination
      _currentDestination = selectedDestinationData;
      
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
            
            // Update current location status
            setState(() {
              _currentLocation = 'Indo para ${_currentDestination!.name}';
            });
            
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
      
      // Clear the current destination
      _currentDestination = null;
      
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
            
            // Update current location
            setState(() {
              _currentLocation = 'Aguardando';
            });
            
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

  IconData _getLocationIcon(RobotStatus status) {
    if (status.chargeStage == CHARGING_STATE || status.chargeStage == CHARGE_FULL_STATE) {
      return Icons.electrical_services;
    }
    
    if (status.moveState == MOVING_STATE) {
      return Icons.directions_walk;
    }
    
    if (status.moveState == ARRIVED_STATE || status.moveState == ARRIVE_STATE) {
      return Icons.pin_drop;
    }
    
    if (status.moveState == IDLE_STATE) {
      return Icons.home;
    }
    
    return Icons.location_on;
  }

  // Method to check battery status and update UI accordingly
  Widget _buildBatteryStatus(int power) {
    IconData batteryIcon;
    Color batteryColor;
    
    if (power > 80) {
      batteryIcon = Icons.battery_full;
      batteryColor = Colors.green;
    } else if (power > 50) {
      batteryIcon = Icons.battery_5_bar;
      batteryColor = Colors.green;
    } else if (power > 20) {
      batteryIcon = Icons.battery_3_bar;
      batteryColor = Colors.orange;
    } else {
      batteryIcon = Icons.battery_1_bar;
      batteryColor = Colors.red;
    }
    
    return Row(
      children: [
        Icon(
          batteryIcon,
          color: batteryColor,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '$power%',
          style: TextStyle(
            color: batteryColor,
            fontWeight: power <= 20 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset(
                      'lib/assets/logo_bot_delivery.png',
                      height: 70,
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
                              _buildBatteryStatus(robotStatus.robotPower),
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
                                      'Estado do robot:',
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
                          InkWell(
                            onTap: () => _showLocationDialog(_currentLocation),
                            child: Row(
                              children: [
                                Icon(
                                  _getLocationIcon(robotStatus),
                                  size: 16,
                                  color: _getStateColor(robotStatus),
                                ),
                                const SizedBox(width: 8),
                                Text(_currentLocation),
                              ],
                            ),
                          ),
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
