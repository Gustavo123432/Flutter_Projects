import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:my_flutter_project/Bar/drawerBar.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/pudu_robot_model.dart';
import 'database/botdelivery_database.dart';
import 'pages/register_pudu.dart';
import 'pages/robot_menu.dart';

class HomePudu extends StatefulWidget {
  const HomePudu({super.key});

  @override
  State<HomePudu> createState() => _HomePuduState();
}

class _HomePuduState extends State<HomePudu> {
  late Stream<List<PuduRobot>> robotStream;
  final StreamController<List<PuduRobot>> robotController = StreamController.broadcast();
  List<PuduRobot> currentRobots = [];
  final dbHelper = PuduDatabase.instance;

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _fetchRobots();
  }

  void _initializeStream() {
    robotStream = robotController.stream;
  }

  Future<void> _fetchRobots() async {
    try {
      final robots = await dbHelper.getAllRobots();
      print('Fetched robots: ${robots.map((r) => r.toMap()).toList()}');
      setState(() {
        currentRobots = robots;
        robotController.add(robots);
      });
    } catch (e) {
      print('Erro ao buscar Robots: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar Robots: ${e.toString()}')),
      );
    }
  }

  void _showRobotActions(PuduRobot robot, BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: 340,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 246, 141, 45),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.precision_manufacturing,
                      color: Colors.white,
                      size: 30,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            robot.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            robot.type,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 193, 221, 224),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu, color: Color.fromARGB(255, 18, 192, 183)),
                      ),
                      title: const Text('Menu Robot'),
                      subtitle: const Text('Menu Robot'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => RobotMenu(robot: robot),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.info_outline, color: Colors.blue.shade700),
                      ),
                      title: const Text('Detalhes'),
                      subtitle: const Text('Ver informações detalhadas do Robot'),
                      onTap: () {
                        Navigator.pop(context);
                        _showRobotDetails(robot);
                      },
                    ),
                    /*ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.edit, color: Colors.green.shade700),
                      ),
                      title: const Text('Editar'),
                      subtitle: const Text('Modificar informações do Robot'),
                      onTap: () {
                        // Implementar edição
                        Navigator.pop(context);
                      },
                    ),*/
                
                    
                    ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.delete_outline, color: Colors.red.shade700),
                      ),
                      title: const Text('Excluir'),
                      subtitle: const Text('Remover este Robot'),
                      onTap: () async {
                        Navigator.pop(context);
                        _confirmDelete(robot);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRobotDetails(PuduRobot robot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            robot.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                leading: const Icon(Icons.wifi),
                title: const Text('IP Address'),
                subtitle: Text(robot.ip),
              ),
              ListTile(
                leading: const Icon(Icons.devices),
                title: const Text('Device ID'),
                subtitle: Text(robot.idDevice),
              ),
              ListTile(
                leading: const Icon(Icons.location_on),
                title: const Text('Region'),
                subtitle: Text(robot.region),
              ),
              ListTile(
                leading: const Icon(Icons.category),
                title: const Text('Type'),
                subtitle: Text(robot.type),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text('Fechar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(PuduRobot robot) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text('Deseja realmente excluir o Robot ${robot.name}?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Excluir',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () async {
                if (robot.id != null) {
                  await dbHelper.delete(robot.id!);
                  if (mounted) {
                    Navigator.of(context).pop();
                    _fetchRobots();
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }

  void logout(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Pretende fazer Log Out?'),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Confirmar'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (ctx) => LoginForm()),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 246, 141, 45),
        title: const Text('Bot Delivery'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchRobots,
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: const DrawerBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const RegisterPudu()),
          );
          if (result == true) {
            _fetchRobots();
          }
        },
        backgroundColor: const Color.fromARGB(255, 246, 141, 45),
        child: const Icon(Icons.add),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: StreamBuilder<List<PuduRobot>>(
            stream: robotStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Erro: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      'Nenhum Robot cadastrado',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                );
              }

              final robots = snapshot.data!;
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: robots.length,
                  itemBuilder: (context, index) {
                    final robot = robots[index];
                    return Card(
                      elevation: 4,
                      child: InkWell(
                        onTap: () => _showRobotActions(robot, context),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(255, 246, 141, 45),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.precision_manufacturing,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          robot.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          robot.type,
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const Spacer(),
                              Text(
                                'IP: ${robot.ip}',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Region: ${robot.region}',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    robotController.close();
    super.dispose();
  }
} 