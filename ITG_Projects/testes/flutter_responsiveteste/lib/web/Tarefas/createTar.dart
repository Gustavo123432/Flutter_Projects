import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:syncfusion_localizations/syncfusion_localizations.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'dart:convert';

class CreateTar extends StatefulWidget {


  @override
  _CreateTarState createState() => _CreateTarState();
}

class _CreateTarState extends State<CreateTar> {

final TextEditingController _nomeController = TextEditingController();
 final TextEditingController _controller = TextEditingController();

  List Users = [];
  String selectedOption = '1';
  bool isRecurrentChecked = false;
  OverlayEntry? overlayEntry;
  dynamic tar;
  dynamic length;
  bool isChecked1 = false;
  bool isChecked2 = false;
  bool isChecked3 = false;
  bool isChecked4 = false;
  bool isChecked5 = false;
  bool isChecked6 = false;
  bool isChecked7 = false;
  bool isChecked8 = false;
  bool isChecked10 = false;
  bool isChecked11 = true;
  bool isChecked12 = false;
  bool isChecked13 = false;
  List<String> order = <String>[
    'Segunda',
    'Terça',
    'Quarta',
    'Quinta',
    'Sexta',
    'Sabado',
    'Domingo'
  ];
  dynamic orderv = 'Segunda';
  bool isCheckedAdditional = false; // Nova variável para a nova checkbox
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

