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
    'HolaBot',
    'BellaBot',
    'SwiftBot',
    'PuduBot'
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
      setState(() {
        _isLoading = true;
      });

      try {
        final robot = PuduRobot(
          ip: _ipController.text,
          idDevice: _idDeviceController.text,
          name: _nameController.text,
          secretDevice: _secretDeviceController.text,
          region: _regionController.text,
          type: _selectedType,
        );

        await PuduDatabase.instance.insertPuduRobot(robot);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Robot registrado com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
          _formKey.currentState!.reset();
          _clearForm();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro ao registrar robot: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  void _clearForm() {
    _ipController.clear();
    _idDeviceController.clear();
    _nameController.clear();
    _secretDeviceController.clear();
    _regionController.clear();
    setState(() {
      _selectedType = 'KettyBot';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar Novo Robot'),
        backgroundColor: const Color.fromARGB(255, 246, 141, 45),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        const Text(
                          'Informação do Robot',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 246, 141, 45),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _ipController,
                          decoration: InputDecoration(
                            labelText: 'IP Address',
                            prefixIcon: const Icon(Icons.wifi),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor insira o IP';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _idDeviceController,
                          decoration: InputDecoration(
                            labelText: 'ID do Dispositivo',
                            prefixIcon: const Icon(Icons.devices),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor insira o ID do dispositivo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: 'Nome',
                            prefixIcon: const Icon(Icons.smart_toy),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor insira o nome';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _secretDeviceController,
                          decoration: InputDecoration(
                            labelText: 'Chave do Dispositivo',
                            prefixIcon: const Icon(Icons.key),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor insira a chave do dispositivo';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        TextFormField(
                          controller: _regionController,
                          decoration: InputDecoration(
                            labelText: 'Região',
                            prefixIcon: const Icon(Icons.location_on),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor insira a região';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        DropdownButtonFormField<String>(
                          value: _selectedType,
                          decoration: InputDecoration(
                            labelText: 'Tipo de Robot',
                            prefixIcon: const Icon(Icons.category),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 246, 141, 45),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Registrar Robot',
                          style: TextStyle(fontSize: 18),
                        ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isLoading ? null : _clearForm,
                  child: const Text('Limpar Formulário'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 