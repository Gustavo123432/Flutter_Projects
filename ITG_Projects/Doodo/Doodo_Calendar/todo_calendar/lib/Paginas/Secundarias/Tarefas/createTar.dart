// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:todo_itg/Paginas/Principais/defaultTar.dart';


class CreateTar extends StatefulWidget {
  const CreateTar({super.key});

  @override
  _CreateTarState createState() => _CreateTarState();
}

class _CreateTarState extends State<CreateTar> {
  final TextEditingController _controller = TextEditingController();

  List Users = [];
  String selectedOption = '1';
  bool isRecurrentChecked = false;
  OverlayEntry? overlayEntry;
  dynamic tar;
  dynamic length;
//Recurrencia Variaveis
  //Principais(Checkbox)
  bool isCheckedY = false;
  bool isCheckedN = false;
  bool isCheckedDaily = false;
  bool isCheckedWeekly = true;
  bool isCheckedMonthly = false;
  bool isCheckedAnualy = false;
//semanalmente
  bool isCheckedSegunda = false;
  bool isCheckedTerca = false;
  bool isCheckedQuarta = false;
  bool isCheckedQuinta = false;
  bool isCheckedSexta = false;
  bool isCheckedSabado = false;
  bool isCheckedDomingo = false;
  bool isCheckedAll = false;
//diariamente
  bool DisCheckedall = false;
  bool DisCheckedCada = false;
  final TextEditingController _controllerD = TextEditingController();
//Mensalmente
  bool MisCheckedDias = false;
  bool MisCheckedSemana = false;
  final TextEditingController _controllerM = TextEditingController();
  final TextEditingController _controllerM2 = TextEditingController();
  final TextEditingController _controllerM3 = TextEditingController();
  List<String> orderM = <String>[
    'Primeiro',
    'Segundo',
    'Teceiro',
    'Quarto',
    'Ùltimo'
  ];
  dynamic orderm = 'Primeiro';
  List<String> orderM2 = <String>[
    'dia',
    'dia da semana',
    'Fim de Semana',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sabado',
    'Domingo'
  ];
  dynamic orderm2 = 'Segunda';
//Anualmente
  bool AisChecked1 = false;
  bool AisChecked2 = false;
  final TextEditingController _controllerA = TextEditingController();
  final TextEditingController _controllerA1 = TextEditingController();
  final TextEditingController _controllerA2 = TextEditingController();
  List<String> orderAnualM1 = <String>[
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro"
  ];

  dynamic orderanualM1 = 'Janeiro';
  List<String> orderAnualM2 = <String>[
    'Primeiro',
    'Segundo',
    'Teceiro',
    'Quarto',
    'Ùltimo'
  ];
  dynamic orderanualM2 = 'Primeiro';
  List<String> orderAnualsM3 = <String>[
    'dia',
    'dia da semana',
    'Fim de Semana',
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sabado',
    'Domingo'
  ];
  dynamic orderanualsM3 = 'Segunda';

  List<String> orderAnualM4 = <String>[
    "Janeiro",
    "Fevereiro",
    "Março",
    "Abril",
    "Maio",
    "Junho",
    "Julho",
    "Agosto",
    "Setembro",
    "Outubro",
    "Novembro",
    "Dezembro"
  ];
  dynamic orderanualM4 = 'Janeiro';
//Range Recurrence
  bool RRisCheckedAcabaEm = false;
  bool RRisCheckedAcabaDepois = false;
  bool RRisCheckedSemFim = false;
  final TextEditingController _controllerRR = TextEditingController();

  bool isCheckedAdditional = false;

  final TextEditingController _dateController = TextEditingController();
  TextEditingController dateController = TextEditingController();
  late DateTime _selectedDate;
  late DateTime selectedDate;

  //Fim Recorrencia Variaveis

//Criar Tarefas(Card Principal) Variaveis

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController NameClientController = TextEditingController();
  final TextEditingController LocRController = TextEditingController();
  final TextEditingController LocEController = TextEditingController();

  DateTime selectedStartDate = DateTime.now();
  TimeOfDay selectedStartTime = TimeOfDay.now();
  DateTime selectedEndDate = DateTime.now();
  TimeOfDay selectedEndTime = TimeOfDay.now();
  dynamic selectedColor = Colors.blue;
  String formattedStartDate = '';
  String formattedEndDate = '';
  String formattedStartTime = '';
  String formattedEndTime = '';


//Fim de Variaveis

  @override
  void initState() {
    super.initState();
    _controller.text = "0";
    _controllerA.text = "0";
    _controllerA1.text = "0";
    _controllerA2.text = "0";
    _controllerD.text = "0";
    _controllerM.text = "0";
    _controllerM2.text = "0";
    _controllerM3.text = "0";
    _controllerRR.text = "0";
    _updateDateText(DateTime.now());
    updateDateText(DateTime.now());
    getUserList();
  }

  void _updateDateText(DateTime date) {
    _selectedDate = date;
    _dateController.text = "${date.toLocal()}".split(' ')[0];
  }

