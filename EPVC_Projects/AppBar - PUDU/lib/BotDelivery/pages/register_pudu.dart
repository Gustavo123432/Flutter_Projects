import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../database/botdelivery_database.dart';
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
    'BellaBot'
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
          throw Exception('Tempo expirado ao conectar com o servidor');
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
            throw Exception('Nenhum grupo de robot encontrado');
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
          throw Exception('Tempo expirado ao conectar com o servidor');
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
            throw Exception('Nenhum robot encontrado');
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
          throw Exception('Tempo expirado ao conectar com o servidor');
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        if (responseBody['code'] == 0 && responseBody['data']['success'] == true) {
          // If device is added successfully, get the robot group
          await getRobotGroup();
        } else {
          throw Exception('Falha ao adicionar o robot: ${responseBody['msg'] ?? 'Erro desconhecido'}');
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
            content: Text('Robot registado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao registar o Robot: ${e.toString()}'),
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
        title: const Text('Registar Novo Robot'),
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
                          child: ClipOval(
                            child: Container(
                              color: const Color.fromARGB(255, 246, 141, 45),
                              child: Image.asset(
                                'lib/assets/bellabotwhiteandorange_icon.png',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _ipController,
                          cursorColor: Colors.black,
                          decoration: const InputDecoration(
                            labelText: 'Endereço IP',
                            labelStyle: TextStyle(color: Colors.black),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            prefixIcon: Icon(Icons.wifi, color: Colors.black),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o IP do robot';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _idDeviceController,
                          cursorColor: Colors.black,
                          decoration: const InputDecoration(
                            labelText: 'ID do Robot',
                            labelStyle: TextStyle(color: Colors.black),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            prefixIcon: Icon(Icons.devices, color: Colors.black),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o ID do Robot';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _nameController,
                          cursorColor: Colors.black,
                          decoration: InputDecoration(
                            labelText: 'Nome do Robot',
                            labelStyle: TextStyle(color: Colors.black),
                            border: const OutlineInputBorder(),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ), prefixIcon: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.asset(
                                'lib/assets/bellabot_icon.png',
                                width: 24,
                                height: 24,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o nome do robot';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _secretDeviceController,
                          cursorColor: Colors.black,
                          decoration: const InputDecoration(
                            labelText: 'Segredo do Robot',
                            labelStyle: TextStyle(color: Colors.black),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            prefixIcon: Icon(Icons.security, color: Colors.black),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o segredo do robot';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _regionController,
                          cursorColor: Colors.black,
                          decoration: const InputDecoration(
                            labelText: 'Região',
                            labelStyle: TextStyle(color: Colors.black),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            prefixIcon: Icon(Icons.location_on, color: Colors.black),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira a região do robot';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Modelo do Robot',
                            labelStyle: TextStyle(color: Colors.black),
                            border: OutlineInputBorder(),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.black),
                            ),
                            prefixIcon: Icon(Icons.category, color: Colors.black),
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
                                    'Registar Robot',
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
