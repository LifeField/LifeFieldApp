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

class PlanWorkoutExercise {
  const PlanWorkoutExercise({
    required this.id,
    required this.workoutId,
    required this.exerciseId,
    required this.exerciseName,
    required this.sets,
    required this.reps,
    this.notes,
    this.videoUrl,
    this.setDetails = const [],
    this.recoverySeconds,
  });

  final int id;
  final int workoutId;
  final String exerciseId;
  final String exerciseName;
  final int sets;
  final int reps;
  final String? notes;
  final String? videoUrl;
  final List<ExerciseSetDetail> setDetails;
  final int? recoverySeconds;

  PlanWorkoutExercise copyWith({
    int? sets,
    int? reps,
    String? notes,
    String? videoUrl,
    List<ExerciseSetDetail>? setDetails,
    int? recoverySeconds,
    bool clearRecovery = false,
  }) {
    return PlanWorkoutExercise(
      id: id,
      workoutId: workoutId,
      exerciseId: exerciseId,
      exerciseName: exerciseName,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
      setDetails: setDetails ?? this.setDetails,
      recoverySeconds:
          clearRecovery ? null : (recoverySeconds ?? this.recoverySeconds),
    );
  }
}

class ExerciseSetDetail {
  const ExerciseSetDetail({
    required this.setNumber,
    this.weight,
    this.reps,
  });

  final int setNumber;
  final String? weight;
  final String? reps;
}
