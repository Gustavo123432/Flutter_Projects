import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:appBar/Admin/drawerAdmin.dart';

class Turma {
  final String turma;
  bool selected;

  Turma({required this.turma, this.selected = false});

  factory Turma.fromJson(Map<String, dynamic> json) {
    return Turma(
      turma: json['Turma'],
    );
  }
}

class TurmasPage extends StatefulWidget {
  @override
  _TurmasPageState createState() => _TurmasPageState();
}

class _TurmasPageState extends State<TurmasPage> {
  List<Turma> turmas = [];
  TextEditingController turmaController = TextEditingController();
  bool removerMode = false;
  List<int> indexesToRemove = [];

  @override
  void initState() {
    super.initState();
    _fetchTurmas();
  }

  Future<void> _fetchTurmas() async {
    final response = await http.get(Uri.parse('http://appbar.epvc.pt//appBarAPI_GET.php?query_param=20'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      List<Turma> fetchedTurmas = responseData.map((data) => Turma.fromJson(data)).toList();
      fetchedTurmas.sort((a, b) => a.turma.compareTo(b.turma)); // Ordenar por ordem alfabética
      setState(() {
        turmas = fetchedTurmas;
      });
    } else {
      throw Exception('Failed to load turmas');
    }
  }

  void _addTurma(String turmaName) async {
    final response = await http.get(
        Uri.parse('http://appbar.epvc.pt//appBarAPI_GET.php?query_param=21&nome=$turmaName'));
    if (response.statusCode == 200) {
      setState(() {
        turmas.add(Turma(turma: turmaName));
      });
    } else {
      throw Exception('Failed to add turma');
    }
  }

  void _removeTurma(int index) {
    setState(() {
      turmas.removeAt(index);
    });
  }

  void _toggleEditMode() {
    setState(() {
      removerMode = !removerMode;
      if (!removerMode) {
        indexesToRemove.clear(); // Limpa a lista de índices ao sair do modo de remoção
      }
    });
  }

  void _toggleRemoveSelection(int index) async {
    if (removerMode) {
      final response = await http.get(
        Uri.parse('http://appbar.epvc.pt//appBarAPI_GET.php?query_param=22&nome=${turmas[index].turma}')
      );
      if (response.statusCode == 200) {
        _removeTurma(index);
      } else {
        throw Exception('Failed to remove turma');
      }
      _toggleEditMode(); // Desativa o modo de remoção após a remoção da turma selecionada
    }
  }

  void _removeSelectedTurmas() async {
    for (int i = indexesToRemove.length - 1; i >= 0; i--) {
      final int index = indexesToRemove[i];
      final response = await http.get(
          Uri.parse('http://appbar.epvc.pt//appBarAPI_GET.php?query_param=22&nome=${turmas[index].turma}'));

      if (response.statusCode == 200) {
        _removeTurma(index);
      }
    }
    _toggleEditMode(); // Desativa o modo de remoção após a remoção das turmas selecionadas
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        title: Text('Turmas'),
      ),
      drawer:DrawerAdmin(),
      body: Container(
        width: double.infinity, // Usar toda a largura disponível
        height: double.infinity, // Usar toda a altura disponível
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
                'lib/assets/epvc.png'), // Caminho para a sua imagem de fundo
            // fit: BoxFit.cover,
          ),
        ),
        child: Stack(
          children: [
            // Imagem de fundo
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255)
                      .withOpacity(0.80), // Cor preta com opacidade de 40%
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                child: DataTable(
                  columns: [
                    DataColumn(label: Text('Turma')),
                    DataColumn(label: Text('')),
                  ],
                  rows: turmas.map((turma) {
                    return DataRow(
                      cells: [
                        DataCell(Text(turma.turma)),
                        DataCell(
                          removerMode
                              ? ElevatedButton(
                                  onPressed: () {
                                    _toggleRemoveSelection(turmas.indexOf(turma));
                                  },
                                  child: indexesToRemove.contains(turmas.indexOf(turma))
                                      ? Text('Cancelar')
                                      : Text('Eliminar'),
                                )
                              : SizedBox.shrink(),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 130, 201, 189),
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Adicionar Turma',
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Adicionar Turma'),
                    content: TextField(
                      controller: turmaController,
                      decoration: InputDecoration(labelText: 'Nome da Turma'),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          _addTurma(turmaController.text);
                          Navigator.of(context).pop();
                        },
                        child: Text('Adicionar'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          SpeedDialChild(
            child: Icon(Icons.delete),
            label: 'Remover Turma',
            onTap: () {
              _removeSelectedTurmas();
            },
          ),
        ],
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    home: TurmasPage(),
  ));
}
