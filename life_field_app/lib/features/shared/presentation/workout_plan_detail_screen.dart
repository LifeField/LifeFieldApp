import 'dart:convert';
import 'package:flutter/material.dart';

import '../data/datasources/workout_plan_local_data_source.dart';
import '../domain/entities/workout_models.dart';
import 'workout_plan_exercises_screen.dart';

class WorkoutPlanDetailScreen extends StatefulWidget {
  const WorkoutPlanDetailScreen({
    super.key,
    required this.planId,
    this.planName,
  });

  final int planId;
  final String? planName;

  @override
  State<WorkoutPlanDetailScreen> createState() => _WorkoutPlanDetailScreenState();
}

class _WorkoutPlanDetailScreenState extends State<WorkoutPlanDetailScreen> {
  final WorkoutPlanLocalDataSource _dataSource =
      WorkoutPlanLocalDataSource.instance;
  WorkoutPlan? _plan;
  final List<PlanWorkout> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadPlan();
    _loadWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    final title = _plan?.name ?? widget.planName ?? 'Scheda';
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView.separated(
            itemCount: _workouts.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == _workouts.length) {
                return _AddWorkoutCard(onTap: _showAddWorkoutDialog);
              }
              final workout = _workouts[index];
              return Dismissible(
                key: ValueKey('plan-workout-${workout.id}'),
                background: _buildNeutralBackground(context),
                secondaryBackground: _buildDeleteBackground(context),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    return await _confirmDelete(context, workout);
                  }
                  return false;
                },
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await _removeWorkout(workout.id);
                  }
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                child: ListTile(
                  leading: const Icon(Icons.checklist_rtl_outlined),
                  title: Text(workout.name),
                  subtitle: _buildWorkoutSubtitle(workout),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => _openExercises(workout),
                ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadPlan() async {
    final plan = await _dataSource.getPlan(widget.planId);
    if (!mounted) return;
    setState(() {
      _plan = plan;
    });
  }

  Future<void> _loadWorkouts() async {
    final items = await _dataSource.fetchPlanWorkouts(widget.planId);
    if (!mounted) return;
    setState(() {
      _workouts
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> _showAddWorkoutDialog() async {
    final nameController = TextEditingController();
    final detailsController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuovo workout'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: detailsController,
              decoration: const InputDecoration(labelText: 'Dettagli'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.of(context).pop(true);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    if (result == true) {
      await _dataSource.addPlanWorkout(
        planId: widget.planId,
        name: nameController.text.trim(),
        details: detailsController.text.trim(),
      );
      await _loadWorkouts();
    }
  }

  Future<void> _removeWorkout(int id) async {
    await _dataSource.deletePlanWorkout(id);
    await _loadWorkouts();
  }

  Future<void> _openExercises(PlanWorkout workout) async {
    final result = await Navigator.of(context).push<String?>(
      MaterialPageRoute(
        builder: (_) => WorkoutPlanExercisesScreen(
          workoutId: workout.id,
          workoutName: workout.name,
          initialDetails: workout.details,
        ),
      ),
    );
    if (result != null) {
      await _dataSource.updatePlanWorkoutDetails(
        workoutId: workout.id,
        details: result,
      );
      await _loadWorkouts();
    }
  }

  Widget? _buildWorkoutSubtitle(PlanWorkout workout) {
    if (workout.details.isEmpty) return null;
    try {
      final decoded = jsonDecode(workout.details);
      if (decoded is List) {
        final parts = decoded.whereType<Map>().map((e) {
          final name = (e['name'] ?? '').toString();
          final sets = e['sets']?.toString();
          final reps = e['reps']?.toString();
          if (name.isEmpty || sets == null || reps == null) return '';
          return '$sets x $reps reps $name';
        }).where((e) => e.isNotEmpty).toList();
        if (parts.isNotEmpty) {
          return Text(parts.join('\n'));
        }
      }
    } catch (_) {
      // ignore
    }
    return Text(workout.details);
  }

  Future<bool> _confirmDelete(BuildContext context, PlanWorkout workout) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina workout'),
        content: Text('Vuoi eliminare "${workout.name}" dalla scheda?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annulla'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildDeleteBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          const Text('Elimina'),
          const SizedBox(width: 8),
          Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
        ],
      ),
    );
  }

  Widget _buildNeutralBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _AddWorkoutCard extends StatelessWidget {
  const _AddWorkoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                ),
                child: Icon(
                  Icons.add,
                  color: Theme.of(context).colorScheme.primary,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aggiungi workout',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inserisci un nuovo workout nella scheda',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
