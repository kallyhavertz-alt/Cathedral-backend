import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalDatabaseHelper {
  static final LocalDatabaseHelper instance = LocalDatabaseHelper._init();
  static Database? _database;

  LocalDatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    // 🔄 V3 Rename safely forces a migration to handle the new feedback storage layer
    _database = await _initDB('cathedral_notes_v3.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
      onUpgrade: _onUpgradeDB,
    );
  }

  Future _createDB(Database db, int version) async {
    // 🛡️ Table 1: Notes Cache Layer
    await db.execute('''
      CREATE TABLE local_notes (
        id INTEGER PRIMARY KEY,
        userId INTEGER NOT NULL,
        eventId INTEGER,
        eventTitle TEXT,
        title TEXT,
        content TEXT,
        createdAt TEXT,
        syncStatus TEXT NOT NULL,
        isFavorite INTEGER DEFAULT 0  -- 💾 0 = False, 1 = True
      )
    ''');
    print("✅ SQLite Layout: 'local_notes' table created.");

    // 🛡️ Table 2: Isolated Local Feedback Sync Queue Layer
    await db.execute('''
      CREATE TABLE local_feedback (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        feedback TEXT,
        submitted_at TEXT NOT NULL,
        stars_rated INTEGER NOT NULL,
        syncStatus TEXT NOT NULL       -- 📡 PENDING or SYNCED
      )
    ''');
    print("✅ SQLite Layout: 'local_feedback' table created successfully.");
    await _createEventsTable(db);
  }

  Future _onUpgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _createEventsTable(db);
    }
  }

  Future<void> _createEventsTable(Database db) async {
    await db.execute('''
      CREATE TABLE local_events (
        id INTEGER PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        date TEXT,
        isFavorite INTEGER DEFAULT 0,
        syncStatus TEXT NOT NULL
      )
    ''');
    print("✅ SQLite Layout: 'local_events' table initialized.");
  }


  // ==========================================
  // ⭐ FEEDBACK DATA OPERATORS (ISOLATED RUN)
  // ==========================================

  /// 📥 Inserts an offline/pending feedback record directly into local queue
  Future<int> insertOfflineFeedback(Map<String, dynamic> feedbackData) async {
    final db = await instance.database;
    print('💾 SQLITE APP ENGINE: Queueing feedback record locally.');

    return await db.insert('local_feedback', {
      'user_id': feedbackData['userId'],
      'feedback': feedbackData['feedback'],
      'submitted_at': feedbackData['submittedAt'] ?? DateTime.now().toIso8601String(),
      'stars_rated': feedbackData['starsRated'],
      'syncStatus': feedbackData['syncStatus'] ?? 'PENDING',
    });
  }

  /// 🔍 Fetch all pending feedback records awaiting backend cloud upload
  Future<List<Map<String, dynamic>>> getPendingFeedback() async {
    final db = await instance.database;
    return await db.query(
        'local_feedback',
        where: 'syncStatus = ?',
        whereArgs: ['PENDING']
    );
  }

  /// 🔄 Update status or delete a feedback row after it successfully reaches PostgreSQL
  Future<void> markFeedbackSynced(int localId) async {
    final db = await instance.database;
    await db.update(
      'local_feedback',
      {'syncStatus': 'SYNCED'},
      where: 'id = ?',
      whereArgs: [localId],
    );
    print('✅ SQLite Sync Ledger: Feedback record ID $localId marked SYNCED.');
  }

  // ==========================================
  // ⭐ EXISTING NOTE DATA OPERATORS
  // ==========================================

  Future<int> updateNoteFavoriteStatus(int noteId, int isFavoriteBit) async {
    final db = await instance.database;
    print('💾 SQLITE ENGINE: Mutating favorite status for Note #$noteId to bit: $isFavoriteBit');

    int rowsAffected = await db.update(
      'local_notes',
      {'isFavorite': isFavoriteBit},
      where: 'id = ?',
      whereArgs: [noteId],
    );
    print('💾 SQLITE RESULT: Affected $rowsAffected rows in local storage.');
    return rowsAffected;
  }

  Future<List<Map<String, dynamic>>> getFavoritesForUser(int userId) async {
    final db = await instance.database;
    print('💾 PROFILE CACHE ENGINE: Fetching synchronized favorites for User ID: $userId');

    return await db.query(
      'local_notes',
      where: 'userId = ? AND isFavorite = 1',
      whereArgs: [userId],
      orderBy: 'id DESC',
    );
  }

  // 📥 Cache downloaded network notes safely without reviving locally deleted records
  Future<void> refreshLocalCache(List<dynamic> networkNotes) async {
    final db = await instance.database;

    print('🔄 CACHE ENGINE START: Processing ${networkNotes.length} cloud records.');

    await db.transaction((txn) async {
      for (var jsonNote in networkNotes) {
        if (jsonNote['id'] == null) continue;
        final int serverNoteId = jsonNote['id'];

        // 🛡️ ISOLATION SHIELD: Check if this note is flagged as pending deletion locally
        final List<Map<String, dynamic>> localCheck = await txn.query(
          'local_notes',
          where: 'id = ?',
          whereArgs: [serverNoteId],
        );

        if (localCheck.isNotEmpty) {
          final String localSyncStatus = localCheck.first['syncStatus'] ?? 'SYNCED';

          // 🚨 IF PENDING DELETION: Reject the server's update to prevent ghost resurrections!
          if (localSyncStatus == 'DELETED') {
            print('🛡️ SYNC BLOCKED: Note ID $serverNoteId is marked DELETED locally. Rejecting cloud revival.');
            continue;
          }

          final dynamic serverFavValue = jsonNote['isFavorite'] ?? jsonNote['favorite'];
          final int serverFavoriteBit = (serverFavValue == true || serverFavValue == 1) ? 1 : 0;
          final int localFavoriteBit = localCheck.first['isFavorite'] ?? 0;
          final int finalFavoriteBit = (localFavoriteBit == 1) ? 1 : serverFavoriteBit;

          await txn.update(
            'local_notes',
            {
              'userId': jsonNote['userId'] ?? jsonNote['user_id'],
              'eventId': jsonNote['eventId'],
              'eventTitle': jsonNote['eventTitle'],
              'title': jsonNote['title'],
              'content': jsonNote['content'],
              'createdAt': jsonNote['createdAt'] ?? jsonNote['dateCreated'] ?? jsonNote['date'],
              'syncStatus': 'SYNCED',
              'isFavorite': finalFavoriteBit,
            },
            where: 'id = ?',
            whereArgs: [serverNoteId],
          );
        } else {
          // Insert a brand new record down from the cloud pipeline
          final dynamic serverFavValue = jsonNote['isFavorite'] ?? jsonNote['favorite'];
          final int serverFavoriteBit = (serverFavValue == true || serverFavValue == 1) ? 1 : 0;

          await txn.insert(
            'local_notes',
            {
              'id': serverNoteId,
              'userId': jsonNote['userId'] ?? jsonNote['user_id'],
              'eventId': jsonNote['eventId'],
              'eventTitle': jsonNote['eventTitle'],
              'title': jsonNote['title'],
              'content': jsonNote['content'],
              'createdAt': jsonNote['createdAt'] ?? jsonNote['dateCreated'] ?? jsonNote['date'],
              'syncStatus': 'SYNCED',
              'isFavorite': serverFavoriteBit,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      }
    });

    print('💾 CACHE SYNC ENGINE: Successfully synchronized local memory grid.');
  }
  /// 🗑️ Clean Online Purge: Wipes the note from SQLite completely
  Future<int> clearNoteFromHardware(int noteId) async {
    final db = await instance.database;
    print(' Mauri 💾 HARDWARE PURGE: Erasing Note ID $noteId permanently from disk.');
    return await db.delete(
      'local_notes',
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  /// 📥 Offline Deletion Queue: Marks a note as DELETED so it can sync to cloud later
  Future<int> queueOfflineDeletion(int noteId) async {
    final db = await instance.database;
    print('💾 SQLITE LAYER: Device offline. Flagging Note ID $noteId as DELETED in sync ledger.');
    return await db.update(
      'local_notes',
      {'syncStatus': 'DELETED'},
      where: 'id = ?',
      whereArgs: [noteId],
    );
  }

  Future<int> insertOfflineNote(Map<String, dynamic> noteData) async {
    final db = await instance.database;
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
      'isFavorite': 0,
    });
    return temporaryId;
  }

  Future<List<Map<String, dynamic>>> getUserNotes(int userId) async {
    final db = await instance.database;
    return await db.query(
      'local_notes',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<List<Map<String, dynamic>>> getPendingNotes() async {
    final db = await instance.database;
    return await db.query('local_notes', where: 'syncStatus = ?', whereArgs: ['PENDING']);
  }

  Future<void> deleteNote(int id) async {
    final db = await instance.database;
    await db.delete('local_notes', where: 'id = ?', whereArgs: [id]);
  }
  // ==========================================
  // ⭐ EVENT DATA OPERATORS
  // ==========================================

  /// 💾 Updates or sets the localized state tracker for an event item
  Future<int> updateEventFavoriteStatus(int eventId, int isFavoriteBit, Map<String, dynamic> eventDetails) async {
    final db = await instance.database;
    print('💾 SQLITE ENGINE: Mutating favorite status for Event #$eventId to bit: $isFavoriteBit');

    // Check if the event record exists locally first
    final List<Map<String, dynamic>> maps = await db.query(
      'local_events',
      where: 'id = ?',
      whereArgs: [eventId],
    );

    if (maps.isEmpty) {
      // Warm up caching by inserting details natively if missing on disk
      return await db.insert('local_events', {
        'id': eventId,
        'title': eventDetails['title'] ?? 'Church Event',
        'description': eventDetails['description'] ?? '',
        'date': eventDetails['date'] ?? DateTime.now().toIso8601String(),
        'isFavorite': isFavoriteBit,
        'syncStatus': 'PENDING',
      });
    } else {
      return await db.update(
        'local_events',
        {
          'isFavorite': isFavoriteBit,
          'syncStatus': 'PENDING',
        },
        where: 'id = ?',
        whereArgs: [eventId],
      );
    }
  }

  /// 🔍 Pulls down all items marked as true for the user profile layout
  Future<List<Map<String, dynamic>>> getFavoriteEvents() async {
    final db = await instance.database;
    return await db.query(
      'local_events',
      where: 'isFavorite = 1',
      orderBy: 'id DESC',
    );
  }

  /// 🛡️ Checks current disk status directly inside the Event Details initState block
  Future<bool> isEventFavorite(int eventId) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> result = await db.query(
      'local_events',
      columns: ['isFavorite'],
      where: 'id = ?',
      whereArgs: [eventId],
    );
    if (result.isEmpty) return false;
    return result.first['isFavorite'] == 1;
  }
}