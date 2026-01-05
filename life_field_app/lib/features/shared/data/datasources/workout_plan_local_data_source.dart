import '../../domain/entities/exercise_catalog_entry.dart';
import '../../domain/entities/workout_models.dart';
import 'workout_local_data_source.dart';

class WorkoutPlanLocalDataSource {
  WorkoutPlanLocalDataSource._();

  static final WorkoutPlanLocalDataSource instance =
      WorkoutPlanLocalDataSource._();

  final WorkoutLocalDataSource _base = WorkoutLocalDataSource.instance;

  Future<List<WorkoutPlan>> fetchPlans() async {
    final db = await _base.database();
    final rows = await db.query(
      'training_plans',
      orderBy: 'is_current DESC, id DESC',
    );
    return rows
        .map(
          (row) => WorkoutPlan(
            id: row['id'] as int,
            name: (row['name'] as String?) ?? '',
            details: (row['details'] as String?) ?? '',
            isCurrent: ((row['is_current'] ?? 0) as int) == 1,
          ),
        )
        .toList();
  }

  Future<WorkoutPlan> addPlan({
    required String name,
    String details = '',
  }) async {
    final db = await _base.database();
    final id = await db.insert(
      'training_plans',
      {'name': name, 'details': details, 'is_current': 0},
    );
    return WorkoutPlan(id: id, name: name, details: details);
  }

  Future<void> deletePlan(int planId) async {
    final db = await _base.database();
    await db.delete('training_plans', where: 'id = ?', whereArgs: [planId]);
  }

  Future<WorkoutPlan?> getPlan(int planId) async {
    final db = await _base.database();
    final rows = await db.query(
      'training_plans',
      where: 'id = ?',
      whereArgs: [planId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final row = rows.first;
    return WorkoutPlan(
      id: row['id'] as int,
      name: (row['name'] as String?) ?? '',
      details: (row['details'] as String?) ?? '',
      isCurrent: ((row['is_current'] ?? 0) as int) == 1,
    );
  }

  Future<List<PlanWorkout>> fetchPlanWorkouts(int planId) async {
    final db = await _base.database();
    final rows = await db.query(
      'plan_workouts',
      where: 'plan_id = ?',
      whereArgs: [planId],
      orderBy: 'id DESC',
    );
    return rows
        .map(
          (row) => PlanWorkout(
            id: row['id'] as int,
            planId: row['plan_id'] as int,
            name: (row['name'] as String?) ?? '',
            details: (row['details'] as String?) ?? '',
          ),
        )
        .toList();
  }

  Future<PlanWorkout> addPlanWorkout({
    required int planId,
    required String name,
    String details = '',
  }) async {
    final db = await _base.database();
    final id = await db.insert(
      'plan_workouts',
      {'plan_id': planId, 'name': name, 'details': details},
    );
    return PlanWorkout(
      id: id,
      planId: planId,
      name: name,
      details: details,
    );
  }

  Future<void> deletePlanWorkout(int workoutId) async {
    final db = await _base.database();
    await db.delete('plan_workouts', where: 'id = ?', whereArgs: [workoutId]);
  }

  Future<void> updatePlanWorkoutDetails({
    required int workoutId,
    required String details,
  }) async {
    final db = await _base.database();
    await db.update(
      'plan_workouts',
      {'details': details},
      where: 'id = ?',
      whereArgs: [workoutId],
    );
  }

  Future<List<PlanWorkoutExercise>> fetchExercises(int workoutId) async {
    final db = await _base.database();
    final rows = await db.query(
      'plan_workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'id DESC',
    );
    return rows
        .map(
          (row) => PlanWorkoutExercise(
            id: row['id'] as int,
            workoutId: row['workout_id'] as int,
            exerciseId: (row['exercise_id'] ?? '').toString(),
            exerciseName: (row['exercise_name'] ?? '').toString(),
            sets: (row['sets'] as int?) ?? 0,
            reps: (row['reps'] as int?) ?? 0,
            notes: (row['notes'] as String?)?.isNotEmpty == true
                ? row['notes'] as String
                : null,
            videoUrl: (row['video_url'] as String?)?.isNotEmpty == true
                ? row['video_url'] as String
                : null,
          ),
        )
        .toList();
  }

  Future<PlanWorkoutExercise> addExercise({
    required int workoutId,
    required ExerciseCatalogEntry exercise,
    required int sets,
    required int reps,
    String? notes,
  }) async {
    final db = await _base.database();
    final id = await db.insert(
      'plan_workout_exercises',
      {
        'workout_id': workoutId,
        'exercise_id': exercise.id,
        'exercise_name': exercise.name,
        'sets': sets,
        'reps': reps,
        'notes': notes ?? '',
        'video_url': exercise.videoUrl ?? '',
      },
    );
    return PlanWorkoutExercise(
      id: id,
      workoutId: workoutId,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      sets: sets,
      reps: reps,
      notes: notes,
      videoUrl: exercise.videoUrl,
    );
  }

  Future<void> deleteExercise(int id) async {
    final db = await _base.database();
    await db.delete(
      'plan_workout_exercises',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> setCurrentPlan(int planId) async {
    final db = await _base.database();
    await db.transaction((txn) async {
      await txn.update('training_plans', {'is_current': 0});
      await txn.update(
        'training_plans',
        {'is_current': 1},
        where: 'id = ?',
        whereArgs: [planId],
      );
    });
  }
}
