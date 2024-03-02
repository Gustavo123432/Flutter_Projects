import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CreateProjetoDPage extends StatefulWidget {
  @override
  _CreateProjetoDPageState createState() => _CreateProjetoDPageState();
}

class _CreateProjetoDPageState extends State<CreateProjetoDPage> {
  String _titulo = '';
  String _localizacao = '';
  DateTime? _dataInicio;
  DateTime? _dataFim;
  String _precoTotal = '';
  String _nomeItem = '';
  String _custoItem = '';
  List<Map<String, dynamic>> _itens = [];
  bool _camposPreenchidos = false;
  String _descricaoItem = '';
  double _materialItem = 0.0;
  double _maoObraItem = 0.0;
  double totalMaterialCost = 0.0;
  double totalLaborCost = 0.0;
  double _lucroEstimado1 = 0.0;
  double _lucroEstimado2 = 0.0;
bool incluiIVA = false; 

  List<DataRow> _linhas = [];
  List<bool> _showValoresIvaList =
      []; // Lista para armazenar o estado da checkbox de cada linha

  // Lista de controladores para os campos de texto
  List<TextEditingController> _controllers = [];

  @override
  void dispose() {
    // Limpa os controladores ao descartar o estado do widget
    _controllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    totalMaterialCost =
        _itens.fold(0, (sum, item) => sum + (item['material'] ?? 0.0));
    totalLaborCost =
        _itens.fold(0, (sum, item) => sum + (item['maoObra'] ?? 0.0));
    double totalCost = totalMaterialCost + totalLaborCost;

    return Scaffold(
         appBar: AppBar(
        
        title: Text('Criar Projeto'),
        elevation: 2,
        shadowColor: Theme.of(context).shadowColor,
      
      ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Card(
              margin: EdgeInsets.all(8.0),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'Informações do Projeto',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 16.0),
                                  ],
                                ),
                                Divider(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: const InputDecoration(
                                            labelText: 'Número de Orçamento'),
                                        onChanged: (value) {
                                          setState(() {
                                            _titulo = value;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                            labelText: 'Localização'),
                                        onChanged: (value) {
                                          setState(() {
                                            _localizacao = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        _dataInicio == null
                                            ? 'Data de Início'
                                            : 'Data de Início: ${_dataInicio!.day}/${_dataInicio!.month}/${_dataInicio!.year}',
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.calendar_today),
                                      onPressed: () async {
                                        final selectedDate =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (selectedDate != null) {
                                          setState(() {
                                            _dataInicio = selectedDate;
                                          });
                                        }
                                      },
                                    ),
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Expanded(
                                      child: Text(
                                        _dataFim == null
                                            ? 'Data de Fim'
                                            : 'Data de Fim: ${_dataFim!.day}/${_dataFim!.month}/${_dataFim!.year}',
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.calendar_today),
                                      onPressed: () async {
                                        final selectedDate =
                                            await showDatePicker(
                                          context: context,
                                          initialDate: DateTime.now(),
                                          firstDate: DateTime(2000),
                                          lastDate: DateTime(2100),
                                        );
                                        if (selectedDate != null) {
                                          setState(() {
                                            _dataFim = selectedDate;
                                          });
                                        }
                                      },
                                    ),
                                  ],
                                ),

                                SizedBox(height: 24.0),
                                // Dados do Cliente
                                Text(
                                  'Dados do Cliente',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                            labelText: 'Nome Cliente'),
                                        onChanged: (value) {
                                          setState(() {
                                            _localizacao = value;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10.0),
                                    Expanded(
                                      child: TextFormField(
                                        decoration: InputDecoration(
                                            labelText: 'Contacto'),
                                        onChanged: (value) {
                                          setState(() {
                                            _localizacao = value;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10.0),
                                    Expanded(
                                      child: TextFormField(
                                        decoration:
                                            InputDecoration(labelText: 'Email'),
                                        onChanged: (value) {
                                          setState(() {
                                            _localizacao = value;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 10.0),
                                    Expanded(
                                      child: TextFormField(
                                        decoration:
                                            InputDecoration(labelText: 'NIF'),
                                        onChanged: (value) {
                                          setState(() {
                                            _localizacao = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16.0),
                                // Orçamento
                                Text(
                                  'Orçamento',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(),

                                DataTable(
                                  columns: [
                                    DataColumn(label: Text('Código')),
                                    DataColumn(label: Text('Descrição/Nome')),
                                      DataColumn(label: Text('Unidades')),
                                    DataColumn(label: Text('Qtd')),
                                  
                                    DataColumn(label: Text('Descontos')),
                                    DataColumn(label: Text('Preço Total')),
                                  ],
                                  rows: _linhas.isNotEmpty
                                      ? _linhas
                                      : [
                                          DataRow(cells: [
                                            DataCell(
                                                Text('Nenhum dado encontrado')),
                                            DataCell(Text('')),
                                            DataCell(Text('')),
                                            DataCell(Text('')),
                                            DataCell(Text('')),
                                            DataCell(Text('')),
                                          ])
                                        ],
                                ),
                                SizedBox(height: 16.0),
// TextButton para adicionar linhas
                                Row(
                                  mainAxisAlignment: MainAxisAlignment
                                      .start, // Alinha o botão à esquerda
                                  children: [
                                    TextButton(
                                      onPressed: _adicionarLinha,
                                      child: Text('Adicionar Linha'),
                                    ),
                                  ],
                                ),

                                SizedBox(height: 16.0),
                                // Observações
                                Text(
                                  'Observações',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Divider(),
                                TextFormField(
                                  decoration:
                                      InputDecoration(labelText: 'Observações'),
                                  maxLines: 3,
                                  onChanged: (value) {
                                    // Adicione o código para lidar com as observações
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 5),
      Expanded(
  flex: 1,
  child: Card(
    margin: EdgeInsets.all(8.0),
    child: Padding(
      padding: EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Inclui IVA?'), // Label para o checkbox
              Checkbox(  // Checkbox para selecionar se inclui ou não IVA
                value: incluiIVA,  // variável que representa se IVA está incluído ou não
                onChanged: (bool? newValue) {
                  // Função chamada quando o estado do checkbox é alterado
                  // Aqui você deve atualizar a variável que controla se IVA está incluído ou não
                  setState(() {
                    incluiIVA = newValue!; // Atualizando o estado do checkbox
                  });
                },
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total de material:'),
              Text('Total de mão de obra:'),
              Text('Total de orçamento:'),
              Text('Potencial Lucro:'),
            ],
          ),
        ],
      ),
    ),
  ),
),

        ],
      ),
    );
  }

  void _adicionarLinha() {
    setState(() {
      // Controladores para os campos de texto
      TextEditingController codigoController = TextEditingController();
      TextEditingController descricaoController = TextEditingController();
      TextEditingController qtdController = TextEditingController();
      TextEditingController precoController = TextEditingController();
      TextEditingController valoresIvaController = TextEditingController();
      TextEditingController descontosController = TextEditingController();

      _controllers.addAll([
        codigoController,
        descricaoController,
        qtdController,
        precoController,
        valoresIvaController,
        descontosController,
      ]);

      bool showValoresIva = false; // Estado inicial da checkbox para esta linha
      _showValoresIvaList.add(showValoresIva); // Adiciona o estado à lista

      // Adicione a criação da checkbox diretamente na lista de células para a linha de dados
      List<DataCell> cells = [
        DataCell(TextField(
          controller: codigoController,
          decoration: InputDecoration(
            hintText: 'Código',
          ),
        )),
      DataCell(Text(
       "Info vem da BD"
        
        )),
         DataCell(Text(
       "Info vem da BD"
        
        )),
        DataCell(TextField(
          controller: qtdController,
          decoration: InputDecoration(
            hintText: 'Qtd',
          ),
        )),
          
 
        DataCell(TextField(
          controller: descontosController,
          decoration: InputDecoration(
            hintText: 'Descontos',
          ),
        )),
        DataCell(TextField(
          controller: precoController,
          decoration: InputDecoration(
            hintText: 'Preço Total',
          ),
        )),
      ];

      _linhas.add(DataRow(cells: cells));
    });
  }

  // Método para atualizar a visibilidade dos valores de IVA
  void _atualizarVisibilidadeValoresIva() {
    for (int i = 0; i < _linhas.length; i++) {
      DataRow row = _linhas[i];
      List<DataCell> cells = row.cells;
      bool showValoresIva = _showValoresIvaList.length > i
          ? _showValoresIvaList[i]
          : false; // Estado da checkbox para esta linha
      DataCell checkboxCell = cells[5]; // Célula da checkbox
      DataCell valoresIvaCell = cells[6]; // Célula dos valores de IVA

      checkboxCell = DataCell(Checkbox(
        value:
            showValoresIva, // Usa o estado da lista para determinar o valor da checkbox
        onChanged: (bool? value) {
          setState(() {
            showValoresIva = value ?? false;
            _showValoresIvaList[i] =
                showValoresIva; // Atualiza o estado na lista
          });
        },
      ));

      valoresIvaCell = DataCell(Visibility(
        visible:
            showValoresIva, // Usa o estado da lista para determinar a visibilidade
        child: TextField(
          controller: _controllers[i * 6 +
              4], // o controlador de valoresIvaController na posição correta na lista
          decoration: InputDecoration(
            hintText: 'Valores de IVA',
          ),
        ),
      ));

      // Atualiza as células da checkbox e dos valores de IVA
      cells[5] = checkboxCell;
      cells[6] = valoresIvaCell;
      _linhas[i] = DataRow(cells: cells);
    }
  }
}
