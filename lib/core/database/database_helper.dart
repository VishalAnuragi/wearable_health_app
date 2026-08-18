import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../../features/wearable/domain/wearable_service.dart';

class DatabaseHelper {
  static const _databaseName = "WearableHealth.db";
  static const _databaseVersion = 1;
  static const tableReadings = 'health_readings';

  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // We use INTEGER for is_synced because SQLite does not have a native boolean type.
    // 0 = False (Unsynced), 1 = True (Synced)
    await db.execute('''
      CREATE TABLE $tableReadings (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        heart_rate INTEGER NOT NULL,
        spo2 INTEGER NOT NULL,
        steps INTEGER NOT NULL,
        battery_level INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        is_synced INTEGER NOT NULL DEFAULT 0
      )
    ''');
  }

  // Insert a new reading from the wearable
  Future<int> insertReading(HealthDataPacket packet) async {
    final db = await database;
    return await db.insert(tableReadings, {
      'device_id': packet.deviceId,
      'heart_rate': packet.heartRate,
      'spo2': packet.spo2,
      'steps': packet.steps,
      'battery_level': packet.batteryLevel,
      'timestamp': packet.timestamp.toIso8601String(),
      'is_synced': 0,
    });
  }

  // Fetch unsynced records for the batch upload queue
  Future<List<Map<String, dynamic>>> getUnsyncedReadings({int limit = 100}) async {
    final db = await database;
    return await db.query(
        tableReadings,
        where: 'is_synced = ?',
        whereArgs: [0],
        limit: limit,
        orderBy: 'timestamp ASC'
    );
  }

  // Mark uploaded records as synced
  Future<int> markAsSynced(List<int> ids) async {
    if (ids.isEmpty) return 0;
    final db = await database;
    return await db.update(
      tableReadings,
      {'is_synced': 1},
      where: 'id IN (${List.filled(ids.length, '?').join(',')})',
      whereArgs: ids,
    );
  }
}