import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if(_database != null) return _database!;
    _database = await _initDB();
    return _database!;

  }
  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes_database.db');
    print('Database Path: $path');

    return await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
        CREATE TABLE notes(id INTEGER PRIMARY KEY AUTOINCREMENT, content TEXT)
      ''');
    });
  }
  Future<void> insertNote(String content) async {
    final db = await database;
    await db.insert('notes', {'content': content},
        conflictAlgorithm: ConflictAlgorithm.replace);
    print('Inserted Note: $content');
  }
  Future<List<Map<String, dynamic>>> getNotes() async {
    final db = await database;
    var result = await db.query('notes');
    print('Database Notes: $result');
    return result;
  }

  // Delete Note
  Future<void> deleteNote(int id) async {
    final db = await database;
    await db.delete('notes', where: "id = ?", whereArgs: [id]);
    print('Deleted Note with ID: $id');
  }


}