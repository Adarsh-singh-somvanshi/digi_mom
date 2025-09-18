// task_repository.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'task_model.dart';

class TaskRepository {
  static final TaskRepository instance = TaskRepository._init();

  static Database? _database;

  TaskRepository._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('tasks.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    final idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    final textType = 'TEXT NOT NULL';
    final boolType = 'INTEGER NOT NULL';
    final dateType = 'INTEGER NOT NULL'; // store dueDate as INTEGER

    await db.execute('''
    CREATE TABLE tasks (
      id $idType,
      title $textType,
      description $textType,
      dueDate $dateType,
      isCompleted $boolType
    )
    ''');
  }

  Future<Task> create(Task task) async {
    final db = await instance.database;
    final id = await db.insert('tasks', task.toMap());
    return task..id = id;
  }

  Future<List<Task>> readAllTasks() async {
    final db = await instance.database;
    final orderBy = 'dueDate ASC';
    final result = await db.query('tasks', orderBy: orderBy);
    return result.map((json) => Task.fromMap(json)).toList();
  }

  Future<int> update(Task task) async {
    final db = await instance.database;
    return db.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
  }

  Future<int> delete(int id) async {
    final db = await instance.database;
    return await db.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
