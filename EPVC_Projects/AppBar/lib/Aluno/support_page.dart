import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SupportPage extends StatefulWidget {
  final String userEmail;

  const SupportPage({Key? key, required this.userEmail}) : super(key: key);

  @override
  _SupportPageState createState() => _SupportPageState();
}

class _SupportPageState extends State<SupportPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _customReasonController = TextEditingController();
  bool _isSending = false;

  final List<String> _reasons = [
    'Problema com o Carrinho',
    'Problema com o Pagamento',
    'Problema com Pedidos Anteriores',
    'Sugestão / Feedback',
    'Problema na aplicação',
    'Outra',
  ];
  
  String? _selectedReason;

  @override
  void dispose() {
    _customReasonController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _sendSupportTicket() async {
    // Determine the final reason to send
    String finalReason = _selectedReason == 'Outra' 
        ? _customReasonController.text.trim() 
        : _selectedReason ?? '';

    // Validate the form, including the custom reason field if applicable
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSending = true;
      });

      // --- Implement API call to send the ticket ---
      // You will need an API endpoint that accepts:
      // - user_email: widget.userEmail
      // - reason: finalReason
      // - description: _descriptionController.text
      // This API should send an email to the admin and save the report to the database.

      try {
        final response = await http.get(
          Uri.parse(
              'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=14.1&email=${widget.userEmail}&motivo=${Uri.encodeComponent(finalReason)}&descricao=${Uri.encodeComponent(_descriptionController.text)}'),
        );

        if (mounted) { // Check if the widget is still mounted before showing feedback
          if (response.statusCode == 200) {
            // Assuming a 200 status code means success based on typical API patterns
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ticket de suporte submetido com sucesso. Em breve será contactado.')),
            );
            // Clear fields on success
            _descriptionController.clear();
            if (_selectedReason == 'Outra') {
              _customReasonController.clear();
            }
            // Optionally reset dropdown
            setState(() {
              _selectedReason = null;
            });

          } else {
            // Handle server errors or non-200 status codes
            print('Failed to send support ticket: ${response.statusCode}');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Erro ao enviar ticket de suporte. Código: ${response.statusCode}')),
            );
          }
        }
      } catch (e) {
        // Handle network or other errors
        print('Error sending support ticket: $e');
        if (mounted) { // Check if the widget is still mounted before showing feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao enviar ticket de suporte: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) { // Ensure setState is called only if widget is still mounted
          setState(() {
            _isSending = false;
          });
        }
      }
      // --- End API call implementation ---
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suporte'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              Text(
                'Seu Email: ${widget.userEmail}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: 'Motivo do Ticket',
                  border: OutlineInputBorder(),
                ),
                value: _selectedReason,
                hint: Text('Selecione ou digite o motivo'),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedReason = newValue;
                  });
                },
                items: _reasons.map((String reason) {
                  return DropdownMenuItem<String>(
                    value: reason,
                    child: Text(reason),
                  );
                }).toList(),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecione o motivo.';
                  }
                  return null;
                },
              ),
              if (_selectedReason == 'Outra') ...[
                SizedBox(height: 16),
                TextFormField(
                  controller: _customReasonController,
                  decoration: InputDecoration(
                    labelText: 'Especifique o motivo',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (_selectedReason == 'Outra' && (value == null || value.isEmpty)) {
                      return 'Por favor, especifique o motivo.';
                    }
                    return null;
                  },
                ),
              ],
              SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descrição do Problema (Passos, detalhes)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, descreva o problema.';
                  }
                  return null;
                },
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSending ? null : _sendSupportTicket,
                child: _isSending
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text('Enviar Ticket'),
                style: ElevatedButton.styleFrom(
                   padding: EdgeInsets.symmetric(vertical: 12.0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 