import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/workout_models.dart';

class WorkoutLocalDataSource {
  WorkoutLocalDataSource._();

  static final WorkoutLocalDataSource instance = WorkoutLocalDataSource._();

  Database? _db;

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'life_field_workouts.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE workouts(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          details TEXT NOT NULL
        );
        ''');
      },
    );
    return _db!;
  }

  Future<List<WorkoutEntry>> fetchWorkouts() async {
    final db = await _database();
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
    final db = await _database();
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
    final db = await _database();
    await db.delete('workouts', where: 'id = ?', whereArgs: [id]);
  }
}
