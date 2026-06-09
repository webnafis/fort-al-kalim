import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/word_model.dart';

final localDbServiceProvider = Provider<LocalDbService>((_) => LocalDbService());

/// SQLite local cache for word content and user progress.
/// Enables offline play and fast local access.
class LocalDbService {
  static Database? _db;

  Future<Database> get db async {
    _db ??= await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
      return openDatabase(
        'fort_al_kalim_web.db',
        version: 1,
        onCreate: _createTables,
      );
    }
    
    if (defaultTargetPlatform == TargetPlatform.windows || 
        defaultTargetPlatform == TargetPlatform.linux || 
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path   = join(dbPath, 'fort_al_kalim.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Words table
    await db.execute('''
      CREATE TABLE words (
        id          TEXT PRIMARY KEY,
        level       INTEGER NOT NULL,
        arabicText  TEXT NOT NULL,
        englishText TEXT NOT NULL,
        audioUrl    TEXT NOT NULL,
        imageUrl    TEXT NOT NULL,
        writeTiles  TEXT NOT NULL
      )
    ''');

    // Word progress table (per user, per word, per section)
    await db.execute('''
      CREATE TABLE word_progress (
        id          TEXT PRIMARY KEY,
        userId      TEXT NOT NULL,
        wordId      TEXT NOT NULL,
        section     TEXT NOT NULL,
        baseAp      REAL NOT NULL,
        currentAp   REAL NOT NULL,
        lockUntil   INTEGER,
        isBonusWord INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Create indexes for fast lookups
    await db.execute('CREATE INDEX idx_words_level ON words(level)');
    await db.execute('CREATE INDEX idx_progress_user ON word_progress(userId)');
    await db.execute('CREATE INDEX idx_progress_word ON word_progress(wordId)');
  }

  // ── Words ────────────────────────────────────────────────────────
  Future<List<WordModel>> getWordsForLevel(int level) async {
    final database = await db;
    final rows = await database.query(
      'words',
      where: 'level = ?',
      whereArgs: [level],
    );
    return rows.map(_rowToWord).toList();
  }

  Future<void> cacheWords(List<WordModel> words) async {
    final database = await db;
    final batch    = database.batch();
    for (final w in words) {
      batch.insert(
        'words',
        _wordToRow(w),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  // ── Progress ─────────────────────────────────────────────────────
  Future<void> upsertProgress(WordProgress p) async {
    final database = await db;
    await database.insert(
      'word_progress',
      _progressToRow(p),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<WordProgress>> getProgressForUser(String userId) async {
    final database = await db;
    final rows = await database.query(
      'word_progress',
      where: 'userId = ?',
      whereArgs: [userId],
    );
    return rows.map(_rowToProgress).toList();
  }

  // ── Serialization helpers ────────────────────────────────────────
  WordModel _rowToWord(Map<String, dynamic> row) {
    return WordModel(
      id:          row['id'] as String,
      level:       row['level'] as int,
      arabicText:  row['arabicText'] as String,
      englishText: row['englishText'] as String,
      audioUrl:    row['audioUrl'] as String,
      imageUrl:    row['imageUrl'] as String,
      writeTiles:  (row['writeTiles'] as String).split('|'),
    );
  }

  Map<String, dynamic> _wordToRow(WordModel w) => {
    'id':          w.id,
    'level':       w.level,
    'arabicText':  w.arabicText,
    'englishText': w.englishText,
    'audioUrl':    w.audioUrl,
    'imageUrl':    w.imageUrl,
    'writeTiles':  w.writeTiles.join('|'), // store as pipe-separated string
  };

  WordProgress _rowToProgress(Map<String, dynamic> row) {
    return WordProgress(
      userId:      row['userId'] as String,
      wordId:      row['wordId'] as String,
      section:     row['section'] as String,
      baseAp:      row['baseAp'] as double,
      currentAp:   row['currentAp'] as double,
      lockUntil:   row['lockUntil'] != null
                     ? DateTime.fromMillisecondsSinceEpoch(row['lockUntil'] as int)
                     : null,
      isBonusWord: (row['isBonusWord'] as int) == 1,
    );
  }

  Map<String, dynamic> _progressToRow(WordProgress p) => {
    'id':          '${p.userId}_${p.wordId}_${p.section}',
    'userId':      p.userId,
    'wordId':      p.wordId,
    'section':     p.section,
    'baseAp':      p.baseAp,
    'currentAp':   p.currentAp,
    'lockUntil':   p.lockUntil?.millisecondsSinceEpoch,
    'isBonusWord': p.isBonusWord ? 1 : 0,
  };

  Future<void> close() async {
    final database = await db;
    await database.close();
    _db = null;
  }
}