  void updateDateText(DateTime date) {
    selectedDate = date;
    dateController.text = "${date.toLocal()}".split(' ')[0];
  }

  createTar(String title, String descrip, String dataini, String tempini,
      String dateend, String tempend, String selectedColor, int id, String nomeC, String LocR, String LocE) async {
    dynamic response = await http.get(Uri.parse(
        "https://services.interagit.com/API/api_Calendar.php?query_param=15&Titulo=$title&Descrip=$descrip&DataM=$dataini&TempM=$tempini&TempEnd=$tempend&DateEnd=$dateend&NameCliente=$nomeC&LocI=$LocR&LocF=$LocE&&id=$id"));
    if (response.statusCode == 200) {
      setState(() {
      });
    }
  }

  getUserList() async {
    dynamic response = await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=4'));
    if (response.statusCode == 200) {
      setState(() {
        Users = jsonDecode(response.body) as List;
      });
      length = int.parse(Users.length.toString());

      return Users;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Tarefa'),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Card(
                elevation: 3,
                child: Container(
                  width: 575,
                  height: 575,
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(children: [
                      SizedBox(
                        child: TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            labelText: 'Título',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 50,
                        child: TextField(
                          maxLines: null,
                          expands: true,
                          keyboardType: TextInputType.multiline,
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            labelText: 'Observações',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.description),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: NameClientController,
                        decoration: const InputDecoration(
                          labelText: 'Nome Cliente',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: LocRController,
                              decoration: const InputDecoration(
                                labelText: 'Localização de Recolha',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: LocEController,
                              decoration: const InputDecoration(
                                labelText: 'Localização de Entrega',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.location_on),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: selectedStartDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );

                                    if (pickedDate != null) {
                                      setState(() {
                                        selectedStartDate = pickedDate;
                                        formattedStartDate =
                                            '${pickedDate.year}-${pickedDate.month}-${pickedDate.day}';
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    minimumSize: const Size(275, 50),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        formattedStartDate.isEmpty
                                            ? MainAxisAlignment.center
                                            : MainAxisAlignment.start,
                                    children: [
                                      if (formattedStartDate.isEmpty)
                                        const Text(
                                          'Data Início',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Data Início: $formattedStartDate',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    DateTime? pickedDate = await showDatePicker(
                                      context: context,
                                      initialDate: selectedEndDate,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime(2101),
                                    );

                                    if (pickedDate != null) {
                                      setState(() {
                                        selectedEndDate = pickedDate;
                                        formattedEndDate =
                                            '${pickedDate.year}-${pickedDate.month}-${pickedDate.day}';
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    minimumSize: const Size(275, 50),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: formattedEndDate.isEmpty
                                        ? MainAxisAlignment.center
                                        : MainAxisAlignment.start,
                                    children: [
                                      if (formattedEndDate.isEmpty)
                                        const Text(
                                          'Data Fim',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Data Fim: $formattedEndDate',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    TimeOfDay? pickedTime =
                                        await showTimePicker(
                                      context: context,
                                      initialTime: selectedStartTime,
                                      builder: (BuildContext context,
                                          Widget? child) {
                                        return MediaQuery(
                                          data: MediaQuery.of(context).copyWith(
                                            alwaysUse24HourFormat: true,
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );

                                    if (pickedTime != null) {
                                      setState(() {
                                        selectedStartTime = pickedTime;
                                        formattedStartTime =
                                            '${pickedTime.hour}:${pickedTime.minute}';
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    minimumSize: const Size(275, 50),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        formattedStartTime.isEmpty
                                            ? MainAxisAlignment.center
                                            : MainAxisAlignment.start,
                                    children: [
                                      if (formattedStartTime.isEmpty)
                                        const Text(
                                          'Hora Inicio',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Hora Inicio: $formattedStartTime',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () async {
                                    TimeOfDay? pickedTime =
                                        await showTimePicker(
                                      context: context,
                                      initialTime: selectedEndTime,
                                      builder: (BuildContext context,
                                          Widget? child) {
                                        return MediaQuery(
                                          data: MediaQuery.of(context).copyWith(
                                            alwaysUse24HourFormat: true,
                                          ),
                                          child: child!,
                                        );
                                      },
                                    );

                                    if (pickedTime != null) {
                                      setState(() {
                                        selectedEndTime = pickedTime;
                                        formattedEndTime =
                                            '${pickedTime.hour}:${pickedTime.minute}';
                                      });
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    minimumSize: const Size(275, 50),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: formattedEndTime.isEmpty
                                        ? MainAxisAlignment.center
                                        : MainAxisAlignment.start,
                                    children: [
                                      if (formattedEndTime.isEmpty)
                                        const Text(
                                          'Hora Fim',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Hora Fim: $formattedEndTime',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Column(children: [
                        Row(
                          children: [
                            const Text("Escolha um motorista:  "),
                            DropdownButton(
                              value: selectedOption,
                              icon: const Icon(Icons.expand_more),
                              elevation: 16,
                              style: const TextStyle(color: Colors.black),
                              underline: Container(
                                height: 2,
                                color: Colors.blue,
                              ),
                              items: Users.map(
                                (category) {
                                  return DropdownMenuItem(
                                    value: category['IdUser'].toString(),
                                    child: Text(category['Name'].toString()),
                                  );
                                },
                              ).toList(),
                              onChanged: (v) {
                                setState(() {
                                  selectedOption = v.toString();
                                });
                              },
                            ),
                          ],
                        ),
                      ]),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            child: const Text('Cancelar'),
                            onPressed: () {
                              Navigator.of(context)
                                  .pop(); // Close the AlertDialog
                            },
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              emptyFields();
                            },
                            child: const Text('Confirmar'),
                          ),
                        ],
                      ),
                    ]),
                  ),
                )),
            /*      Card(
              elevation: 3,
              child: Container(
                width: 675,
                height: 525,
                padding: EdgeInsets.all(16),
                child: Center(
                    child: Column(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Recorrente?"),
                        Row(
                          children: [
                            Row(
                              children: [
                                Checkbox(
                                  value: isCheckedY,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      isCheckedY = value ?? false;

                                      isCheckedN = false;
                                    });
                                  },
                                ),
                                Text('Sim'),
                              ],
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: isCheckedN,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      isCheckedN = value ?? false;
                                      isCheckedY = false;
                                    });
                                  },
                                ),
                                Text('Não'),
                              ],
                            ),
                          ],
                        ),
                        Container(
                          height: 1,
                          width: 600,
                          color: Colors.black,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Checkbox(
                                      value: isCheckedDaily,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          isCheckedDaily = value ?? false;
                                          isCheckedWeekly = !isCheckedDaily;
                                          isCheckedMonthly = false;
                                          isCheckedAnualy = false;
                                        });
                                      },
                                    ),
                                    Text('Diariamente'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: isCheckedWeekly,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          isCheckedWeekly = value ?? false;
                                          isCheckedDaily = false;
                                          isCheckedMonthly = false;
                                          isCheckedAnualy = false;
                                        });
                                      },
                                    ),
                                    Text('Semanalmente'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: isCheckedMonthly,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          isCheckedMonthly = value ?? false;
                                          isCheckedWeekly = !isCheckedMonthly;
                                          isCheckedAnualy = false;
                                          isCheckedDaily = false;
                                        });
                                      },
                                    ),
                                    const Text('Mensalmente'),
                                  ],
                                ),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: isCheckedAnualy,
                                      onChanged: (bool? value) {
                                        setState(() {
                                          isCheckedAnualy = value ?? false;
                                          isCheckedWeekly = !isCheckedAnualy;
                                          isCheckedMonthly = false;
                                          isCheckedDaily = false;
                                        });
                                      },
                                    ),
                                    const Text('Anualmente'),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              width: 1,
                              height: 200,
                              color: Colors.black,
                            ),
                            Column(
                              children: [
                                //semanalmente
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: Checkbox(
                                                value: isCheckedSegunda,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isCheckedSegunda =
                                                        value ?? false;
                                                    isCheckedAll = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child:
                                                  const Text('Segunda-Feira'),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: Checkbox(
                                                value: isCheckedSexta,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isCheckedSexta =
                                                        value ?? false;
                                                    isCheckedAll = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: const Text('Sexta-Feira'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: Checkbox(
                                                value: isCheckedTerca,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isCheckedTerca =
                                                        value ?? false;
                                                    isCheckedAll = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: const Text('Terça-Feira'),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: Checkbox(
                                                value: isCheckedSabado,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isCheckedSabado =
                                                        value ?? false;
                                                    isCheckedAll = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: const Text('Sábado'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: Checkbox(
                                                value: isCheckedQuarta,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isCheckedQuarta =
                                                        value ?? false;
                                                    isCheckedAll = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: const Text('Quarta-Feira'),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: Checkbox(
                                                value: isCheckedDomingo,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isCheckedDomingo =
                                                        value ?? false;
                                                    isCheckedAll = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: const Text('Domingo'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: Checkbox(
                                                value: isCheckedQuinta,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isCheckedQuinta =
                                                        value ?? false;
                                                    isCheckedAll = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: const Text('Quinta-Feira'),
                                            ),
                                          ],
                                        ),
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child: Checkbox(
                                                value: isCheckedAll,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    isCheckedAll =
                                                        value ?? false;
                                                    isCheckedSegunda = false;
                                                    isCheckedTerca = false;
                                                    isCheckedQuarta = false;
                                                    isCheckedQuinta = false;
                                                    isCheckedSexta = false;
                                                    isCheckedSabado = false;
                                                    isCheckedDomingo = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedDaily &&
                                                  isCheckedWeekly,
                                              child:
                                                  const Text('Todos os dias'),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
//diariamente
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Visibility(
                                          visible: isCheckedDaily,
                                          child: Checkbox(
                                            value: DisCheckedall,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                DisCheckedall = value ?? false;
                                                DisCheckedCada = false;
                                              });
                                            },
                                          ),
                                        ),
                                        Visibility(
                                          visible: isCheckedDaily,
                                          child: const Text('Todos os dias'),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              isCheckedDaily &&
                                              !isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: Checkbox(
                                            value: DisCheckedCada,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                DisCheckedCada = value ?? false;
                                                DisCheckedall = false;
                                              });
                                            },
                                          ),
                                        ),
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              isCheckedDaily &&
                                              !isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: const Text('A cada'),
                                        ),
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              isCheckedDaily &&
                                              !isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: Container(
                                            width: 60.0,
                                            height: 40,
                                            foregroundDecoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              border: Border.all(
                                                color: Colors.blueGrey,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                Expanded(
                                                  flex: 1,
                                                  child: TextFormField(
                                                    textAlign: TextAlign.center,
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5.0),
                                                      ),
                                                    ),
                                                    controller: _controllerD,
                                                    //  onChanged: _controller.text.toString() == "" ? _controller.text == "0" : _controller.text=="" ,
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                      decimal: false,
                                                      signed: true,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 38.0,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      Container(
                                                        decoration:
                                                            const BoxDecoration(
                                                          border: Border(
                                                            bottom: BorderSide(
                                                              width: 0.5,
                                                            ),
                                                          ),
                                                        ),
                                                        child: InkWell(
                                                          child: const Icon(
                                                            Icons.arrow_drop_up,
                                                            size: 18.0,
                                                          ),
                                                          onTap: () {
                                                            int currentValueD =
                                                                int.parse(
                                                                    _controllerD
                                                                        .text);
                                                            setState(() {
                                                              currentValueD++;
                                                              _controllerD
                                                                      .text =
                                                                  (currentValueD)
                                                                      .toString(); // incrementing value
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      InkWell(
                                                        child: const Icon(
                                                          Icons.arrow_drop_down,
                                                          size: 18.0,
                                                        ),
                                                        onTap: () {
                                                          int currentValueD =
                                                              int.parse(
                                                                  _controllerD
                                                                      .text);
                                                          setState(() {
                                                            print(
                                                                "Setting state");
                                                            currentValueD--;
                                                            _controllerD.text =
                                                                (currentValueD >
                                                                            0
                                                                        ? currentValueD
                                                                        : 0)
                                                                    .toString(); // decrementing value
                                                          });
                                                        },
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                            visible: !isCheckedWeekly &&
                                                isCheckedDaily &&
                                                !isCheckedMonthly &&
                                                !isCheckedAnualy,
                                            child: const Text("dias")),
                                      ],
                                    ),
                                  ],
                                ),
                                //Mensalmente
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              !isCheckedDaily &&
                                              isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: Checkbox(
                                            value: MisCheckedDias,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                MisCheckedDias = value ?? false;
                                                MisCheckedSemana = false;
                                              });
                                            },
                                          ),
                                        ),
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              !isCheckedDaily &&
                                              isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: const Text('Dia'),
                                        ),
//countbox
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              !isCheckedDaily &&
                                              isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: Container(
                                            width: 45.0,
                                            height: 30.0,
                                            foregroundDecoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              border: Border.all(
                                                color: Colors.blueGrey,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                Expanded(
                                                  flex: 1,
                                                  child: TextFormField(
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize:
                                                            14.0), // Ajuste o tamanho da fonte conforme necessário
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5.0),
                                                      ),
                                                    ),
                                                    controller: _controllerM,
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                      decimal: false,
                                                      signed: true,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 30.0,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      SizedBox(
                                                        height:
                                                            15.0, // Ajuste a altura conforme necessário
                                                        child: InkWell(
                                                          child: const Icon(
                                                            Icons.arrow_drop_up,
                                                            size: 14.0,
                                                          ),
                                                          onTap: () {
                                                            int currentValueM =
                                                                int.parse(
                                                                    _controllerM
                                                                        .text);
                                                            setState(() {
                                                              currentValueM++;
                                                              _controllerM
                                                                      .text =
                                                                  (currentValueM)
                                                                      .toString();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            15.0, // Ajuste a altura conforme necessário
                                                        child: InkWell(
                                                          child: const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            size: 14.0,
                                                          ),
                                                          onTap: () {
                                                            int currentValueM =
                                                                int.parse(
                                                                    _controllerM
                                                                        .text);
                                                            setState(() {
                                                              print(
                                                                  "Setting state");
                                                              currentValueM--;
                                                              _controllerM
                                                                      .text =
                                                                  (currentValueM >
                                                                              0
                                                                          ? currentValueM
                                                                          : 0)
                                                                      .toString();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        Visibility(
                                            visible: !isCheckedWeekly &&
                                                !isCheckedDaily &&
                                                isCheckedMonthly &&
                                                !isCheckedAnualy,
                                            child: const Text('of every')),
//countbox2
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              !isCheckedDaily &&
                                              isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: Container(
                                            width: 45.0,
                                            height: 30.0,
                                            foregroundDecoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              border: Border.all(
                                                color: Colors.blueGrey,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                Expanded(
                                                  flex: 1,
                                                  child: TextFormField(
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize:
                                                            14.0), // Ajuste o tamanho da fonte conforme necessário
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5.0),
                                                      ),
                                                    ),
                                                    controller: _controllerM2,
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                      decimal: false,
                                                      signed: true,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 30.0,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      SizedBox(
                                                        height:
                                                            15.0, // Ajuste a altura conforme necessário
                                                        child: InkWell(
                                                          child: const Icon(
                                                            Icons.arrow_drop_up,
                                                            size: 14.0,
                                                          ),
                                                          onTap: () {
                                                            int currentValueM2 =
                                                                int.parse(
                                                                    _controllerM2
                                                                        .text);
                                                            setState(() {
                                                              currentValueM2++;
                                                              _controllerM2
                                                                      .text =
                                                                  (currentValueM2)
                                                                      .toString();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            15.0, // Ajuste a altura conforme necessário
                                                        child: InkWell(
                                                          child: const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            size: 14.0,
                                                          ),
                                                          onTap: () {
                                                            int currentValueM2 =
                                                                int.parse(
                                                                    _controllerM2
                                                                        .text);
                                                            setState(() {
                                                              print(
                                                                  "Setting state");
                                                              currentValueM2--;
                                                              _controllerM2
                                                                      .text =
                                                                  (currentValueM2 >
                                                                              0
                                                                          ? currentValueM2
                                                                          : 0)
                                                                      .toString();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),

                                        Visibility(
                                            visible: !isCheckedWeekly &&
                                                !isCheckedDaily &&
                                                isCheckedMonthly &&
                                                !isCheckedAnualy,
                                            child: const Text('mes(es)')),
                                      ],
                                    ),

                                    const Divider(),
                                    Row(
                                      children: [
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              !isCheckedDaily &&
                                              isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: Checkbox(
                                            value: MisCheckedSemana,
                                            onChanged: (bool? value) {
                                              setState(() {
                                                MisCheckedSemana =
                                                    value ?? false;
                                                MisCheckedDias = false;
                                              });
                                            },
                                          ),
                                        ),
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              !isCheckedDaily &&
                                              isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: const Text('A'),
                                        ),
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              !isCheckedDaily &&
                                              isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: DropdownButton<String>(
                                            value: orderm,
                                            hint: Text('Select an Option'),
                                            elevation: 50,
                                            style: const TextStyle(
                                                color: Colors.black),
                                            underline: Container(
                                              height: 2,
                                              color: Colors.blue,
                                            ),
                                            items: orderM
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                orderm = value.toString();
                                              });
                                            },
                                            icon: const Icon(Icons.expand_more),
                                          ),
                                        ),
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              !isCheckedDaily &&
                                              isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: DropdownButton<String>(
                                            value: orderm2,
                                            hint:
                                                const Text('Select an Option'),
                                            elevation: 14,
                                            style: const TextStyle(
                                                color: Colors.black),
                                            underline: Container(
                                              height: 2,
                                              color: Colors.blue,
                                            ),
                                            items: orderM2
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                orderm2 = value.toString();
                                              });
                                            },
                                            icon: const Icon(Icons.expand_more),
                                          ),
                                        ),
                                        Visibility(
                                            visible: !isCheckedWeekly &&
                                                !isCheckedDaily &&
                                                isCheckedMonthly &&
                                                !isCheckedAnualy,
                                            child: const Text('of every')),
                                        Visibility(
                                          visible: !isCheckedWeekly &&
                                              !isCheckedDaily &&
                                              isCheckedMonthly &&
                                              !isCheckedAnualy,
                                          child: Container(
                                            width: 45.0,
                                            height: 30.0,
                                            foregroundDecoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                              border: Border.all(
                                                color: Colors.blueGrey,
                                                width: 2.0,
                                              ),
                                            ),
                                            child: Row(
                                              children: <Widget>[
                                                Expanded(
                                                  flex: 1,
                                                  child: TextFormField(
                                                    textAlign: TextAlign.center,
                                                    style: const TextStyle(
                                                        fontSize:
                                                            14.0), // Ajuste o tamanho da fonte conforme necessário
                                                    decoration: InputDecoration(
                                                      contentPadding:
                                                          const EdgeInsets.all(
                                                              8.0),
                                                      border:
                                                          OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5.0),
                                                      ),
                                                    ),
                                                    controller: _controllerM3,
                                                    keyboardType:
                                                        const TextInputType
                                                            .numberWithOptions(
                                                      decimal: false,
                                                      signed: true,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(
                                                  height: 30.0,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .center,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: <Widget>[
                                                      SizedBox(
                                                        height:
                                                            15.0, // Ajuste a altura conforme necessário
                                                        child: InkWell(
                                                          child: const Icon(
                                                            Icons.arrow_drop_up,
                                                            size: 14.0,
                                                          ),
                                                          onTap: () {
                                                            int currentValueM3 =
                                                                int.parse(
                                                                    _controllerM3
                                                                        .text);
                                                            setState(() {
                                                              currentValueM3++;
                                                              _controllerM3
                                                                      .text =
                                                                  (currentValueM3)
                                                                      .toString();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            15.0, // Ajuste a altura conforme necessário
                                                        child: InkWell(
                                                          child: const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            size: 14.0,
                                                          ),
                                                          onTap: () {
                                                            int currentValueM3 =
                                                                int.parse(
                                                                    _controllerM3
                                                                        .text);
                                                            setState(() {
                                                              print(
                                                                  "Setting state");
                                                              currentValueM3--;
                                                              _controllerM3
                                                                      .text =
                                                                  (currentValueM3 >
                                                                              0
                                                                          ? currentValueM3
                                                                          : 0)
                                                                      .toString();
                                                            });
                                                          },
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Visibility(
                                            visible: !isCheckedWeekly &&
                                                !isCheckedDaily &&
                                                isCheckedMonthly &&
                                                !isCheckedAnualy,
                                            child: const Text('mes(es)')),
                                      ],
                                    ),

//Anualmente

                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Visibility(
                                                visible: !isCheckedWeekly &&
                                                    !isCheckedDaily &&
                                                    !isCheckedMonthly &&
                                                    isCheckedAnualy,
                                                child: const Text(
                                                    'Recorre a cada')),
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: Container(
                                                width: 45.0,
                                                height: 30.0,
                                                foregroundDecoration:
                                                    BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                  border: Border.all(
                                                    color: Colors.blueGrey,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: <Widget>[
                                                    Expanded(
                                                      flex: 1,
                                                      child: TextFormField(
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize:
                                                                14.0), // Ajuste o tamanho da fonte conforme necessário
                                                        decoration:
                                                            InputDecoration(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5.0),
                                                          ),
                                                        ),
                                                        controller:
                                                            _controllerA,
                                                        keyboardType:
                                                            const TextInputType
                                                                .numberWithOptions(
                                                          decimal: false,
                                                          signed: true,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 30.0,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          SizedBox(
                                                            height:
                                                                15.0, // Ajuste a altura conforme necessário
                                                            child: InkWell(
                                                              child: const Icon(
                                                                Icons
                                                                    .arrow_drop_up,
                                                                size: 14.0,
                                                              ),
                                                              onTap: () {
                                                                int currentValueA =
                                                                    int.parse(
                                                                        _controllerA
                                                                            .text);
                                                                setState(() {
                                                                  currentValueA++;
                                                                  _controllerA
                                                                          .text =
                                                                      (currentValueA)
                                                                          .toString();
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                15.0, // Ajuste a altura conforme necessário
                                                            child: InkWell(
                                                              child: const Icon(
                                                                Icons
                                                                    .arrow_drop_down,
                                                                size: 14.0,
                                                              ),
                                                              onTap: () {
                                                                int currentValueA =
                                                                    int.parse(
                                                                        _controllerA
                                                                            .text);
                                                                setState(() {
                                                                  print(
                                                                      "Setting state");
                                                                  currentValueA--;
                                                                  _controllerA
                                                                      .text = (currentValueA >
                                                                              0
                                                                          ? currentValueA
                                                                          : 0)
                                                                      .toString();
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            Visibility(
                                                visible: !isCheckedWeekly &&
                                                    !isCheckedDaily &&
                                                    !isCheckedMonthly &&
                                                    isCheckedAnualy,
                                                child: const Text('Ano(s)')),
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: Checkbox(
                                                value: AisChecked1,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    AisChecked1 =
                                                        value ?? false;
                                                    AisChecked2 = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: const Text('Em'),
                                            ),
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: Container(
                                                child: DropdownButton<String>(
                                                  value: orderanualM1,
                                                  hint: const Text(
                                                      'Select an Option'),
                                                  elevation: 14,
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                  underline: Container(
                                                    height: 2,
                                                    color: Colors.blue,
                                                  ),
                                                  items: orderAnualM1.map<
                                                          DropdownMenuItem<
                                                              String>>(
                                                      (String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      orderanualM1 =
                                                          value.toString();
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      Icons.expand_more),
                                                ),
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: Container(
                                                width: 45.0,
                                                height: 30.0,
                                                foregroundDecoration:
                                                    BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          5.0),
                                                  border: Border.all(
                                                    color: Colors.blueGrey,
                                                    width: 2.0,
                                                  ),
                                                ),
                                                child: Row(
                                                  children: <Widget>[
                                                    Expanded(
                                                      flex: 1,
                                                      child: TextFormField(
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: const TextStyle(
                                                            fontSize:
                                                                14.0), // Ajuste o tamanho da fonte conforme necessário
                                                        decoration:
                                                            InputDecoration(
                                                          contentPadding:
                                                              const EdgeInsets
                                                                  .all(8.0),
                                                          border:
                                                              OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5.0),
                                                          ),
                                                        ),
                                                        controller:
                                                            _controllerA1,
                                                        keyboardType:
                                                            const TextInputType
                                                                .numberWithOptions(
                                                          decimal: false,
                                                          signed: true,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(
                                                      height: 30.0,
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: <Widget>[
                                                          SizedBox(
                                                            height:
                                                                15.0, // Ajuste a altura conforme necessário
                                                            child: InkWell(
                                                              child: const Icon(
                                                                Icons
                                                                    .arrow_drop_up,
                                                                size: 14.0,
                                                              ),
                                                              onTap: () {
                                                                int currentValueA1 =
                                                                    int.parse(
                                                                        _controllerA1
                                                                            .text);
                                                                setState(() {
                                                                  currentValueA1++;
                                                                  _controllerA1
                                                                          .text =
                                                                      (currentValueA1)
                                                                          .toString();
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                          SizedBox(
                                                            height:
                                                                15.0, // Ajuste a altura conforme necessário
                                                            child: InkWell(
                                                              child: const Icon(
                                                                Icons
                                                                    .arrow_drop_down,
                                                                size: 14.0,
                                                              ),
                                                              onTap: () {
                                                                int currentValueA1 =
                                                                    int.parse(
                                                                        _controllerA1
                                                                            .text);
                                                                setState(() {
                                                                  print(
                                                                      "Setting state");
                                                                  currentValueA1--;
                                                                  _controllerA1
                                                                      .text = (currentValueA1 >
                                                                              0
                                                                          ? currentValueA1
                                                                          : 0)
                                                                      .toString();
                                                                });
                                                              },
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const Divider(),
                                        Row(
                                          children: [
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: Checkbox(
                                                value: AisChecked2,
                                                onChanged: (bool? value) {
                                                  setState(() {
                                                    AisChecked2 =
                                                        value ?? false;
                                                    AisChecked1 = false;
                                                  });
                                                },
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: const Text('A'),
                                            ),
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: Container(
                                                child: DropdownButton<String>(
                                                  value: orderanualM2,
                                                  hint: const Text(
                                                      'Select an Option'),
                                                  elevation: 14,
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                  underline: Container(
                                                    height: 2,
                                                    color: Colors.blue,
                                                  ),
                                                  items: orderAnualM2.map<
                                                          DropdownMenuItem<
                                                              String>>(
                                                      (String value) {
                                                    return DropdownMenuItem<
                                                        String>(
                                                      value: value,
                                                      child: Text(value),
                                                    );
                                                  }).toList(),
                                                  onChanged: (value) {
                                                    setState(() {
                                                      orderanualM2 =
                                                          value.toString();
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      Icons.expand_more),
                                                ),
                                              ),
                                            ),
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: DropdownButton<String>(
                                                value: orderanualsM3,
                                                hint: const Text(
                                                    'Select an Option'),
                                                elevation: 14,
                                                style: const TextStyle(
                                                    color: Colors.black),
                                                underline: Container(
                                                  height: 2,
                                                  color: Colors.blue,
                                                ),
                                                items: orderAnualsM3.map<
                                                        DropdownMenuItem<
                                                            String>>(
                                                    (String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    orderanualsM3 =
                                                        value.toString();
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.expand_more),
                                              ),
                                            ),
                                            Visibility(
                                                visible: !isCheckedWeekly &&
                                                    !isCheckedDaily &&
                                                    !isCheckedMonthly &&
                                                    isCheckedAnualy,
                                                child: const Text('of every')),
                                            Visibility(
                                              visible: !isCheckedWeekly &&
                                                  !isCheckedDaily &&
                                                  !isCheckedMonthly &&
                                                  isCheckedAnualy,
                                              child: DropdownButton<String>(
                                                value: orderanualM4,
                                                hint: const Text(
                                                    'Select an Option'),
                                                elevation: 14,
                                                style: const TextStyle(
                                                    color: Colors.black),
                                                underline: Container(
                                                  height: 2,
                                                  color: Colors.blue,
                                                ),
                                                items: orderAnualM4.map<
                                                        DropdownMenuItem<
                                                            String>>(
                                                    (String value) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: value,
                                                    child: Text(value),
                                                  );
                                                }).toList(),
                                                onChanged: (value) {
                                                  setState(() {
                                                    orderanualM4 =
                                                        value.toString();
                                                  });
                                                },
                                                icon: const Icon(
                                                    Icons.expand_more),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(
                          height: 5,
                        ),
                        Container(
                          width: 600,
                          height: 1,
                          color: Colors.black,
                        ),
                        Column(
                          children: [
                            Row(
                              children: [
                                Text('Começa:'),
                                SizedBox(
                                  width: 235,
                                  height: 50,
                                  child: GestureDetector(
                                    onTap: () {
                                      _selectDate(context);
                                    },
                                    child: AbsorbPointer(
                                      child: TextField(
                                        controller: _dateController,
                                        style: TextStyle(
                                            fontSize:
                                                14), // Define o tamanho da fonte
                                        decoration: InputDecoration(
                                          suffixIcon:
                                              Icon(Icons.calendar_today),
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical:
                                                  15), // Ajusta o preenchimento vertical
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Checkbox(
                                  value: RRisCheckedAcabaEm,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      RRisCheckedAcabaEm = value ?? false;
                                      RRisCheckedAcabaDepois = false;
                                      RRisCheckedSemFim = false;
                                    });
                                  },
                                ),
                                Text('Acaba em:'),
                                SizedBox(
                                  width: 235,
                                  height: 50,
                                  child: GestureDetector(
                                    onTap: () {
                                      selectDate(context);
                                    },
                                    child: AbsorbPointer(
                                      child: TextField(
                                        controller: dateController,
                                        style: TextStyle(
                                            fontSize:
                                                14), // Define o tamanho da fonte
                                        decoration: InputDecoration(
                                          suffixIcon:
                                              Icon(Icons.calendar_today),
                                          contentPadding: EdgeInsets.symmetric(
                                              vertical:
                                                  15), // Ajusta o preenchimento vertical
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: RRisCheckedAcabaDepois,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      RRisCheckedAcabaDepois = value ?? false;
                                      RRisCheckedAcabaEm = false;
                                      RRisCheckedSemFim = false;
                                    });
                                  },
                                ),
                                Text('Acaba depois:'),
                                SizedBox(
                                  width: 15,
                                ),
                                Container(
                                  width: 45.0,
                                  height: 30.0,
                                  foregroundDecoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(5.0),
                                    border: Border.all(
                                      color: Colors.blueGrey,
                                      width: 2.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        flex: 1,
                                        child: TextFormField(
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                              fontSize:
                                                  14.0), // Ajuste o tamanho da fonte conforme necessário
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.all(8.0),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5.0),
                                            ),
                                          ),
                                          controller: _controllerRR,
                                          keyboardType: const TextInputType
                                              .numberWithOptions(
                                            decimal: false,
                                            signed: true,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        height: 30.0,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: <Widget>[
                                            SizedBox(
                                              height:
                                                  15.0, // Ajuste a altura conforme necessário
                                              child: InkWell(
                                                child: const Icon(
                                                  Icons.arrow_drop_up,
                                                  size: 14.0,
                                                ),
                                                onTap: () {
                                                  int currentValueRR =
                                                      int.parse(
                                                          _controllerRR.text);
                                                  setState(() {
                                                    currentValueRR++;
                                                    _controllerRR.text =
                                                        (currentValueRR)
                                                            .toString();
                                                  });
                                                },
                                              ),
                                            ),
                                            SizedBox(
                                              height:
                                                  15.0, // Ajuste a altura conforme necessário
                                              child: InkWell(
                                                child: const Icon(
                                                  Icons.arrow_drop_down,
                                                  size: 14.0,
                                                ),
                                                onTap: () {
                                                  int currentValueRR =
                                                      int.parse(
                                                          _controllerRR.text);
                                                  setState(() {
                                                    print("Setting state");
                                                    currentValueRR--;
                                                    _controllerRR.text =
                                                        (currentValueRR > 0
                                                                ? currentValueRR
                                                                : 0)
                                                            .toString();
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Checkbox(
                                  value: RRisCheckedSemFim,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      RRisCheckedSemFim = value ?? false;
                                      RRisCheckedAcabaDepois = false;
                                      RRisCheckedAcabaEm = false;
                                    });
                                  },
                                ),
                                Text('sem fim'),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          child: const Text('Cancelar'),
                          onPressed: () {
                            Navigator.of(context)
                                .pop(); // Close the AlertDialog
                          },
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            emptyFields();
                          },
                          child: const Text('Confirmar'),
                        ),
                      ],
                    ),
                  ],
                )),
              ),
            ),*/
          ],
        ),
      ),
    );
  }


  Future<void> selectDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (picked != null && picked != selectedDate) {
      setState(() {
        updateDateText(picked);
      });
    }
  }

  void emptyFields() async {
    final title = _titleController.text;
    final descri = _descriptionController.text;
    final nomeC = NameClientController.text;
    final LocR = LocRController.text;
    final LocE = LocEController.text;

    final color = selectedColor.toString().substring(10, 16);

    //print(color);

    if (title.isEmpty ||
        descri.isEmpty ||
        nomeC.isEmpty ||
        LocE.isEmpty ||
        LocR.isEmpty ||
        color.isEmpty) {
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text(
          'Preencha todos os campos',
          style: TextStyle(
            fontSize: 16, // Customize font size
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
        backgroundColor: Colors.red, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    } else {
      //print(title);
      //print(color);

      createTar(
        _titleController.text,
        _descriptionController.text,
   
        '${selectedStartDate.year}-${selectedStartDate.month}-${selectedStartDate.day}',
        '${selectedStartTime.hour}:${selectedStartTime.minute}:00',
        '${selectedEndDate.year}-${selectedEndDate.month}-${selectedEndDate.day}',
        '${selectedEndTime.hour}:${selectedEndTime.minute}:00',
        '$selectedColor',
        int.parse(selectedOption),
             NameClientController.text,
        LocEController.text,
        LocRController.text,
      );
      Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => defaultTar(),
          ));
      final snackBar = SnackBar(
        behavior: SnackBarBehavior.floating,
        content: const Text(
          'Tarefa criada',
          style: TextStyle(
            fontSize: 16, // Customize font size
          ),
        ),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // Some code to undo the change.
          },
        ),
        backgroundColor: Colors.green, // Customize background color
        elevation: 6.0, // Add elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.0), // Customize border radius
        ),
      );

      // Find the ScaffoldMessenger in the widget tree
      // and use it to show a SnackBar.
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(snackBar);
      });
    }
  }
}
