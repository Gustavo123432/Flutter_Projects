import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CriaMaterialDPage extends StatefulWidget {
  @override
  _CriaMaterialDPageState createState() => _CriaMaterialDPageState();
}

class _CriaMaterialDPageState extends State<CriaMaterialDPage> {
  TextEditingController _codigoProdutoController = TextEditingController();
  TextEditingController _descricaoNomeController = TextEditingController();
  TextEditingController _unidadeController = TextEditingController();
  TextEditingController _notasController = TextEditingController();

  String _grupoSelecionado = '';
  List<String> _grupos = ['Grupo A', 'Grupo B', 'Grupo C'];
  TextEditingController _novoGrupoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Define o valor inicial como o primeiro valor da lista de grupos
    _grupoSelecionado = _grupos.isNotEmpty ? _grupos.first : '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
          appBar: AppBar(
     
        title: Text('Criar Material'),
        elevation: 2,
        shadowColor: Theme.of(context).shadowColor,
       
      ),
        body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(horizontal: 100, vertical: 8),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Campo de código de produto
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  Text('Código de Produto'),
                                  Divider(),
                                  TextFormField(
                                    controller: _codigoProdutoController,
                                    decoration: InputDecoration(
                                        labelText:
                                            'Introduza o código do produto',
                                        prefixIcon: Icon(Icons.abc,
                                            color: Colors.black),
                                        border: const OutlineInputBorder(),
                                        focusedBorder: OutlineInputBorder(
                                          borderSide: BorderSide(
                                              color:
                                                  Colors.deepPurple.shade300),
                                        ),
                                        labelStyle: const TextStyle(
                                            color: Colors.deepPurple)),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(width: 16), // Espaço entre os campos
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    children: [
                                      Text('Grupo'),
                                      IconButton(
                                        onPressed: () {
                                          _adicionarNovoGrupo(context);
                                        },
                                        icon: Icon(
                                          Icons.add,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Divider(),
                                  DropdownButton<String>(
                                    items: _grupos.map((grupo) {
                                      return DropdownMenuItem<String>(
                                        value: grupo,
                                        child: Text(grupo),
                                      );
                                    }).toList(),
                                    value: _grupoSelecionado,
                                    onChanged: (value) {
                                      setState(() {
                                        _grupoSelecionado = value!;
                                      });
                                    },
                                    hint: Text('Selecione o Grupo'),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    SizedBox(height: 16),
                    // Campo de descrição/nome
                    TextFormField(
                      controller: _descricaoNomeController,
                      decoration: InputDecoration(
                          labelText: 'Descrição/Nome',
                          prefixIcon: Icon(Icons.abc, color: Colors.black),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.deepPurple.shade300),
                          ),
                          labelStyle:
                              const TextStyle(color: Colors.deepPurple)),
                    ),
                    SizedBox(height: 16),
                    // Campo de unidade
                    TextFormField(
                      controller: _unidadeController,
                      decoration: InputDecoration(
                          labelText: 'Unidade',
                          prefixIcon: Icon(Icons.abc, color: Colors.black),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.deepPurple.shade300),
                          ),
                          labelStyle:
                              const TextStyle(color: Colors.deepPurple)),
                    ),
                    SizedBox(height: 16),
                    // Campo de notas
                    TextFormField(
                      controller: _notasController,
                      decoration: InputDecoration(
                          labelText: 'Notas',
                          prefixIcon: Icon(Icons.abc, color: Colors.black),
                          border: const OutlineInputBorder(),
                          focusedBorder: OutlineInputBorder(
                            borderSide:
                                BorderSide(color: Colors.deepPurple.shade300),
                          ),
                          labelStyle:
                              const TextStyle(color: Colors.deepPurple)),
                    ),
                    SizedBox(height: 32),
                    // Botão de criar material
                    ElevatedButton(
                      child: Text('Criar Material'),
                      onPressed: () {
                        // Adicione aqui a lógica para criar o material
                      },
                    ),
                  ],
                ),
              ),
            )));
  }

  void _adicionarNovoGrupo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Novo Grupo'),
          content: TextFormField(
            controller: _novoGrupoController,
            decoration: InputDecoration(labelText: 'Nome do Grupo'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_novoGrupoController.text.isNotEmpty) {
                  setState(() {
                    _grupos.add(_novoGrupoController.text);
                    _grupoSelecionado = _novoGrupoController.text;
                  });
                  _novoGrupoController.clear();
                  Navigator.pop(context);
                }
              },
              child: Text('Adicionar'),
            ),
          ],
        );
      },
    );
  }
}
