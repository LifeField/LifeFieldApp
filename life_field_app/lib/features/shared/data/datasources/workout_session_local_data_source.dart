import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/workout_session.dart';

class WorkoutSessionLocalDataSource {
  WorkoutSessionLocalDataSource._();

  static final WorkoutSessionLocalDataSource instance =
      WorkoutSessionLocalDataSource._();

  static const _activeSessionKey = 'active_workout_session';

  Future<WorkoutSession?> fetchActiveSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeSessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      final workoutId = int.tryParse('${decoded['workoutId'] ?? ''}');
      final workoutName = (decoded['workoutName'] ?? '').toString();
      final startedAtMs =
          int.tryParse('${decoded['startedAtMs'] ?? ''}') ?? 0;
      if (workoutId == null || workoutName.isEmpty || startedAtMs == 0) {
        return null;
      }
      return WorkoutSession(
        workoutId: workoutId,
        workoutName: workoutName,
        startedAt: DateTime.fromMillisecondsSinceEpoch(startedAtMs),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> startSession({
    required int workoutId,
    required String workoutName,
    required DateTime startedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(
      {
        'workoutId': workoutId,
        'workoutName': workoutName,
        'startedAtMs': startedAt.millisecondsSinceEpoch,
      },
    );
    await prefs.setString(_activeSessionKey, payload);
  }

  Future<void> endSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeSessionKey);
  }
}
