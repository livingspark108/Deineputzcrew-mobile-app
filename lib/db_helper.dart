import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'tasks.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (Database db, int version) async {
        // Tasks table
        await db.execute('''
          CREATE TABLE tasks(
            id TEXT PRIMARY KEY,
            task_name TEXT,
            start_time TEXT,
            end_time TEXT,
            location_name TEXT,
            priority TEXT,
            status TEXT,
            punch_in INTEGER,
            punch_out INTEGER,
            break_in INTEGER,
            break_out INTEGER,
            day TEXT,
            datee TEXT,
          )
        ''');

        // Punch actions table
        await db.execute('''
          CREATE TABLE punch_actions(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            task_id TEXT,
            type TEXT,          -- punch_in / punch_out
            lat TEXT,
            long TEXT,
            image_path TEXT,
            timestamp TEXT,
            remark TEXT,
            synced INTEGER
          )
        ''');
      },
    );
  }

  // ---------------- TASKS ----------------
  Future<int> savePunchOutOffline(String taskId, String lat, String long, String remark, {String? imagePath}) async {
    final dbClient = await db;
    return await dbClient.insert('punch_actions', {
      'task_id': taskId,
      'type': 'punch_out',
      'lat': lat,
      'long': long,
      'remark': remark,
      'image_path': imagePath ?? '',
      'timestamp': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<int> insertTask(Map<String, dynamic> task) async {
    final dbClient = await db;
    return await dbClient.insert('tasks', task,
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<Map<String, dynamic>>> getTasks() async {
    final dbClient = await db;
    return await dbClient.query('tasks');
  }

  Future<int> updateTask(Map<String, dynamic> task) async {
    final dbClient = await db;
    return await dbClient.update(
      'tasks',
      task,
      where: 'id = ?',
      whereArgs: [task['id']],
    );
  }

  Future<int> deleteTask(String id) async {
    final dbClient = await db;
    return await dbClient.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- PUNCH ACTIONS ----------------

  Future<int> insertPunchAction(Map<String, dynamic> action) async {
    final dbClient = await db;
    return await dbClient.insert('punch_actions', action);
  }

  Future<List<Map<String, dynamic>>> getPunchActions() async {
    final dbClient = await db;
    return await dbClient.query('punch_actions');
  }

  Future<int> deletePunchAction(int id) async {
    final dbClient = await db;
    return await dbClient.delete('punch_actions', where: 'id = ?', whereArgs: [id]);
  }

  // ---------------- CLOSE ----------------
  Future<void> clearTasks() async {
    final dbClient = await db;
    await dbClient.delete('tasks');
  }
  Future close() async {
    final dbClient = await db;
    dbClient.close();
  }
}
