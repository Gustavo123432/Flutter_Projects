import 'package:flutter/material.dart';

// Constants for charge stage
const String CHARGING_STATE = 'Charging';
const String CHARGE_FULL_STATE = 'ChargeFull';
const String CHARGE_IDLE_STATE = 'Idle';
const String CHARGE_LOW_STATE = 'Low';

// Constants for movement state
const String MOVING_STATE = 'Moving';
const String ARRIVED_STATE = 'Arrived';
const String ARRIVE_STATE = 'Arrive';
const String IDLE_STATE = 'Idle';
const String PAUSE_STATE = 'Pause';
const String ERROR_STATE = 'Error';
const String STUCK_STATE = 'Stuck';
const String APPROACHING_STATE = 'Approaching';

// Constants for robot state
const String FREE_STATE = 'Free';
const String BUSY_STATE = 'Busy';
const String ERROR_ROBOT_STATE = 'Error';

// Class that represents the robot's pose
class RobotPose {
  final double x;
  final double y;
  final double angle;

  RobotPose(this.x, this.y, this.angle);
  
  factory RobotPose.fromJson(Map<String, dynamic> json) {
    return RobotPose(
      (json['x'] ?? 0.0).toDouble(),
      (json['y'] ?? 0.0).toDouble(),
      (json['angle'] ?? 0.0).toDouble(),
    );
  }
}

// Class that represents the robot's status
class RobotStatus {
  final bool isConnected;
  final String moveState;
  final String robotState;
  final String robotId;
  final String chargeStage;
  final int robotPower;
  final RobotPose robotPose;
  final List<Map<String, dynamic>> destinationQueue;

  RobotStatus({
    required this.isConnected,
    required this.moveState,
    required this.robotState,
    required this.robotId,
    required this.chargeStage,
    required this.robotPower,
    required this.robotPose,
    required this.destinationQueue,
  });

  factory RobotStatus.empty() {
    return RobotStatus(
      isConnected: false,
      moveState: 'Unknown',
      robotState: 'Unknown',
      robotId: '',
      chargeStage: 'Unknown',
      robotPower: 0,
      robotPose: RobotPose(0, 0, 0),
      destinationQueue: [],
    );
  }
  
  String get formattedLocation {
    final x = robotPose.x.toStringAsFixed(2);
    final y = robotPose.y.toStringAsFixed(2);
    return 'X: $x, Y: $y';
  }
}

// Map to translate robot state
const Map<String, String> robotStateTranslations = {
  'Free': 'Livre',
  'Busy': 'Ocupado',
  'Charging': 'Carregando',
  'Error': 'Erro',
  'Unknown': 'Desconhecido',
};

// Map to translate movement state
const Map<String, String> moveStateTranslations = {
  'Idle': 'Parado',
  'Moving': 'Movendo',
  'Pause': 'Pausado',
  'Error': 'Erro',
  'Arrived': 'Chegou',
  'Stuck': 'Preso',
  'Approaching': 'Aproximando',
  'Arrive': 'Chegar',
  'Unknown': 'Desconhecido',
};

// Map to translate charge stage
const Map<String, String> chargeStageTranslations = {
  'Idle': 'Não carregando',
  'Charging': 'Carregando',
  'ChargeFull': 'Completamente carregado',
  'Low': 'Bateria baixa',
  'Unknown': 'Desconhecido',
};

// Function to translate robot state
String translateRobotState(String state) {
  return robotStateTranslations[state] ?? state;
}

// Function to translate movement state
String translateMoveState(String state) {
  return moveStateTranslations[state] ?? state;
}

// Function to translate charge stage
String translateChargeStage(String state) {
  return chargeStageTranslations[state] ?? state;
}

// Function to get color based on state
Color getStateColor(RobotStatus status) {
  // First check if charging
  if (status.chargeStage == CHARGING_STATE || status.chargeStage == CHARGE_FULL_STATE) {
    return Colors.blue;
  }
  
  // Then check movement state
  final moveState = status.moveState.toLowerCase();
  if (moveState == IDLE_STATE.toLowerCase()) {
    return Colors.grey;
  } else if (moveState == MOVING_STATE.toLowerCase()) {
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