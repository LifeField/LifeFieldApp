import 'workout_local_data_source.dart';
import '../../domain/entities/workout_models.dart';

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
