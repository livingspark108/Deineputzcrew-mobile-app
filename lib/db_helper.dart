import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'task_model.dart';

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
      version: 3, // 🔥 IMPORTANT: VERSION INCREASED
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
        if (oldVersion < 3) {
          await db.execute("ALTER TABLE tasks ADD COLUMN radius INTEGER DEFAULT 500");
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
        auto_checkout INTEGER DEFAULT 1,
        total_work_time TEXT,
        radius INTEGER DEFAULT 300
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

  Future<List<Map<String, dynamic>>> getOldPendingTasks() async {
    final dbClient = await db;
    final now = DateTime.now();
    final oneDayAgo = now.subtract(const Duration(days: 1));
    final cutoffDate = oneDayAgo.toIso8601String().substring(0, 10); // yyyy-MM-dd format
    
    return await dbClient.query(
      'tasks',
      where: 'date < ? AND status != ?',
      whereArgs: [cutoffDate, 'completed'],
    );
  }

  Future<int> deleteOldTask(String taskId) async {
    final dbClient = await db;
    return await dbClient.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  // ================= PUNCH ACTIONS =================
  Future<int> insertPunchAction(Map<String, dynamic> action) async {
    final dbClient = await db;
    final String taskId = (action['task_id'] ?? '').toString();
    final String type = _normalizeActionType(action['type']?.toString());

    final Map<String, dynamic> normalizedAction = Map<String, dynamic>.from(action);
    if (type.isNotEmpty) {
      normalizedAction['type'] = type;
    }

    if (taskId.isNotEmpty && type.isNotEmpty) {
      final existing = await dbClient.query(
        'punch_actions',
        columns: ['id', 'type'],
        where: 'synced = ? AND task_id = ?',
        whereArgs: [0, taskId],
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final existingType =
            _normalizeActionType(existing.first['type']?.toString());
        if (existingType == type) {
          return 0;
        }
      }
    }

    return await dbClient.insert('punch_actions', normalizedAction);
  }

  String _normalizeActionType(String? type) {
    if (type == null) return '';
    return type.replaceAll('_', '-').trim().toLowerCase();
  }

  Future<int> pruneDuplicatePunchActions() async {
    final dbClient = await db;
    final rows = await dbClient.query(
      'punch_actions',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'timestamp DESC',
    );

    final Map<String, int> latestByKey = {};
    final List<int> toDelete = [];

    for (final row in rows) {
      final String taskId = (row['task_id'] ?? '').toString();
      final String type = _normalizeActionType(row['type']?.toString());
      final String key = '$taskId|$type';

      if (latestByKey.containsKey(key)) {
        final id = row['id'] as int?;
        if (id != null) {
          toDelete.add(id);
        }
      } else {
        final id = row['id'] as int?;
        if (id != null) {
          latestByKey[key] = id;
        }
      }
    }

    int deleted = 0;
    for (final id in toDelete) {
      deleted += await dbClient.delete(
        'punch_actions',
        where: 'id = ?',
        whereArgs: [id],
      );
    }

    return deleted;
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

  Future<void> clearPendingPunchActions() async {
    final dbClient = await db;
    await dbClient.delete(
      'punch_actions',
      where: 'synced = ?',
      whereArgs: [0],
    );
  }

  // ================= CLOSE =================
  Future<void> close() async {
    final dbClient = await db;
    await dbClient.close();
    _db = null;
  }
}

// New DatabaseHelper class for background tasks
class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'app_tasks.db');

    return await openDatabase(
      path,
      version: 2,
      onCreate: (Database db, int version) async {
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
            longg TEXT,
            punch_in INTEGER,
            punch_out INTEGER,
            break_in INTEGER,
            break_out INTEGER,
            day TEXT,
            date TEXT,
            auto_checkin INTEGER,
            auto_checkout INTEGER DEFAULT 1,
            total_work_time TEXT,
            radius INTEGER DEFAULT 300
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Add auto_checkout column if it doesn't exist
          try {
            await db.execute('ALTER TABLE tasks ADD COLUMN auto_checkout INTEGER DEFAULT 1');
            print('✅ Added auto_checkout column to tasks table');
          } catch (e) {
            print('⚠️ auto_checkout column might already exist: $e');
          }
          
          // Update radius default if needed
          try {
            await db.execute('ALTER TABLE tasks ADD COLUMN radius INTEGER DEFAULT 300');
            print('✅ Added radius column to tasks table');
          } catch (e) {
            print('⚠️ radius column might already exist: $e');
          }
        }
      },
    );
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('tasks');

    return List.generate(maps.length, (i) {
      return Task.fromJson(maps[i]);
    });
  }

  Future<void> insertTask(Task task) async {
    final db = await database;
    await db.insert(
      'tasks',
      {
        'id': task.id,
        'task_name': task.taskName,
        'start_time': task.startTime,
        'end_time': task.endTime,
        'location_name': task.locationName,
        'priority': task.priority,
        'status': task.status,
        'lat': task.lat,
        'longg': task.longg,
        'punch_in': task.punchIn ? 1 : 0,
        'punch_out': task.punchOut ? 1 : 0,
        'break_in': task.breakIn ? 1 : 0,
        'break_out': task.breakOut ? 1 : 0,
        'day': task.day,
        'date': task.date,
        'auto_checkin': task.autoCheckin ? 1 : 0,
        'total_work_time': task.totalWorkTime,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateTaskPunchIn(String taskId, bool punchIn) async {
    final db = await database;
    await db.update(
      'tasks',
      {'punch_in': punchIn ? 1 : 0},
      where: 'id = ?',
      whereArgs: [taskId],
    );
  }

  Future<void> clearAllTasks() async {
    final db = await database;
    await db.delete('tasks');
  }
}
