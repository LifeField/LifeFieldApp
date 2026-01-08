class WorkoutSession {
  const WorkoutSession({
    required this.workoutId,
    required this.workoutName,
    required this.startedAt,
  });

  final int workoutId;
  final String workoutName;
  final DateTime startedAt;
}
