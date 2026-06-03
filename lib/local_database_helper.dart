import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseHelper {
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._init();
  static Database? _database;

  LocalDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('cathedral_notes.db');
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

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE local_notes (
        id INTEGER PRIMARY KEY,
        userId INTEGER NOT NULL,
        eventId INTEGER,
        eventTitle TEXT,
        title TEXT,
        content TEXT,
        createdAt TEXT,
        syncStatus TEXT NOT NULL
      )
    ''');
  }

  // 📥 Cache downloaded network notes locally
  Future<void> refreshLocalCache(List<dynamic> networkNotes) async {
    final db = await instance.database;

    // Clear out old synced records to prevent stale duplicates
    await db.delete('local_notes', where: 'syncStatus = ?', whereArgs: ['SYNCED']);

    for (var note in networkNotes) {
      await db.insert(
        'local_notes',
        {
          'id': note['id'],
          'userId': note['userId'] ?? note['user_id'],
          'eventId': note['eventId'],
          'eventTitle': note['eventTitle'],
          'title': note['title'],
          'content': note['content'],
          'createdAt': note['createdAt'] ?? note['dateCreated'] ?? note['date'],
          'syncStatus': 'SYNCED',
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  // 📝 Save a brand new offline/edited note to the queue
  Future<int> insertOfflineNote(Map<String, dynamic> noteData) async {
    final db = await instance.database;
    // Generate a temporary negative integer ID for local storage tracking so it doesn't clash with real database increments
    final int temporaryId = DateTime.now().millisecondsSinceEpoch * -1;

    await db.insert('local_notes', {
      'id': temporaryId,
      'userId': noteData['userId'],
      'eventId': noteData['eventId'],
      'eventTitle': noteData['eventTitle'],
      'title': noteData['title'],
      'content': noteData['content'],
      'createdAt': DateTime.now().toIso8601String(),
      'syncStatus': 'PENDING',
    });
    return temporaryId;
  }

  // 🔍 Retrieve local records matching user session rules
  Future<List<Map<String, dynamic>>> getUserNotes(int userId) async {
    final db = await instance.database;
    return await db.query(
      'local_notes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  // 🔄 Get all pending notes ready to be uploaded to Spring Boot
  Future<List<Map<String, dynamic>>> getPendingNotes() async {
    final db = await instance.database;
    return await db.query('local_notes', where: 'syncStatus = ?', whereArgs: ['PENDING']);
  }

  // 🗑️ Mark synced or delete temp record after a successful upload
  Future<void> deleteNote(int id) async {
    final db = await instance.database;
    await db.delete('local_notes', where: 'id = ?', whereArgs: [id]);
  }
}