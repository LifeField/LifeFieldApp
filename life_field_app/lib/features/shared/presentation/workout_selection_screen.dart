import 'package:flutter/material.dart';

import '../domain/entities/workout_models.dart';

class WorkoutSelectionScreen extends StatelessWidget {
  const WorkoutSelectionScreen({
    super.key,
    required this.planName,
    required this.workouts,
  });

  final String planName;
  final List<PlanWorkout> workouts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Seleziona workout'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: workouts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final workout = workouts[index];
              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: const Icon(Icons.fitness_center_outlined),
                  title: Text(workout.name),
                  subtitle:
                      workout.details.isNotEmpty ? Text(workout.details) : null,
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.of(context).pop(workout),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
