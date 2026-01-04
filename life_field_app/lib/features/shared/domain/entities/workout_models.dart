class WorkoutEntry {
  const WorkoutEntry({
    required this.id,
    required this.name,
    required this.details,
  });

  final int id;
  final String name;
  final String details;
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.id,
    required this.name,
    required this.details,
    this.isCurrent = false,
  });

  final int id;
  final String name;
  final String details;
  final bool isCurrent;
}

class PlanWorkout {
  const PlanWorkout({
    required this.id,
    required this.planId,
    required this.name,
    required this.details,
  });

  final int id;
  final int planId;
  final String name;
  final String details;
}
