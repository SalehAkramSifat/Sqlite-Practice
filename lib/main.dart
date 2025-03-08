import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController noteController = TextEditingController();
  List<Map<String, dynamic>> notes = [];

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    try {
      final data = await DatabaseHelper.instance.getNotes();
      print('Loaded Notes: $data');
      if (data.isEmpty) {
        print("No notes found in the database.");
      }
      setState(() {
        notes = data;
      });
    } catch (e) {
      print("Error loading notes: $e");
    }
  }

  Future<void> _saveNote() async {
    try {
      if (noteController.text.isEmpty) return;

      await DatabaseHelper.instance.insertNote(noteController.text);
      print('Note Saved: ${noteController.text}');
      noteController.clear();
      await _loadNotes();
    } catch (e) {
      print("Error saving note: $e");
    }
  }

  Future<void> _deleteNote(int id) async {
    try {
      await DatabaseHelper.instance.deleteNote(id);
      print('Note Deleted: $id');
      await _loadNotes();
    } catch (e) {
      print("Error deleting note: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "SQLite Database",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blue,
      ),
      backgroundColor: Colors.white12,
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: noteController,
              decoration: InputDecoration(
                labelText: "What's On your mind?",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              minLines: 1,
            ),
            SizedBox(height: 10),
            TextButton(
              onPressed: _saveNote,
              style: TextButton.styleFrom(
                backgroundColor: Colors.black,
                elevation: 4,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Save',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: notes.isEmpty ? 1 : notes.length,
                itemBuilder: (context, index) {
                  if (notes.isEmpty) {
                    return Center(child: Text("No notes available"));
                  }
                  return Card(
                    child: ListTile(
                      title: Text(notes[index]['content']),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNote(notes[index]['id']),
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}

// DatabaseHelper class

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'notes_database.db');
    print('Database Path: $path');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(''' 
          CREATE TABLE notes(
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            content TEXT
          )
        ''');
      },
    );
  }

  // Insert Note
  Future<void> insertNote(String content) async {
    final db = await database;
    await db.insert('notes', {'content': content},
        conflictAlgorithm: ConflictAlgorithm.replace);
    print('Inserted Note: $content');
  }

  // Get Notes
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