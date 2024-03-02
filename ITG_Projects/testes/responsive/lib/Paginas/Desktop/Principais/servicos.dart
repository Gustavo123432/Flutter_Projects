import 'package:flutter/material.dart';

import '../../../Componentes/drawer.dart';
import '../../../Componentes/drawerWidget.dart';
import '../../../Componentes/logout.dart';
import '../../../Paginas/Desktop/Secundárias/criarmaterial.dart';
import '../../../Responsive/responsive_Layout.dart';

class ServicosD extends StatefulWidget {
  @override
  _ServicosDState createState() => _ServicosDState();
}

class _ServicosDState extends State<ServicosD> {
  List<Map<String, dynamic>> _itens = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Serviços'),
        elevation: 2,
        shadowColor: Theme.of(context).shadowColor,
        actions: [
          GestureDetector(
            onTap: () {
              LogoutDialog();
            },
            child: const Icon(
              Icons.exit_to_app,
              size: 26.0,
            ),
          ),
        ],
      ),
      body: Center(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
               DrawerWidget(),
            Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              Card(
  color: Colors.black,
  child: Container(
    width: 255,
    height: 50,
    padding: EdgeInsets.symmetric(horizontal: 16), // Adiciona um espaçamento horizontal
    child: Row(
      children: [
        Expanded(
          child: TextField(
            style: TextStyle(color: Colors.white), // Estilo do texto da barra de busca
            decoration: InputDecoration(
              hintText: 'Pesquisar...', // Texto de dica dentro da barra de busca
              hintStyle: TextStyle(color: Colors.grey), // Estilo do texto de dica
              border: InputBorder.none, // Remove a borda da barra de busca
            ),
          ),
        ),
        IconButton(
          icon: Icon(Icons.search, color: Colors.white), // Ícone de pesquisa
          onPressed: () {
            // Adicione aqui a lógica para executar a pesquisa
          },
        ),
      ],
    ),
  ),
),


                Expanded(
                    child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.all(
                            Colors.blue), // Cor de fundo da linha de cabeçalho
                        dataRowColor: MaterialStateProperty.all(Colors
                            .grey[200]), // Cor de fundo das linhas de dados
                        dataRowHeight: 50, // Altura das linhas de dados
                        headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors
                                .white), // Estilo de texto para as células de cabeçalho
                        dataTextStyle: TextStyle(
                            color: Colors
                                .black), // Estilo de texto para as células de dados
                        dividerThickness:
                            2, // Espessura da linha divisória entre as linhas de dados
                        columnSpacing: 20, // Espaçamento entre as colunas
                        horizontalMargin: 20, // Margem horizontal da tabela
                        columns: [
                          DataColumn(label: Text('Código de Serviço')),
                          DataColumn(label: Text('Grupo')),
                          DataColumn(label: Text('Descrição/Nome')),
                          DataColumn(label: Text('Uni')),
                          DataColumn(label: Text('Preço de venda')),
                        ],
                        rows: [
                          ..._itens.map((item) {
                            return DataRow(cells: [
                              DataCell(Text('Nº Produto')),
                              DataCell(Text('Nº Produto')),
                              DataCell(Text('Nº Produto')),
                              DataCell(Text('Nº Produto')),
                              DataCell(Text('Nº Produto')),
                            ]);
                          }),
                        ],
                      ),
                    )
                  ],
                )),
              ],
            )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => CriaMaterialDPage()));
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
