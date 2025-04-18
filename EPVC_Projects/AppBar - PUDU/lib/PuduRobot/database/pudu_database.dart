import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/pudu_robot_model.dart';

class PuduDatabase {
  static final PuduDatabase instance = PuduDatabase._init();
  static Database? _database;

  PuduDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pudurobotinfo.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE pudurobotinfo(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        ip TEXT NOT NULL,
        idDevice TEXT NOT NULL,
        name TEXT NOT NULL,
        secretDevice TEXT NOT NULL,
        region TEXT NOT NULL,
        type TEXT NOT NULL,
        idGroup TEXT NOT NULL,
        groupName TEXT NOT NULL,
        shopName TEXT NOT NULL,
        robotIdd TEXT NOT NULL,
        nameRobot TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE pudurobotinfo ADD COLUMN idGroup TEXT DEFAULT ""');
      await db.execute('ALTER TABLE pudurobotinfo ADD COLUMN groupName TEXT DEFAULT ""');
      await db.execute('ALTER TABLE pudurobotinfo ADD COLUMN shopName TEXT DEFAULT ""');
      await db.execute('ALTER TABLE pudurobotinfo ADD COLUMN robotIdd TEXT DEFAULT ""');
      await db.execute('ALTER TABLE pudurobotinfo ADD COLUMN nameRobot TEXT DEFAULT ""');
    }
  }

  Future<PuduRobot> create(PuduRobot robot) async {
    final db = await database;
    final id = await db.insert('pudurobotinfo', robot.toMap());
    return PuduRobot(
      id: id,
      ip: robot.ip,
      idDevice: robot.idDevice,
      name: robot.name,
      secretDevice: robot.secretDevice,
      region: robot.region,
      type: robot.type,
      idGroup: robot.idGroup,
      groupName: robot.groupName,
      shopName: robot.shopName,
      robotIdd: robot.robotIdd,
      nameRobot: robot.nameRobot,
    );
  }

  Future<List<PuduRobot>> getAllRobots() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('pudurobotinfo');
    
    return List.generate(maps.length, (i) => PuduRobot.fromMap(maps[i]));
  }

  Future<PuduRobot?> getRobot(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'pudurobotinfo',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return PuduRobot.fromMap(maps.first);
    }
    return null;
  }

  Future<int> update(PuduRobot robot) async {
    final db = await database;
    return db.update(
      'pudurobotinfo',
      robot.toMap(),
      where: 'id = ?',
      whereArgs: [robot.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await database;
    return await db.delete(
      'pudurobotinfo',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
} 