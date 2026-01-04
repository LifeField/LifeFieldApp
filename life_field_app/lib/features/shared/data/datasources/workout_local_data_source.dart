import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/workout_models.dart';

class WorkoutLocalDataSource {
  WorkoutLocalDataSource._();

  static final WorkoutLocalDataSource instance = WorkoutLocalDataSource._();

  Database? _db;

  Future<Database> database() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'life_field_workouts.db');
    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await _createTables(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _createPlanTables(db);
        }
        if (oldVersion < 3) {
          await db.execute(
            'ALTER TABLE training_plans ADD COLUMN is_current INTEGER NOT NULL DEFAULT 0',
          );
        }
      },
    );
    return _db!;
  }

  Future<void> _createTables(Database db) async {
    await db.execute('''
        CREATE TABLE workouts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          details TEXT NOT NULL
        );
        ''');
    await _createPlanTables(db);
  }

  Future<void> _createPlanTables(Database db) async {
    await db.execute('''
        CREATE TABLE IF NOT EXISTS training_plans(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          details TEXT NOT NULL,
          is_current INTEGER NOT NULL DEFAULT 0
        );
        ''');
    await db.execute('''
        CREATE TABLE IF NOT EXISTS plan_workouts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          plan_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          details TEXT NOT NULL,
          FOREIGN KEY(plan_id) REFERENCES training_plans(id) ON DELETE CASCADE
        );
        ''');
  }

  Future<List<WorkoutEntry>> fetchWorkouts() async {
    final db = await database();
    final rows = await db.query('workouts', orderBy: 'id DESC');
    return rows
        .map(
          (row) => WorkoutEntry(
            id: row['id'] as int,
            name: (row['name'] as String?) ?? '',
            details: (row['details'] as String?) ?? '',
          ),
        )
        .toList();
  }

  Future<WorkoutEntry> addWorkout({
    required String name,
    String details = '',
  }) async {
    final db = await database();
    final id = await db.insert(
      'workouts',
      {
        'name': name,
        'details': details,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return WorkoutEntry(id: id, name: name, details: details);
  }

  Future<void> deleteWorkout(int id) async {
    final db = await database();
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }
}
