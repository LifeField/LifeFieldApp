import 'package:flutter/material.dart';

import '../data/datasources/workout_plan_local_data_source.dart';
import '../domain/entities/exercise_catalog_entry.dart';
import '../domain/entities/workout_models.dart';
import 'exercise_picker_screen.dart';

class WorkoutPlanExercisesScreen extends StatefulWidget {
  const WorkoutPlanExercisesScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
  });

  final int workoutId;
  final String workoutName;

  @override
  State<WorkoutPlanExercisesScreen> createState() =>
      _WorkoutPlanExercisesScreenState();
}

class _WorkoutPlanExercisesScreenState
    extends State<WorkoutPlanExercisesScreen> {
  final WorkoutPlanLocalDataSource _dataSource =
      WorkoutPlanLocalDataSource.instance;
  final List<PlanWorkoutExercise> _exercises = [];
  bool _modified = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _finish();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workoutName),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _finish,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    itemCount: _exercises.length + 1,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      if (index == _exercises.length) {
                        return _AddExerciseCard(onTap: _showAddExerciseDialog);
                      }
                      final ex = _exercises[index];
                      return Dismissible(
                        key: ValueKey('exercise-${ex.id}'),
                        background: _buildNeutralBackground(context),
                        secondaryBackground: _buildDeleteBackground(context),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (_) => _confirmDelete(context, ex),
                        onDismissed: (_) => _deleteExercise(ex),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.fitness_center_outlined),
                            title: Text(ex.exerciseName),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Serie: ${ex.sets}'),
                                  Text('Ripetizioni: ${ex.reps}'),
                                  if (ex.notes != null &&
                                      ex.notes!.trim().isNotEmpty)
                                    Text(ex.notes!),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _loadExercises() async {
    final items = await _dataSource.fetchExercises(widget.workoutId);
    if (!mounted) return;
    setState(() {
      _exercises
        ..clear()
        ..addAll(items);
      _loading = false;
    });
  }

  Future<void> _showAddExerciseDialog() async {
    final picked = await Navigator.of(context).push<ExerciseCatalogEntry?>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (picked == null || !mounted) return;

    final setsController = TextEditingController();
    final repsController = TextEditingController();
    final notesController = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Configura "${picked.name}"'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: setsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Serie'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: repsController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Ripetizioni'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(labelText: 'Note (opzionale)'),
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
              final sets = int.tryParse(setsController.text.trim());
              final reps = int.tryParse(repsController.text.trim());
              if (sets == null || reps == null || sets <= 0 || reps <= 0) {
                return;
              }
              Navigator.of(context).pop(true);
            },
            child: const Text('Salva'),
          ),
        ],
      ),
    );

    final sets = int.tryParse(setsController.text.trim());
    final reps = int.tryParse(repsController.text.trim());
    if (ok == true && sets != null && reps != null && mounted) {
      final created = await _dataSource.addExercise(
        workoutId: widget.workoutId,
        exercise: picked,
        sets: sets,
        reps: reps,
        notes: notesController.text.trim(),
      );
      setState(() {
        _modified = true;
        _exercises.insert(0, created);
      });
    }
  }

  Future<bool> _confirmDelete(
      BuildContext context, PlanWorkoutExercise ex) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina esercizio'),
        content: Text('Vuoi eliminare "${ex.exerciseName}"?'),
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

  Future<void> _deleteExercise(PlanWorkoutExercise ex) async {
    await _dataSource.deleteExercise(ex.id);
    if (!mounted) return;
    setState(() {
      _modified = true;
      _exercises.removeWhere((e) => e.id == ex.id);
    });
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

  void _finish() {
    if (!mounted) return;
    Navigator.of(context).pop(_modified);
  }
}

class _AddExerciseCard extends StatelessWidget {
  const _AddExerciseCard({required this.onTap});

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
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
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
                    'Aggiungi esercizio',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Inserisci un esercizio nel workout',
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
