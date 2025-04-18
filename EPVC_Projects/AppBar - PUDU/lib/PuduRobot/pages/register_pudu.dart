import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../database/pudu_database.dart';
import '../models/pudu_robot_model.dart';

class RegisterPudu extends StatefulWidget {
  const RegisterPudu({super.key});

  @override
  State<RegisterPudu> createState() => _RegisterPuduState();
}

class _RegisterPuduState extends State<RegisterPudu> {
  final _formKey = GlobalKey<FormState>();
  final _ipController = TextEditingController();
  final _idDeviceController = TextEditingController();
  final _nameController = TextEditingController();
  final _secretDeviceController = TextEditingController();
  final _regionController = TextEditingController();
  String _selectedType = 'BellaBot';
  bool _isLoading = false;
  String? idGroup;
  String? idRobot;
  String? shopName;
  String? groupName;
  String? robotName;

  final List<String> _robotTypes = [
    'KettyBot',
    'BellaBot',
    'HolaBot',
    'SwiftBot',
    'PuduBot',
  ];

  @override
  void dispose() {
    _ipController.dispose();
    _idDeviceController.dispose();
    _nameController.dispose();
    _secretDeviceController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> getRobotGroup() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://${_ipController.text}:5000/api/robot/groups?device=${_idDeviceController.text}',
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout ao conectar com o servidor');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['robotGroups'] is List) {
          final List<dynamic> data = json['data']['robotGroups'];
          if (data.isNotEmpty) {
            setState(() {
              idGroup = data[0]['id']?.toString() ?? '';
              groupName = data[0]['name']?.toString() ?? '';
              shopName = data[0]['shop_name']?.toString() ?? '';
            });
            await getRobotInterface();
          } else {
            throw Exception('Nenhum grupo de robô encontrado');
          }
        } else {
          throw Exception('Dados inválidos recebidos do servidor');
        }
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> getRobotInterface() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://${_ipController.text}:5000/api/robots?device=${_idDeviceController.text}&group_id=${idGroup}',
        ),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout ao conectar com o servidor');
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> json = jsonDecode(response.body);
        if (json['data'] != null && json['data']['robots'] is List) {
          final List<dynamic> robots = json['data']['robots'];
          if (robots.isNotEmpty) {
            setState(() {
              idRobot = robots[0]['id']?.toString() ?? '';
              robotName = robots[0]['name']?.toString() ?? '';
              shopName = robots[0]['shop_name']?.toString() ?? '';
            });
            await _submitForm();
          } else {
            throw Exception('Nenhum robô encontrado');
          }
        } else {
          throw Exception('Dados inválidos recebidos do servidor');
        }
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> addRobot() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      // First, add the device to the server
      final response = await http.post(
        Uri.parse('http://${_ipController.text}:5000/api/add/device'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'deviceName': _nameController.text,
          'deviceId': _idDeviceController.text,
          'deviceSecret': _secretDeviceController.text,
          'region': _regionController.text,
        }),
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
          await getRobotGroup();
        } else {
          throw Exception('Falha ao adicionar o robô: ${responseBody['msg'] ?? 'Erro desconhecido'}');
        }
      } else {
        throw Exception('Erro ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
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

  Future<void> _submitForm() async {
    try {
      final robot = PuduRobot(
        name: _nameController.text,
        type: _selectedType,
        ip: _ipController.text,
        idDevice: _idDeviceController.text,
        secretDevice: _secretDeviceController.text,
        region: _regionController.text,
        idGroup: idGroup ?? '',
        groupName: groupName ?? '',
        shopName: shopName ?? '',
        robotIdd: idRobot ?? '',
        nameRobot: robotName ?? '',
      );

      final dbHelper = PuduDatabase.instance;
      await dbHelper.create(robot);

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Robot registrado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registrar o Robot: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register New Robot'),
        backgroundColor: const Color.fromARGB(255, 246, 141, 45),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: const BoxDecoration(
                            color: Color.fromARGB(255, 246, 141, 45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.precision_manufacturing,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _ipController,
                          decoration: const InputDecoration(
                            labelText: 'IP Address',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.wifi),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter IP address';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _idDeviceController,
                          decoration: const InputDecoration(
                            labelText: 'Device ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.devices),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter Device ID';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          decoration: const InputDecoration(
                            labelText: 'Robot Name',
                            border: OutlineInputBorder(),
                            prefixIcon:
                                Icon(Icons.precision_manufacturing_outlined),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter robot name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _secretDeviceController,
                          decoration: const InputDecoration(
                            labelText: 'Device Secret',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.security),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter device secret';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _regionController,
                          decoration: const InputDecoration(
                            labelText: 'Region',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter region';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Robot Type',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.category),
                          ),
                          items: _robotTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedType = newValue;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : addRobot,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 246, 141, 45),
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    'Register Robot',
                                    style: TextStyle(fontSize: 18),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
