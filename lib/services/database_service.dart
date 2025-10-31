import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/currency.dart';
import '../models/recent_search.dart';

class DatabaseService {
  // Singleton pattern
  static final DatabaseService instance = DatabaseService._init();
  static Database? _database;
  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('recent_searches.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';

    await db.execute('''
      CREATE TABLE recentSearches ( 
        id $idType, 
        fromCode $textType,
        fromName $textType,
        toCode $textType,
        toName $textType
      )
    ''');
  }

  Future<void> insertSearch(RecentSearch search) async {
    final db = await instance.database;
    // Delete existing pair to ensure the new one is at the top
    await db.delete(
      'recentSearches',
      where: 'fromCode = ? AND toCode = ?',
      whereArgs: [search.fromCurrency.code, search.toCurrency.code],
    );
    await db.insert('recentSearches', search.toMap());
  }

  Future<List<RecentSearch>> getRecentSearches() async {
    final db = await instance.database;
    final maps = await db.query(
      'recentSearches',
      orderBy: 'id DESC',
      limit: 10,
    );

    if (maps.isEmpty) {
      return [];
    }

    return List.generate(maps.length, (i) {
      return RecentSearch(
        id: maps[i]['id'] as int,
        fromCurrency: Currency(code: maps[i]['fromCode'] as String, name: maps[i]['fromName'] as String),
        toCurrency: Currency(code: maps[i]['toCode'] as String, name: maps[i]['toName'] as String),
      );
    });
  }

  Future<void> deleteSearch(int id) async {
    final db = await instance.database;
    await db.delete(
      'recentSearches',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // --- Deletes ALL records from the recentSearches table ---
  Future<void> clearRecentSearches() async {
    final db = await instance.database;
    await db.delete('recentSearches');
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
