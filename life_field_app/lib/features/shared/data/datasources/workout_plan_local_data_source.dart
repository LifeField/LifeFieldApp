import 'dart:convert';

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

  List<ExerciseSetDetail> _decodeSets(String payload, int fallbackCount) {
    if (payload.isEmpty) {
      if (fallbackCount <= 0) return [];
      return List.generate(
        fallbackCount,
        (index) => ExerciseSetDetail(setNumber: index + 1),
      );
    }
    try {
      final raw = jsonDecode(payload);
      if (raw is List) {
        return raw.whereType<Map>().map((item) {
          final setNumber = int.tryParse('${item['set'] ?? item['setNumber'] ?? ''}') ?? 0;
          final weight = (item['weight'] ?? '').toString();
          final reps = (item['reps'] ?? '').toString();
          return ExerciseSetDetail(
            setNumber: setNumber > 0 ? setNumber : 0,
            weight: weight.isNotEmpty ? weight : null,
            reps: reps.isNotEmpty ? reps : null,
          );
        }).where((e) => e.setNumber > 0).toList();
      }
    } catch (_) {
      // ignore malformed payloads
    }
    return [];
  }

  String _encodeSets(List<ExerciseSetDetail> details) {
    return jsonEncode(details
        .map(
          (e) => {
            'set': e.setNumber,
            'weight': e.weight ?? '',
            'reps': e.reps ?? '',
          },
        )
        .toList());
  }

  Future<List<PlanWorkoutExercise>> fetchExercises(int workoutId) async {
    final db = await _base.database();
    final rows = await db.query(
      'plan_workout_exercises',
      where: 'workout_id = ?',
      whereArgs: [workoutId],
      orderBy: 'order_index ASC, id ASC',
    );
    return rows.map((row) {
      final sets = (row['sets'] as int?) ?? 0;
      final decoded = _decodeSets(
        (row['sets_payload'] ?? '').toString(),
        sets,
      );
      final safeDetails = decoded.isNotEmpty
          ? decoded
          : List.generate(
              sets > 0 ? sets : 1,
              (index) => ExerciseSetDetail(setNumber: index + 1),
            );
      return PlanWorkoutExercise(
        id: row['id'] as int,
        workoutId: row['workout_id'] as int,
        exerciseId: (row['exercise_id'] ?? '').toString(),
        exerciseName: (row['exercise_name'] ?? '').toString(),
        sets: sets,
        reps: (row['reps'] as int?) ?? 0,
        notes: (row['notes'] as String?)?.isNotEmpty == true
            ? row['notes'] as String
            : null,
        videoUrl: (row['video_url'] as String?)?.isNotEmpty == true
            ? row['video_url'] as String
            : null,
        setDetails: safeDetails,
        recoverySeconds: row['recovery_seconds'] as int?,
      );
    }).toList();
  }

  Future<PlanWorkoutExercise> addExercise({
    required int workoutId,
    required ExerciseCatalogEntry exercise,
    List<ExerciseSetDetail>? setDetails,
    String? notes,
    int? recoverySeconds,
  }) async {
    final db = await _base.database();
    final details = setDetails ??
        [
          const ExerciseSetDetail(setNumber: 1),
        ];
    final sets = details.length;
    final firstReps = details.first.reps;
    final reps = int.tryParse(firstReps ?? '') ?? 0;
    final values = {
      'workout_id': workoutId,
      'exercise_id': exercise.id,
      'exercise_name': exercise.name,
      'sets': sets,
      'reps': reps,
      'notes': notes ?? '',
      'video_url': exercise.videoUrl ?? '',
      'sets_payload': _encodeSets(details),
      'recovery_seconds': recoverySeconds,
      'order_index': await _nextExerciseOrder(workoutId),
    };
    int id;
    try {
      id = await db.insert('plan_workout_exercises', values);
    } catch (e) {
      final fallback = Map<String, Object?>.from(values)
        ..remove('recovery_seconds');
      id = await db.insert('plan_workout_exercises', fallback);
    }
    return PlanWorkoutExercise(
      id: id,
      workoutId: workoutId,
      exerciseId: exercise.id,
      exerciseName: exercise.name,
      sets: sets,
      reps: reps,
      notes: notes,
      videoUrl: exercise.videoUrl,
      setDetails: details,
      recoverySeconds: recoverySeconds,
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

  Future<void> updateExerciseSets({
    required int exerciseId,
    required List<ExerciseSetDetail> setDetails,
    String? notes,
    int? recoverySeconds,
  }) async {
    final db = await _base.database();
    final normalized = List<ExerciseSetDetail>.generate(
      setDetails.isNotEmpty ? setDetails.length : 1,
      (index) {
        final source = setDetails.isNotEmpty && setDetails.length > index
            ? setDetails[index]
            : const ExerciseSetDetail(setNumber: 1);
        return ExerciseSetDetail(
          setNumber: index + 1,
          weight: source.weight,
          reps: source.reps,
        );
      },
    );
    final sets = normalized.length;
    final reps = normalized.isNotEmpty
        ? int.tryParse(normalized.first.reps ?? '') ?? 0
        : 0;
    final values = {
      'sets': sets,
      'reps': reps,
      'sets_payload': _encodeSets(normalized),
      'notes': notes ?? '',
      'recovery_seconds': recoverySeconds,
    };
    try {
      await db.update(
        'plan_workout_exercises',
        values,
        where: 'id = ?',
        whereArgs: [exerciseId],
      );
    } catch (e) {
      final fallback = Map<String, Object?>.from(values)
        ..remove('recovery_seconds');
      await db.update(
        'plan_workout_exercises',
        fallback,
        where: 'id = ?',
        whereArgs: [exerciseId],
      );
    }
  }

  Future<void> updateExerciseOrder({
    required int workoutId,
    required List<int> orderedExerciseIds,
  }) async {
    final db = await _base.database();
    await db.transaction((txn) async {
      for (var i = 0; i < orderedExerciseIds.length; i += 1) {
        await txn.update(
          'plan_workout_exercises',
          {'order_index': i + 1},
          where: 'id = ? AND workout_id = ?',
          whereArgs: [orderedExerciseIds[i], workoutId],
        );
      }
    });
  }

  Future<int> _nextExerciseOrder(int workoutId) async {
    final db = await _base.database();
    final rows = await db.rawQuery(
      'SELECT MAX(order_index) as max_order FROM plan_workout_exercises WHERE workout_id = ?',
      [workoutId],
    );
    final maxOrder = rows.isNotEmpty ? rows.first['max_order'] as int? : null;
    return (maxOrder ?? 0) + 1;
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
