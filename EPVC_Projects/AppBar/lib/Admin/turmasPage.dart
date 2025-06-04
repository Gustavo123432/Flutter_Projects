import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:appbar_epvc/Admin/drawerAdmin.dart';

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
    final response = await http.get(
        Uri.parse('https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=20'));
    if (response.statusCode == 200) {
      final List<dynamic> responseData = json.decode(response.body);
      List<Turma> fetchedTurmas =
          responseData.map((data) => Turma.fromJson(data)).toList();
      fetchedTurmas.sort(
          (a, b) => a.turma.compareTo(b.turma)); // Ordenar por ordem alfabética
      setState(() {
        turmas = fetchedTurmas;
      });
    } else {
      throw Exception('Failed to load turmas');
    }
  }

  void _addTurma(String turmaName) async {
    final response = await http.get(Uri.parse(
        'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=21&nome=$turmaName'));
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
        indexesToRemove
            .clear(); // Limpa a lista de índices ao sair do modo de remoção
      }
    });
  }

  void _toggleRemoveSelection(int index) async {
    if (removerMode) {
      final response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=22&nome=${turmas[index].turma}'));
      if (response.statusCode == 200) {
        _removeTurma(index);
        print('Turma removed successfully');
      } else {
        throw Exception('Failed to remove turma');
      }
      _toggleEditMode(); // Desativa o modo de remoção após a remoção da turma selecionada
    }
  }

  void _removeSelectedTurmas() async {
    for (int i = indexesToRemove.length - 1; i >= 0; i--) {
      final int index = indexesToRemove[i];
      final response = await http.get(Uri.parse(
          'https://appbar.epvc.pt/API/appBarAPI_GET.php?query_param=22&nome=${turmas[index].turma}'));

      if (response.statusCode == 200) {
        _removeTurma(index);
        print('Turma removed successfully');
      }
    }
    _toggleEditMode(); // Desativa o modo de remoção após a remoção das turmas selecionadas
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/assets/epvc.png'),
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Color.fromARGB(255, 255, 255, 255).withOpacity(0.85),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),
                Text(
                  'Gestão de Turmas',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 246, 141, 45),
                  ),
                ),
                SizedBox(height: 24),
                Expanded(
                  child: turmas.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhuma turma encontrada',
                            style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                          ),
                        )
                      : Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: GridView.builder(
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 1,
                              crossAxisSpacing: 24,
                              mainAxisSpacing: 24,
                              childAspectRatio: 3.5,
                            ),
                            itemCount: turmas.length,
                            itemBuilder: (context, index) {
                              final turma = turmas[index];
                              return Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Color.fromARGB(255, 246, 141, 45),
                                    child: Icon(Icons.class_, color: Colors.white),
                                  ),
                                  title: Text(
                                    turma.turma,
                                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                                  ),
                                  trailing: removerMode
                                      ? ElevatedButton.icon(
                                          style: ButtonStyle(
                                            backgroundColor: MaterialStateProperty.all(Colors.orange),
                                            shape: MaterialStateProperty.all(RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            )),
                                          ),
                                          onPressed: () {
                                            _toggleRemoveSelection(index);
                                          },
                                          icon: Icon(Icons.delete, color: Colors.white),
                                          label: Text('Eliminar', style: TextStyle(color: Colors.white)),
                                        )
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                ),
                SizedBox(height: 24),
                removerMode
                    ? ElevatedButton.icon(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.grey[700]),
                          shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          )),
                        ),
                        onPressed: () {
                          setState(() {
                            removerMode = false;
                          });
                        },
                        icon: Icon(Icons.cancel, color: Colors.white),
                        label: Text('Cancelar Remoção', style: TextStyle(color: Colors.white)),
                      )
                    : ElevatedButton.icon(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Color.fromARGB(255, 246, 141, 45)),
                          shape: MaterialStateProperty.all(RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          )),
                        ),
                        onPressed: () {
                          setState(() {
                            removerMode = true;
                          });
                        },
                        icon: Icon(Icons.delete_outline, color: Colors.white),
                        label: Text('Modo Remover', style: TextStyle(color: Colors.white)),
                      ),
                SizedBox(height: 24),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: SpeedDial(
        icon: Icons.add,
        iconTheme: IconThemeData(color: Colors.white),
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        children: [
          SpeedDialChild(
            child: Icon(Icons.add),
            label: 'Adicionar Turma',
            backgroundColor: Color.fromARGB(255, 246, 141, 45),
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    title: Text('Adicionar Turma'),
                    content: TextField(
                      controller: turmaController,
                      decoration: InputDecoration(
                        labelText: 'Nome da Turma',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Text('Cancelar'),
                      ),
                      ElevatedButton(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Color.fromARGB(255, 246, 141, 45)),
                        ),
                        onPressed: () {
                          _addTurma(turmaController.text);
                          turmaController.clear();
                          Navigator.of(context).pop();
                        },
                        child: Text('Adicionar', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  );
                },
              );
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
