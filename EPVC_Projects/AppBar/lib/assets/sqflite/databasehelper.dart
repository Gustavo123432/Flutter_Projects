import 'package:my_flutter_project/assets/models/cartItem.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  static Database? _database;

  DatabaseHelper._internal();

  // Open the database
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'cart.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  // Create tables
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE cart (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        image TEXT,
        price REAL,
        quantity TEXT
      )
    ''');
  }

  // Insert cart item
  Future<void> insertCartItem(CartItem cartItem) async {
    final db = await database;
    try {
      await db.insert(
        'cart',
        cartItem.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('Error inserting cart item: $e');
    }
  }

  // Fetch all cart items
  Future<List<CartItem>> fetchCartItems() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> maps = await db.query('cart');
      return List.generate(maps.length, (i) {
        return CartItem.fromMap(maps[i]);
      });
    } catch (e) {
      print('Error fetching cart items: $e');
      return [];
    }
  }

  // Remove cart item
  Future<void> removeCartItem(int id) async {
    final db = await database;
    try {
      await db.delete(
        'cart',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Error removing cart item: $e');
    }
  }

  // Close the database (optional, for cleanup)
  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}