import 'dart:async';
//import 'dart:io';

import 'package:path/path.dart';
//import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';


class DatabaseHelper {
  static final  _dbName = "app.db";
  static final  _dbVer = 1;

  static final _mfaopenTableName = "mfa_open";

  //make constructor private. 
  DatabaseHelper._privateConstructor();

  //make DatabaseHelper singleton
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database _database;

  Future<Database> get database async {
    if (_database != null) return _database;
    _database = await _initDatabase();
    return _database;
  }

  _initDatabase() async {
    var databasesPath = await getDatabasesPath();
    String dbPath = join(databasesPath, _dbName);

    return await openDatabase(dbPath,
      version: _dbVer,
      onCreate: _createDb,
    );
  }

  _createDb(Database db, int version) async {
    await db.execute('''create table $_mfaopenTableName (
      id INTEGER PRIMARAY KEY,
      content TEXT
    )''');
  }

  Future<int> insertMfaObject(int id, String content) async {
    var db = await database;
    return await db.rawInsert('INSERT INTO $_mfaopenTableName(id, content) VALUES(?, ?)', [id, content]);
  }

  Future<String> getMfaObject(int id) async {
    var db = await database;
    var rows =  await db.rawQuery('SELECT content FROM $_mfaopenTableName WHERE id=?', [id,]);
    if (rows.length==0) return '';
    return rows[0]['content'];
  }
}