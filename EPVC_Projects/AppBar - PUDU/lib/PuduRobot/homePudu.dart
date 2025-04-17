import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:my_flutter_project/Bar/drawerBar.dart';
import 'package:my_flutter_project/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RoboOrder {
  final String number;
  final String requester;
  final String group;
  final String description;
  final String total;
  final String troco;
  final String status;
  final String userPermission;
  final String imagem;

  RoboOrder({
    required this.number,
    required this.requester,
    required this.group,
    required this.description,
    required this.total,
    required this.troco,
    required this.status,
    required this.userPermission,
    required this.imagem,
  });

  factory RoboOrder.fromMap(Map<String, dynamic> map) {
    return RoboOrder(
      number: map['number']?.toString() ?? 'N/A',
      requester: map['requester'] ?? 'Desconhecido',
      group: map['group'] ?? 'Sem turma',
      description: map['description']?.toString() ?? 'Sem descrição',
      total: map['total']?.toString() ?? '0.00',
      troco: map['troco']?.toString() ?? '0.00',
      status: map['status']?.toString() ?? '0',
      imagem: map['imagem'] ?? '',
      userPermission: map['userPermission'] ?? 'Sem permissão',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'number': number,
      'requester': requester,
      'group': group,
      'description': description,
      'total': total,
      'troco': troco,
      'status': status,
      'imagem': imagem,
      'userPermission': userPermission,
    };
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('robo_orders.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE robo_orders(
        number TEXT PRIMARY KEY,
        requester TEXT,
        group_name TEXT,
        description TEXT,
        total TEXT,
        troco TEXT,
        status TEXT,
        imagem TEXT,
        userPermission TEXT
      )
    ''');
  }

  Future<List<RoboOrder>> getAllOrders() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('robo_orders');
    
    return List.generate(maps.length, (i) {
      return RoboOrder.fromMap({
        'number': maps[i]['number'],
        'requester': maps[i]['requester'],
        'group': maps[i]['group_name'],
        'description': maps[i]['description'],
        'total': maps[i]['total'],
        'troco': maps[i]['troco'],
        'status': maps[i]['status'],
        'imagem': maps[i]['imagem'],
        'userPermission': maps[i]['userPermission'],
      });
    });
  }

  Future<void> insertOrder(RoboOrder order) async {
    final db = await database;
    await db.insert(
      'robo_orders',
      {
        'number': order.number,
        'requester': order.requester,
        'group_name': order.group,
        'description': order.description,
        'total': order.total,
        'troco': order.troco,
        'status': order.status,
        'imagem': order.imagem,
        'userPermission': order.userPermission,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

class HomePudu extends StatefulWidget {
  const HomePudu({super.key});

  @override
  State<HomePudu> createState() => _HomePuduState();
}

class _HomePuduState extends State<HomePudu> {
  late Stream<List<RoboOrder>> roboOrderStream;
  final StreamController<List<RoboOrder>> roboOrderController = StreamController.broadcast();
  List<RoboOrder> currentOrders = [];
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _initializeStream();
    _fetchOrders();
  }

  void _initializeStream() {
    roboOrderStream = roboOrderController.stream;
  }

  Future<void> _fetchOrders() async {
    try {
      final orders = await dbHelper.getAllOrders();
      setState(() {
        currentOrders = orders;
        roboOrderController.add(orders);
      });
    } catch (e) {
      print('Erro ao buscar pedidos: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao carregar pedidos: ${e.toString()}')),
      );
    }
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
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (ctx) => LoginForm()),
                );
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
        backgroundColor: Color.fromARGB(255, 246, 141, 45),
        title: Text('Pedidos'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _fetchOrders,
          ),
          IconButton(
            onPressed: () => logout(context),
            icon: Icon(Icons.logout),
          ),
        ],
      ),
      drawer: DrawerBar(),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Center(
          child: StreamBuilder<List<RoboOrder>>(
            stream: roboOrderStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return FutureBuilder(
                  future: Future.delayed(Duration(seconds: 5)),
                  builder: (context, futureSnapshot) {
                    if (futureSnapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else {
                      return Center(child: Text('Sem Pedidos'));
                    }
                  },
                );
              } else if (snapshot.hasError) {
                return Center(child: Text('Erro ao carregar pedidos'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text('Sem Pedidos'));
              }

              List<RoboOrder> data = snapshot.data!;

              return GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(8.0),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1.0,
                ),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  RoboOrder order = data[index];
                  String formattedTotal = double.parse(order.total)
                      .toStringAsFixed(2)
                      .replaceAll('.', ',');
                  return GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text(
                              'Detalhes do Robo ${order.number}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                                color: Colors.black87,
                              ),
                            ),
                            content: SingleChildScrollView(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'IP: ${order.requester}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Nome: ${order.group}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'ID: ${order.group}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Região:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(
                                child: Text(
                                  'Fechar',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.blue,
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: Card(
                      color: Color.fromARGB(255, 228, 225, 223),
                      elevation: 4.0,
                      child: Padding(
                        padding: EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Pedido ${order.number}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: Colors.black87,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        'Nome: ${order.requester}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Turma: ${order.group}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        'Descrição: ${order.description}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[800],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12),
                              ],
                            ),
                            SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Total: $formattedTotal€',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                Text(
                                  'Troco: ${order.troco}€',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    roboOrderController.close();
    super.dispose();
  }
} 