  createTar(String title, String descrip, String dataini, String tempini,
      String dateend, String tempend, String selectedColor, int id) async {
    dynamic response = await http.get(Uri.parse(
        "https://services.interagit.com/API/api_Calendar.php?query_param=15&Titulo=$title&Descrip=$descrip&DataIni=$dataini&TempIni=$tempini&TempEnd=$tempend&DateEnd=$dateend&Color=$selectedColor&id=$id"));
    if (response.statusCode == 200) {
      setState(() {
        //print('Feito?');
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
  void initState() {
    super.initState();
    _controller.text = "0";
    getUserList();
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
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
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
                                onPressed: () {
                                  showDatePicker(
                                    context: context,
                                    initialDate: selectedStartDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  ).then((pickedDate) {
                                    if (pickedDate != null) {
                                      selectedStartDate = pickedDate;
                                      formattedStartDate =
                                          '${pickedDate.year}-${pickedDate.month}-${pickedDate.day}';
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  minimumSize: const Size(275, 50),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      'Data Início: ',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                      ),
                                    ),
                                    Text(
                                      formattedStartDate,
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
                                onPressed: () {
                                  showDatePicker(
                                    context: context,
                                    initialDate: selectedEndDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2101),
                                  ).then((pickedDate) {
                                    if (pickedDate != null) {
                                      selectedEndDate = pickedDate;
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  minimumSize: const Size(275, 50),
                                ),
                                child: const Text(
                                  'Data Fim',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            )
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
                                onPressed: () {
                                  showTimePicker(
                                    context: context,
                                    initialTime: selectedStartTime,
                                    builder:
                                        (BuildContext context, Widget? child) {
                                      return MediaQuery(
                                        data: MediaQuery.of(context).copyWith(
                                            alwaysUse24HourFormat: true),
                                        child: child!,
                                      );
                                    },
                                  ).then((pickedTime) {
                                    if (pickedTime != null) {
                                      selectedStartTime = pickedTime;
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  minimumSize: const Size(275, 50),
                                ),
                                child: const Text(
                                  'Hora Início',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  showTimePicker(
                                    context: context,
                                    initialTime: selectedEndTime,
                                    builder:
                                        (BuildContext context, Widget? child) {
                                      return MediaQuery(
                                        data: MediaQuery.of(context).copyWith(
                                            alwaysUse24HourFormat: true),
                                        child: child!,
                                      );
                                    },
                                  ).then((pickedTime) {
                                    if (pickedTime != null) {
                                      selectedEndTime = pickedTime;
                                    }
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  minimumSize: const Size(275, 50),
                                ),
                                child: const Text(
                                  'Hora Fim',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [

                      Text('Recorrente'),
                          ],
                        ),
                      ],
					                      
                    ),
					
                    Column(
                      children: [
                        Row(
                          children: [
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
                                //print(selectedOption);
                              });
                            },
                          ),

                          Column(
                            children: [
const Text(
                          'Selected Color:',
                          style: TextStyle(fontSize: 18),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: selectedColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                              _showColorPickerDialog();
                          },
                          child: const Text('Select a Color'),
                        ),
                            ] 
                          )


                      ],
                    )
                      ]),
            ]),
              ),
          )
          ),
          

              Card(
                elevation: 3,
                child: Container(
                    width: 600,
                  height: 575,
                  padding: EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      children: [
                         Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Recorrente"),
                          Container(
                            height: 1,
                            width: 270,
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
                                      Visibility(
                                        visible: !isChecked8,
                                        child: Checkbox(
                                          value: isChecked10,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isChecked10 = value ?? false;
                                              isChecked11 = !isChecked10;
                                              isChecked12 = false;
                                              isChecked13 = false;
                                            });
                                          },
                                        ),
                                      ),
                                      Visibility(
                                        visible: !isChecked8,
                                        child: const Text('Diariamente'),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Visibility(
                                        visible: !isChecked8,
                                        child: Checkbox(
                                          value: isChecked11,
                                          onChanged: (bool? value) {
                                            setState(() {
                                              isChecked11 = value ?? false;
                                              isChecked10 = false;
                                              isChecked12 = false;
                                              isChecked13 = false;
                                            });
                                          },
                                        ),
                                      ),
                                      Visibility(
                                        visible: !isChecked8,
                                        child: const Text('Semanalmente'),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isChecked12,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            isChecked12 = value ?? false;
                                            isChecked11 = !isChecked12;
                                            isChecked13 = false;
                                            isChecked10 = false;
                                          });
                                        },
                                      ),
                                      const Text('Mensalmente'),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: isChecked13,
                                        onChanged: (bool? value) {
                                          setState(() {
                                            isChecked13 = value ?? false;
                                            isChecked11 = !isChecked13;
                                            isChecked12 = false;
                                            isChecked10 = false;
                                          });
                                        },
                                      ),
                                      const Text('Anualmente'),
                                    ],
                                  )
                                ],
                              ),
                              Container(
                                width: 1,
                                height: 150,
                                color: Colors.red,
                              ),
                              Column(
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      //semanalmente
                                      Row(
                                        children: [
                                          Row(
                                            children: [
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: Checkbox(
                                                  value: isChecked1,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked1 =
                                                          value ?? false;
                                                      isChecked8 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: const Text('Segunda-Feira'),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: Checkbox(
                                                  value: isChecked5,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked5 =
                                                          value ?? false;
                                                      isChecked8 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
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
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: Checkbox(
                                                  value: isChecked2,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked2 =
                                                          value ?? false;
                                                      isChecked8 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: const Text('Terça-Feira'),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: Checkbox(
                                                  value: isChecked6,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked6 =
                                                          value ?? false;
                                                      isChecked8 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
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
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: Checkbox(
                                                  value: isChecked3,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked3 =
                                                          value ?? false;
                                                      isChecked8 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: const Text('Quarta-Feira'),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: Checkbox(
                                                  value: isChecked7,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked7 =
                                                          value ?? false;
                                                      isChecked8 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
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
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: Checkbox(
                                                  value: isChecked4,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked4 =
                                                          value ?? false;
                                                      isChecked8 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: const Text('Quinta-Feira'),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: Checkbox(
                                                  value: isChecked8,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked8 =
                                                          value ?? false;
                                                      isChecked1 = false;
                                                      isChecked2 = false;
                                                      isChecked3 = false;
                                                      isChecked4 = false;
                                                      isChecked5 = false;
                                                      isChecked6 = false;
                                                      isChecked7 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible:
                                                    !isChecked10 && isChecked11,
                                                child: const Text('Todos os dias'),
                                              ),
                                              Visibility(
                                                visible: isChecked2,
                                                child: const Text('Funfa?'),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
//diariamente
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Visibility(
                                            visible: isChecked10,
                                            child: Checkbox(
                                              value: isChecked11,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isChecked11 = value ?? false;
                                                  isChecked10 = false;
                                                  isChecked12 = false;
                                                  isChecked13 = false;
                                                });
                                              },
                                            ),
                                          ),
                                          Visibility(
                                            visible: isChecked10,
                                            child: const Text('Todos os dias'),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          Visibility(
                                            visible: !isChecked11 &&
                                                isChecked10 &&
                                                !isChecked12 &&
                                                !isChecked13,
                                            child: Checkbox(
                                              value: isChecked11,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isChecked11 = value ?? false;
                                                  isChecked10 = false;
                                                  isChecked12 = false;
                                                  isChecked13 = false;
                                                });
                                              },
                                            ),
                                          ),
                                          Visibility(
                                            visible: !isChecked11 &&
                                                isChecked10 &&
                                                !isChecked12 &&
                                                !isChecked13,
                                            child: const Text('A cada'),
                                          ),
                                          Visibility(
                                            visible: !isChecked11 &&
                                                isChecked10 &&
                                                !isChecked12 &&
                                                !isChecked13,
                                            child: Container(
                                              width: 60.0,
                                              height: 40,
                                              foregroundDecoration:
                                                  BoxDecoration(
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
                                                      textAlign:
                                                          TextAlign.center,
                                                      decoration:
                                                          InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets.all(8.0),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      5.0),
                                                        ),
                                                      ),
                                                      controller: _controller,
                                                      //  onChanged: _controller.text.toString() == "" ? _controller.text == "0" : _controller.text=="" ,
                                                      keyboardType: const TextInputType
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
                                                              bottom:
                                                                  BorderSide(
                                                                width: 0.5,
                                                              ),
                                                            ),
                                                          ),
                                                          child: InkWell(
                                                            child: const Icon(
                                                              Icons
                                                                  .arrow_drop_up,
                                                              size: 18.0,
                                                            ),
                                                            onTap: () {
                                                              int currentValue =
                                                                  int.parse(
                                                                      _controller
                                                                          .text);
                                                              setState(() {
                                                                currentValue++;
                                                                _controller
                                                                        .text =
                                                                    (currentValue)
                                                                        .toString(); // incrementing value
                                                              });
                                                            },
                                                          ),
                                                        ),
                                                        InkWell(
                                                          child: const Icon(
                                                            Icons
                                                                .arrow_drop_down,
                                                            size: 18.0,
                                                          ),
                                                          onTap: () {
                                                            int currentValue =
                                                                int.parse(
                                                                    _controller
                                                                        .text);
                                                            setState(() {
                                                              print(
                                                                  "Setting state");
                                                              currentValue--;
                                                              _controller.text =
                                                                  (currentValue >
                                                                              0
                                                                          ? currentValue
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
                                              visible: !isChecked11 &&
                                                  isChecked10 &&
                                                  !isChecked12 &&
                                                  !isChecked13,
                                              child: const Text("dias")),
                                        ],
                                      ),
                                    ],
                                  ),
                                  //Mensalmente
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Visibility(
                                            visible: !isChecked11 &&
                                                !isChecked10 &&
                                                isChecked12 &&
                                                !isChecked13,
                                            child: Checkbox(
                                              value: isChecked11,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isChecked11 = value ?? false;
                                                  isChecked10 = false;
                                                  isChecked12 = false;
                                                  isChecked13 = false;
                                                });
                                              },
                                            ),
                                          ),
                                          Visibility(
                                            visible: !isChecked11 &&
                                                !isChecked10 &&
                                                isChecked12 &&
                                                !isChecked13,
                                            child: const Text('Dia'),
                                          ),
//countbox
                                          Visibility(
                                            visible: !isChecked11 &&
                                                !isChecked10 &&
                                                isChecked12 &&
                                                !isChecked13,
                                            child: Container(
                                              width: 45.0,
                                              height: 30.0,
                                              foregroundDecoration:
                                                  BoxDecoration(
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
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                          fontSize:
                                                              14.0), // Ajuste o tamanho da fonte conforme necessário
                                                      decoration:
                                                          InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets.all(8.0),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      5.0),
                                                        ),
                                                      ),
                                                      controller: _controller,
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
                                                              int currentValue =
                                                                  int.parse(
                                                                      _controller
                                                                          .text);
                                                              setState(() {
                                                                currentValue++;
                                                                _controller
                                                                        .text =
                                                                    (currentValue)
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
                                                              int currentValue =
                                                                  int.parse(
                                                                      _controller
                                                                          .text);
                                                              setState(() {
                                                                print(
                                                                    "Setting state");
                                                                currentValue--;
                                                                _controller
                                                                    .text = (currentValue >
                                                                            0
                                                                        ? currentValue
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
                                              visible: !isChecked11 &&
                                                  !isChecked10 &&
                                                  isChecked12 &&
                                                  !isChecked13,
                                              child: const Text('of every')),
//countbox2
                                          Visibility(
                                            visible: !isChecked11 &&
                                                !isChecked10 &&
                                                isChecked12 &&
                                                !isChecked13,
                                            child: Container(
                                              width: 45.0,
                                              height: 30.0,
                                              foregroundDecoration:
                                                  BoxDecoration(
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
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                          fontSize:
                                                              14.0), // Ajuste o tamanho da fonte conforme necessário
                                                      decoration:
                                                          InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets.all(8.0),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      5.0),
                                                        ),
                                                      ),
                                                      controller: _controller,
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
                                                              int currentValue =
                                                                  int.parse(
                                                                      _controller
                                                                          .text);
                                                              setState(() {
                                                                currentValue++;
                                                                _controller
                                                                        .text =
                                                                    (currentValue)
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
                                                              int currentValue =
                                                                  int.parse(
                                                                      _controller
                                                                          .text);
                                                              setState(() {
                                                                print(
                                                                    "Setting state");
                                                                currentValue--;
                                                                _controller
                                                                    .text = (currentValue >
                                                                            0
                                                                        ? currentValue
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
                                              visible: !isChecked11 &&
                                                  !isChecked10 &&
                                                  isChecked12 &&
                                                  !isChecked13,
                                              child: const Text('mes(es)')),
                                        ],
                                      ),
                                   
                                      const Divider(),
                                      Row(
                                        children: [
                                          Visibility(
                                            visible: !isChecked11 &&
                                                !isChecked10 &&
                                                isChecked12 &&
                                                !isChecked13,
                                            child: Checkbox(
                                              value: isChecked11,
                                              onChanged: (bool? value) {
                                                setState(() {
                                                  isChecked11 = value ?? false;
                                                  isChecked10 = false;
                                                  isChecked12 = false;
                                                  isChecked13 = false;
                                                });
                                              },
                                            ),
                                          ),
                                          Visibility(
                                            visible: !isChecked11 &&
                                                !isChecked10 &&
                                                isChecked12 &&
                                                !isChecked13,
                                            child: const Text('A'),
                                          ),
                                          Visibility(
                                            visible: !isChecked11 &&
                                                !isChecked10 &&
                                                isChecked12 &&
                                                !isChecked13,
                                            child: DropdownButton<String>(
                                              value: orderv,
                                              hint: const Text(
                                                  'Select an Option'),
                                              elevation: 50,
                                              style: const TextStyle(
                                                  color: Colors.black),
                                              underline: Container(
                                                height: 2,
                                                color: Colors.blue,
                                              ),
                                              items: order.map<
                                                      DropdownMenuItem<String>>(
                                                  (String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  orderv = value.toString();
                                                });
                                              },
                                              icon:
                                                  const Icon(Icons.expand_more),
                                            ),
                                          ),
                                          Visibility(
                                            visible: !isChecked11 &&
                                                !isChecked10 &&
                                                isChecked12 &&
                                                !isChecked13,
                                            child: DropdownButton<String>(
                                              value: orderv,
                                              hint: const Text(
                                                  'Select an Option'),
                                              elevation: 14,
                                              style: const TextStyle(
                                                  color: Colors.black),
                                              underline: Container(
                                                height: 2,
                                                color: Colors.blue,
                                              ),
                                              items: order.map<
                                                      DropdownMenuItem<String>>(
                                                  (String value) {
                                                return DropdownMenuItem<String>(
                                                  value: value,
                                                  child: Text(value),
                                                );
                                              }).toList(),
                                              onChanged: (value) {
                                                setState(() {
                                                  orderv = value.toString();
                                                });
                                              },
                                              icon:
                                                  const Icon(Icons.expand_more),
                                            ),
                                          ),
                                          Visibility(
                                              visible: !isChecked11 &&
                                                  !isChecked10 &&
                                                  isChecked12 &&
                                                  !isChecked13,
                                              child: const Text('of every')),
                                          Visibility(
                                            visible: !isChecked11 &&
                                                !isChecked10 &&
                                                isChecked12 &&
                                                !isChecked13,
                                            child: Container(
                                              width: 45.0,
                                              height: 30.0,
                                              foregroundDecoration:
                                                  BoxDecoration(
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
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: const TextStyle(
                                                          fontSize:
                                                              14.0), // Ajuste o tamanho da fonte conforme necessário
                                                      decoration:
                                                          InputDecoration(
                                                        contentPadding:
                                                            const EdgeInsets.all(8.0),
                                                        border:
                                                            OutlineInputBorder(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                                      5.0),
                                                        ),
                                                      ),
                                                      controller: _controller,
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
                                                              int currentValue =
                                                                  int.parse(
                                                                      _controller
                                                                          .text);
                                                              setState(() {
                                                                currentValue++;
                                                                _controller
                                                                        .text =
                                                                    (currentValue)
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
                                                              int currentValue =
                                                                  int.parse(
                                                                      _controller
                                                                          .text);
                                                              setState(() {
                                                                print(
                                                                    "Setting state");
                                                                currentValue--;
                                                                _controller
                                                                    .text = (currentValue >
                                                                            0
                                                                        ? currentValue
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
                                              visible: !isChecked11 &&
                                                  !isChecked10 &&
                                                  isChecked12 &&
                                                  !isChecked13,
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
                                                  visible: !isChecked11 &&
                                                      !isChecked10 &&
                                                      !isChecked12 &&
                                                      isChecked13,
                                                  child:
                                                      const Text('Recorre a cada')),
                                              Visibility(
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
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
                                                                const EdgeInsets.all(
                                                                    8.0),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                          ),
                                                          controller:
                                                              _controller,
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
                                                                  int currentValue =
                                                                      int.parse(
                                                                          _controller
                                                                              .text);
                                                                  setState(() {
                                                                    currentValue++;
                                                                    _controller
                                                                            .text =
                                                                        (currentValue)
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
                                                                  int currentValue =
                                                                      int.parse(
                                                                          _controller
                                                                              .text);
                                                                  setState(() {
                                                                    print(
                                                                        "Setting state");
                                                                    currentValue--;
                                                                    _controller
                                                                        .text = (currentValue >
                                                                                0
                                                                            ? currentValue
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
                                                  visible: !isChecked11 &&
                                                      !isChecked10 &&
                                                      !isChecked12 &&
                                                      isChecked13,
                                                  child: const Text('Ano(s)')),
                                            ],
                                          ),
                                          const Divider(),
                                          Row(
                                            children: [
                                              Visibility(
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
                                                child: Checkbox(
                                                  value: isChecked11,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked11 =
                                                          value ?? false;
                                                      isChecked10 = false;
                                                      isChecked12 = false;
                                                      isChecked13 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
                                                child: const Text('Em'),
                                              ),
                                              Visibility(
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
                                                child: Container(
                                                  child: DropdownButton<String>(
                                                    value: orderv,
                                                    hint: const Text(
                                                        'Select an Option'),
                                                    elevation: 14,
                                                    style: const TextStyle(
                                                        color: Colors.black),
                                                    underline: Container(
                                                      height: 2,
                                                      color: Colors.blue,
                                                    ),
                                                    items: order.map<
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
                                                        orderv =
                                                            value.toString();
                                                      });
                                                    },
                                                    icon: const Icon(
                                                        Icons.expand_more),
                                                  ),
                                                ),
                                              ),
                                              Visibility(
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
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
                                                                const EdgeInsets.all(
                                                                    8.0),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                          ),
                                                          controller:
                                                              _controller,
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
                                                                  int currentValue =
                                                                      int.parse(
                                                                          _controller
                                                                              .text);
                                                                  setState(() {
                                                                    currentValue++;
                                                                    _controller
                                                                            .text =
                                                                        (currentValue)
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
                                                                  int currentValue =
                                                                      int.parse(
                                                                          _controller
                                                                              .text);
                                                                  setState(() {
                                                                    print(
                                                                        "Setting state");
                                                                    currentValue--;
                                                                    _controller
                                                                        .text = (currentValue >
                                                                                0
                                                                            ? currentValue
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
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
                                                child: Checkbox(
                                                  value: isChecked11,
                                                  onChanged: (bool? value) {
                                                    setState(() {
                                                      isChecked11 =
                                                          value ?? false;
                                                      isChecked10 = false;
                                                      isChecked12 = false;
                                                      isChecked13 = false;
                                                    });
                                                  },
                                                ),
                                              ),
                                              Visibility(
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
                                                child: const Text('A'),
                                              ),
                                              Visibility(
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
                                                child: Container(
                                                  child: DropdownButton<String>(
                                                    value: orderv,
                                                    hint: const Text(
                                                        'Select an Option'),
                                                    elevation: 14,
                                                    style: const TextStyle(
                                                        color: Colors.black),
                                                    underline: Container(
                                                      height: 2,
                                                      color: Colors.blue,
                                                    ),
                                                    items: order.map<
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
                                                        orderv =
                                                            value.toString();
                                                      });
                                                    },
                                                    icon: const Icon(
                                                        Icons.expand_more),
                                                  ),
                                                ),
                                              ),
                                              Visibility(
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
                                                child: DropdownButton<String>(
                                                  value: orderv,
                                                  hint: const Text(
                                                      'Select an Option'),
                                                  elevation: 14,
                                                  style: const TextStyle(
                                                      color: Colors.black),
                                                  underline: Container(
                                                    height: 2,
                                                    color: Colors.blue,
                                                  ),
                                                  items: order.map<
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
                                                      orderv = value.toString();
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      Icons.expand_more),
                                                ),
                                              ),
                                              Visibility(
                                                  visible: !isChecked11 &&
                                                      !isChecked10 &&
                                                      !isChecked12 &&
                                                      isChecked13,
                                                  child: const Text('of every')),
                                              Visibility(
                                                visible: !isChecked11 &&
                                                    !isChecked10 &&
                                                    !isChecked12 &&
                                                    isChecked13,
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
                                                                const EdgeInsets.all(
                                                                    8.0),
                                                            border:
                                                                OutlineInputBorder(
                                                              borderRadius:
                                                                  BorderRadius
                                                                      .circular(
                                                                          5.0),
                                                            ),
                                                          ),
                                                          controller:
                                                              _controller,
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
                                                                  int currentValue =
                                                                      int.parse(
                                                                          _controller
                                                                              .text);
                                                                  setState(() {
                                                                    currentValue++;
                                                                    _controller
                                                                            .text =
                                                                        (currentValue)
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
                                                                  int currentValue =
                                                                      int.parse(
                                                                          _controller
                                                                              .text);
                                                                  setState(() {
                                                                    print(
                                                                        "Setting state");
                                                                    currentValue--;
                                                                    _controller
                                                                        .text = (currentValue >
                                                                                0
                                                                            ? currentValue
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
                                                  visible: !isChecked11 &&
                                                      !isChecked10 &&
                                                      !isChecked12 &&
                                                      isChecked13,
                                                  child: const Text('mes(es)'))
                                            ],
                                          )
                                        ],
                                      )
                                    ],
                                  ),

          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            
            children: [
             TextButton(
                      child: const Text('Cancelar'),
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the AlertDialog
                      },
                    ),
                    ElevatedButton(
                      onPressed: () async {
                      // emptyFields();
                      },
                      child: const Text('Confirmar'),
                    ),
            ],
          ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                      ],
                    )
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    
  }
  
    void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color pickedColor =
            selectedColor; // Initialize pickedColor with selectedColor

        return AlertDialog(
          title: const Text('Selecione uma Cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  pickedColor = color; // Update pickedColor when color changes
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the AlertDialog
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  selectedColor =
                      pickedColor; // Update selectedColor with pickedColor
                });
                Navigator.of(context).pop(); // Close the AlertDialog
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }
}



