import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

class MyFormDialogPage extends StatefulWidget {
  @override
  dynamic id, name, log, mail, num, type, color, image;

  MyFormDialogPage({super.key, 
  
    required this.id,
    this.name,
    this.log,
    this.mail,
    this.num,
    this.type,
    this.color,
    this.image,
  });

  @override
  _MyFormDialogPageState createState() => _MyFormDialogPageState();
}

class _MyFormDialogPageState extends State<MyFormDialogPage> {
  final TextEditingController _nomeController = TextEditingController();
  final TextEditingController _logController = TextEditingController();
  final TextEditingController _mailController = TextEditingController();
  final TextEditingController _contController = TextEditingController();
  final TextEditingController _sobNController = TextEditingController();

  bool isHovered = false;
  dynamic selectedColor = Colors.blue;
  List<String> order = <String>['User', 'Admin'];
  dynamic orderv = 'User';
  dynamic numberint;
  String initialCountry = 'PT';
  PhoneNumber number = PhoneNumber(isoCode: 'PT');
  dynamic _selectedImage;

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    dynamic imagefile = await pickedFile!.readAsBytes();

    setState(() {
      _selectedImage = imagefile;
    });
  }

  Future<void> _uploadImage(int id) async {
    //print(base64Encode(_selectedImage));
    if (_selectedImage != null) {
      try {
        final response = await http.post(
          Uri.parse('https://services.interagit.com/API/api_Calendar_Post.php'),
          body: {
            'query_param': '1',
            'image': base64.encode(_selectedImage),
            'id': id.toString(),
          },
        );

        if (response.statusCode == 200) {
          // Imagem enviada com sucesso
          //print('Imagem enviada com sucesso');
        } else {
          // Lidar com o erro
          //print('Erro ao enviar a imagem: ${response.statusCode}');
        }
      } catch (e) {
        // Lidar com o erro
        //print('Erro ao enviar a imagem: $e');
      }
    }
  }

  void changeColor(Color color) {
    setState(() {
      selectedColor = color;
    });
  }

  void prehencher_controlers() {
    int n = 0;
    for (int i = 0; i < widget.name.toString().length; i++) {
      if (widget.name[i] == " ") {
        n = i;
      }
    }
    _nomeController.text = widget.name.toString().substring(0, n);
    _sobNController.text = widget.name.toString().substring(n + 1);

    orderv = order[int.parse(widget.type)];

    _logController.text = widget.log;
    _mailController.text = widget.mail;
    selectedColor = Color(int.parse(widget.color, radix: 16) + 0xFF000000);
    for (int i = widget.num.toString().length - 1; i > 0; i--) {
      if (widget.num[i] == " ") n = i;
    }
    _contController.text = widget.num;
    _selectedImage = base64.decode(widget.image.toString());
  }

  @override
  void initState() {
    prehencher_controlers();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text("Alterar Informações"),
        Container(
          color: Colors.black,
          width: 550,
          height: 1,
        ),
      ]),
      content: SizedBox(
        width: 550,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                  onTap: _getImage,
                  child: CircleAvatar(
                      radius: 50.0,
                      child: ClipOval(
                        child: (_selectedImage != null)
                            ? Image.memory(
                                _selectedImage,
                                fit: BoxFit.cover,
                                height: 100,
                                width: 100,
                              )
                            : Icon(
                                Icons.person,
                                size: 47,
                                color: selectedColor != Colors.blue
                                    ? selectedColor
                                    : Colors.white,
                              ),
                      ))),
              const SizedBox(height: 10),
              TextField(
                controller: _nomeController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _sobNController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _logController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _mailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              InternationalPhoneNumberInput(
                onInputChanged: (PhoneNumber number) {
                  numberint = number.phoneNumber;
                },
                onInputValidated: (bool value) {},
                selectorConfig: const SelectorConfig(
                  selectorType: PhoneInputSelectorType.BOTTOM_SHEET,
                  showFlags: true,
                ),
                ignoreBlank: false,
                autoValidateMode: AutovalidateMode.disabled,
                selectorTextStyle: const TextStyle(color: Colors.black),
                initialValue: number,
                textFieldController: _contController,
                formatInput: false,
                keyboardType: const TextInputType.numberWithOptions(
                  signed: true,
                  decimal: true,
                ),
                inputBorder: const OutlineInputBorder(),
                onSaved: (PhoneNumber number) {
                  //print(number);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DropdownButton<String>(
                    value: orderv,
                    hint: const Text('Select an Option'),
                    elevation: 14,
                    style: const TextStyle(color: Colors.black),
                    underline: Container(
                      height: 2,
                      color: Colors.blue,
                    ),
                    items: order.map<DropdownMenuItem<String>>((String value) {
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
                    icon: const Icon(Icons.expand_more),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Selected Color:',
                        style: TextStyle(fontSize: 18),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: EdgeInsets.only(
                            top: (isHovered) ? 5 : 16.0,
                            bottom: !(isHovered) ? 5 : 16),
                        child: InkWell(
                          onTap: () {
                            _showColorPickerDialog();
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: selectedColor,
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onHover: (val) {
                            setState(() {
                              isHovered = val;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('Cancelar'),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        ElevatedButton(
          onPressed: () {
            int i = 0;
            String n = "${_nomeController.text} ${_sobNController.text}";

            if (orderv == "Admin") i = 1;
            alteruser(
              widget.id,
              n,
              _contController.text,
              _logController.text,
              _mailController.text,
              i,
              selectedColor.toString().substring(10, 16),
            );
            
            Navigator.pop(context);

          
          },
          child: const Text("Confirmar"),
        ),
      ],
    );
  }

  void _showColorPickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecione uma Cor'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                setState(() {
                  selectedColor = color;
                });
              },
              showLabel: true,
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o AlertDialog
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> alteruser(dynamic id, name, cont, log, mail, type, color) async {
    await http.get(Uri.parse(
        'https://services.interagit.com/API/api_Calendar.php?query_param=6&id=$id&Name=$name&Cont=$cont&Log=$log&Mail=$mail&Type=$type&Color=$color'));
    _uploadImage(int.parse(id));
  }
}
