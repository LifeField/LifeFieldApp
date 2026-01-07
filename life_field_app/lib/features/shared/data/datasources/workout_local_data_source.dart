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
      version: 6,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
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
        if (oldVersion < 4) {
          await _createExerciseTable(db);
        }
        if (oldVersion < 5) {
          await db.execute(
            'ALTER TABLE plan_workout_exercises ADD COLUMN sets_payload TEXT NOT NULL DEFAULT ""',
          );
        }
        if (oldVersion < 6) {
          await db.execute(
            'ALTER TABLE plan_workout_exercises ADD COLUMN recovery_seconds INTEGER',
          );
        }
      },
    );
    await _ensureRecoveryColumn(_db!);
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
    await _createExerciseTable(db);
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

  Future<void> _createExerciseTable(Database db) async {
    await db.execute('''
        CREATE TABLE IF NOT EXISTS plan_workout_exercises(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          workout_id INTEGER NOT NULL,
          exercise_id TEXT NOT NULL,
          exercise_name TEXT NOT NULL,
          sets INTEGER NOT NULL,
          reps INTEGER NOT NULL,
          notes TEXT,
          video_url TEXT,
          sets_payload TEXT NOT NULL DEFAULT '',
          recovery_seconds INTEGER,
          FOREIGN KEY(workout_id) REFERENCES plan_workouts(id) ON DELETE CASCADE
        );
        ''');
  }

  Future<void> _ensureRecoveryColumn(Database db) async {
    try {
      final rows = await db.rawQuery('PRAGMA table_info(plan_workout_exercises)');
      final hasColumn = rows.any((row) => row['name'] == 'recovery_seconds');
      if (!hasColumn) {
        await db.execute(
          'ALTER TABLE plan_workout_exercises ADD COLUMN recovery_seconds INTEGER',
        );
      }
    } catch (_) {
      // Best effort: ignore if table is missing during first init.
    }
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
