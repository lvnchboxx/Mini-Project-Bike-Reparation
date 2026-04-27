import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/service_item.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();

  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'bike_repair.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE services (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');
  }

  Future<void> seedDefaultServices() async {
    final services = await getServices();

    if (services.isEmpty) {
      await insertService(ServiceItem(name: 'Full Bike Check', price: 250000));
      await insertService(ServiceItem(name: 'Changing Chain', price: 10000));
      await insertService(ServiceItem(name: 'Brake Repair', price: 20000));
    }
  }

  Future<int> insertService(ServiceItem service) async {
    final db = await database;

    return await db.insert(
      'services',
      service.toMap(),
    );
  }

  Future<List<ServiceItem>> getServices() async {
    final db = await database;

    final result = await db.query(
      'services',
      orderBy: 'id DESC',
    );

    return result.map((map) => ServiceItem.fromMap(map)).toList();
  }

  Future<int> updateService(ServiceItem service) async {
    final db = await database;

    return await db.update(
      'services',
      service.toMap(),
      where: 'id = ?',
      whereArgs: [service.id],
    );
  }

  Future<int> deleteService(int id) async {
    final db = await database;

    return await db.delete(
      'services',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}