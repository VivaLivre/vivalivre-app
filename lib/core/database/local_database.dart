import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

class LocalDatabase {
  static final LocalDatabase instance = LocalDatabase._init();
  static Database? _database;

  LocalDatabase._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('vivalivre.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getApplicationDocumentsDirectory();
    final path = join(dbPath.path, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const nullableTextType = 'TEXT';
    const integerType = 'INTEGER NOT NULL';

    await db.execute('''
CREATE TABLE health_entries (
  local_id $idType,
  remote_id $nullableTextType,
  user_id $textType,
  type $textType,
  description $nullableTextType,
  severity $textType,
  symptoms $textType,
  date $textType,
  sync_status $integerType
)
''');
  }

  Future<void> close() async {
    final db = await instance.database;
    db.close();
  }
}
