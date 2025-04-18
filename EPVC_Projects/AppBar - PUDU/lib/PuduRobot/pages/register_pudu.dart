import 'package:flutter/material.dart';
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
  String _selectedType = 'KettyBot';
  bool _isLoading = false;

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

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final robot = PuduRobot(
          ip: _ipController.text,
          idDevice: _idDeviceController.text,
          name: _nameController.text,
          secretDevice: _secretDeviceController.text,
          region: _regionController.text,
          type: _selectedType,
        );

        await PuduDatabase.instance.create(robot);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Robot registered successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error registering robot: $e'),
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
                            prefixIcon: Icon(Icons.precision_manufacturing_outlined),
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
                            onPressed: _isLoading ? null : _submitForm,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(255, 246, 141, 45),
                              foregroundColor: Colors.white,
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(color: Colors.white)
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