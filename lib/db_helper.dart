import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DBHelper {
  static final DBHelper _instance = DBHelper._internal();
  factory DBHelper() => _instance;
  DBHelper._internal();

  static Database? _db;

  // ================= OPEN DATABASE =================
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
      version: 2, // 🔥 IMPORTANT: VERSION INCREASED
      onCreate: (Database db, int version) async {
        await _createTables(db);
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        // 🔁 MIGRATION FOR OLD USERS
        if (oldVersion < 2) {
          await db.execute("ALTER TABLE tasks ADD COLUMN lat TEXT");
          await db.execute("ALTER TABLE tasks ADD COLUMN long TEXT");
          await db.execute("ALTER TABLE tasks ADD COLUMN auto_checkin INTEGER");
          await db.execute("ALTER TABLE tasks ADD COLUMN total_work_time TEXT");
        }
      },
    );
  }

  // ================= CREATE TABLES =================
  Future<void> _createTables(Database db) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        task_name TEXT,
        start_time TEXT,
        end_time TEXT,
        location_name TEXT,
        priority TEXT,
        status TEXT,

        lat TEXT,
        long TEXT,

        punch_in INTEGER,
        punch_out INTEGER,
        break_in INTEGER,
        break_out INTEGER,

        day TEXT,
        date TEXT,

        auto_checkin INTEGER,
        total_work_time TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE punch_actions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        task_id TEXT,
        type TEXT,
        lat TEXT,
        long TEXT,
        image_path TEXT,
        timestamp TEXT,
        remark TEXT,
        synced INTEGER
      )
    ''');
  }

  // ================= TASKS =================
  Future<int> insertTask(Map<String, dynamic> task) async {
    final dbClient = await db;
    return await dbClient.insert(
      'tasks',
      task,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
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
    return await dbClient.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearTasks() async {
    final dbClient = await db;
    await dbClient.delete('tasks');
  }

  // ================= PUNCH ACTIONS =================
  Future<int> insertPunchAction(Map<String, dynamic> action) async {
    final dbClient = await db;
    return await dbClient.insert('punch_actions', action);
  }

  Future<List<Map<String, dynamic>>> getPunchActions() async {
    final dbClient = await db;
    return await dbClient.query(
      'punch_actions',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp ASC',
    );
  }

  Future<int> markPunchActionSynced(int id) async {
    final dbClient = await db;
    return await dbClient.update(
      'punch_actions',
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> getPendingSyncCount() async {
    final dbClient = await db;
    final result = await dbClient.rawQuery(
      'SELECT COUNT(*) as count FROM punch_actions WHERE synced = 0'
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<int> deletePunchAction(int id) async {
    final dbClient = await db;
    return await dbClient.delete(
      'punch_actions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ================= CLOSE =================
  Future<void> close() async {
    final dbClient = await db;
    await dbClient.close();
    _db = null;
  }
}
