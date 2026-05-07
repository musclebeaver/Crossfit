import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalRecordService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  static Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), 'crossfit_offline.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE pending_records(id INTEGER PRIMARY KEY AUTOINCREMENT, data TEXT, timestamp INTEGER)',
        );
      },
    );
  }

  static Future<void> saveRecord(Map<String, dynamic> recordData) async {
    final db = await database;
    await db.insert(
      'pending_records',
      {
        'data': jsonEncode(recordData),
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      },
    );
  }

  static Future<List<Map<String, dynamic>>> getPendingRecords() async {
    final db = await database;
    return await db.query('pending_records', orderBy: 'timestamp ASC');
  }

  static Future<void> deleteRecord(int id) async {
    final db = await database;
    await db.delete('pending_records', where: 'id = ?', whereArgs: [id]);
  }
}
