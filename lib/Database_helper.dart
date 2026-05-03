import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async { //récupère le chemin du téléphone ,crée le fichier favorites.db et ouvre la base de données
    if (_database != null) return _database!;
    _database = await _initDB('favorites.db');
    return _database!;//future qui retourne la base de données initialisée ou déjà existante
  }

  Future<Database> _initDB(String filePath) async {//je ne bloque pas l’application, je te donne un Future”/Un Future représente une valeur qui sera disponible plus tard (pas immédiatement).
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
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        songName TEXT NOT NULL UNIQUE
      )
    ''');
  }

  Future<List<String>> getFavorites() async {
    final db = await database;
    final result = await db.query('favorites');
    return result.map((e) => e['songName'] as String).toList();
  }

  Future<void> addFavorite(String songName) async {
    final db = await database;
    await db.insert(
      'favorites',
      {'songName': songName},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFavorite(String songName) async {
    final db = await database;
    await db.delete(
      'favorites',
      where: 'songName = ?',
      whereArgs: [songName],
    );
  }
}