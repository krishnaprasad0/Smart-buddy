import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/chat/domain/model/chat_session.dart';
import '../../features/chat/presentation/cubit/chat_state.dart';

class DatabaseService {
  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'smart_buddy.db');

    return await openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sessions (
        id TEXT PRIMARY KEY,
        title TEXT,
        createdAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sessionId TEXT,
        text TEXT,
        isAi INTEGER,
        timestamp TEXT,
        timeTakenMs INTEGER,
        tokenCount INTEGER,
        FOREIGN KEY (sessionId) REFERENCES sessions (id) ON DELETE CASCADE
      )
    ''');
  }

  // Session Operations
  Future<void> saveSession(ChatSession session) async {
    final db = await database;
    await db.insert(
      'sessions',
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChatSession>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'sessions',
      orderBy: 'createdAt DESC',
    );
    return List.generate(maps.length, (i) => ChatSession.fromMap(maps[i]));
  }

  Future<void> updateSessionTitle(String sessionId, String title) async {
    final db = await database;
    await db.update(
      'sessions',
      {'title': title},
      where: 'id = ?',
      whereArgs: [sessionId],
    );
  }

  Future<void> deleteSession(String sessionId) async {
    final db = await database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [sessionId]);
    await db.delete('messages', where: 'sessionId = ?', whereArgs: [sessionId]);
  }

  // Message Operations
  Future<void> saveMessage(String sessionId, ChatMessage message) async {
    final db = await database;
    await db.insert('messages', {
      'sessionId': sessionId,
      'text': message.text,
      'isAi': message.isAi ? 1 : 0,
      'timestamp': message.timestamp.toIso8601String(),
      'timeTakenMs': message.timeTaken?.inMilliseconds,
      'tokenCount': message.tokenCount,
    });
  }

  Future<List<ChatMessage>> getMessages(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'sessionId = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return ChatMessage(
        text: maps[i]['text'] as String,
        isAi: (maps[i]['isAi'] as int) == 1,
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
        timeTaken: maps[i]['timeTakenMs'] != null
            ? Duration(milliseconds: maps[i]['timeTakenMs'] as int)
            : null,
        tokenCount: maps[i]['tokenCount'] as int?,
      );
    });
  }

  Future<void> clearAll() async {
    final db = await database;
    await db.delete('sessions');
    await db.delete('messages');
  }
}
