import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class WorkoutRecoveryLocalDataSource {
  WorkoutRecoveryLocalDataSource._();

  static final WorkoutRecoveryLocalDataSource instance =
      WorkoutRecoveryLocalDataSource._();

  String _key(int workoutId) => 'workout_recovery_$workoutId';

  Future<Map<int, DateTime>> fetchRecoveries(int workoutId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key(workoutId));
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      final now = DateTime.now();
      final entries = <int, DateTime>{};
      decoded.forEach((key, value) {
        final id = int.tryParse('$key');
        final ms = int.tryParse('$value') ?? 0;
        if (id == null || ms <= 0) return;
        final endsAt = DateTime.fromMillisecondsSinceEpoch(ms);
        if (endsAt.isAfter(now)) {
          entries[id] = endsAt;
        }
      });
      return entries;
    } catch (_) {
      return {};
    }
  }

  Future<void> setRecovery({
    required int workoutId,
    required int exerciseId,
    required DateTime endsAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchRecoveries(workoutId);
    existing[exerciseId] = endsAt;
    final payload = jsonEncode(
      existing.map(
        (key, value) => MapEntry(
          key.toString(),
          value.millisecondsSinceEpoch,
        ),
      ),
    );
    await prefs.setString(_key(workoutId), payload);
  }

  Future<void> clearRecovery({
    required int workoutId,
    required int exerciseId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await fetchRecoveries(workoutId);
    existing.remove(exerciseId);
    final payload = jsonEncode(
      existing.map(
        (key, value) => MapEntry(
          key.toString(),
          value.millisecondsSinceEpoch,
        ),
      ),
    );
    await prefs.setString(_key(workoutId), payload);
  }
}
