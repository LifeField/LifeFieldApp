import 'dart:convert';
import 'package:flutter/material.dart';
import '../domain/entities/exercise_catalog_entry.dart';
import 'exercise_picker_screen.dart';
import '../data/datasources/workout_plan_local_data_source.dart';

class WorkoutPlanExercisesScreen extends StatefulWidget {
  const WorkoutPlanExercisesScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
    required this.initialDetails,
  });

  final int workoutId;
  final String workoutName;
  final String initialDetails;

  @override
  State<WorkoutPlanExercisesScreen> createState() => _WorkoutPlanExercisesScreenState();
}

class _WorkoutPlanExercisesScreenState extends State<WorkoutPlanExercisesScreen> {
  final WorkoutPlanLocalDataSource _dataSource = WorkoutPlanLocalDataSource.instance;
  final List<_ExerciseEntry> _exercises = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        await _saveAndPop();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workoutName),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveAndPop,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.separated(
              itemCount: _exercises.length + 1,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                if (index == _exercises.length) {
                  return _AddExerciseCard(onTap: _showAddExerciseDialog);
                }
                final ex = _exercises[index];
                return Dismissible(
                  key: ValueKey('exercise-${ex.name}-$index'),
                  background: _buildDeleteBackground(context),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (direction) => _confirmDelete(context, ex),
                  onDismissed: (_) => setState(() => _exercises.removeAt(index)),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.fitness_center_outlined),
                      title: Text(ex.name),
                      subtitle: Text(
                        '${ex.sets}x${ex.reps}${ex.notes.isNotEmpty ? ' ${ex.notes}' : ''}',
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

  Future<void> _showAddExerciseDialog() async {
    final picked = await Navigator.of(context).push<ExerciseCatalogEntry?>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (picked == null) return;

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

    if (ok == true && sets != null && reps != null) {
      setState(() {
        _exercises.add(
          _ExerciseEntry(
            name: picked.name,
            notes: notesController.text.trim(),
            sets: sets,
            reps: reps,
          ),
        );
      });
    }
  }

  Future<bool> _confirmDelete(BuildContext context, _ExerciseEntry ex) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina esercizio'),
        content: Text('Vuoi eliminare "${ex.name}"?'),
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

  Future<void> _loadInitial() async {
    if (widget.initialDetails.isEmpty) return;
    try {
      final decoded = jsonDecode(widget.initialDetails);
      if (decoded is List) {
        for (final item in decoded.whereType<Map>()) {
          final name = (item['name'] ?? '').toString();
          if (name.isEmpty) continue;
          final sets = int.tryParse(item['sets']?.toString() ?? '') ?? 0;
          final reps = int.tryParse(item['reps']?.toString() ?? '') ?? 0;
          final notes = (item['notes'] ?? '').toString();
          _exercises.add(
            _ExerciseEntry(name: name, notes: notes, sets: sets, reps: reps),
          );
        }
        setState(() {});
      }
    } catch (_) {
      // ignore malformed
    }
  }

  Future<void> _saveAndPop() async {
    final serialized = jsonEncode(
      _exercises
          .map((e) => {
                'name': e.name,
                'sets': e.sets,
                'reps': e.reps,
                'notes': e.notes,
              })
          .toList(),
    );
    await _dataSource.updatePlanWorkoutDetails(
      workoutId: widget.workoutId,
      details: serialized,
    );
    if (!mounted) return;
    Navigator.of(context).pop(serialized);
  }
}

class _ExerciseEntry {
  _ExerciseEntry({
    required this.name,
    this.notes = '',
    required this.sets,
    required this.reps,
  });

  final String name;
  final String notes;
  final int sets;
  final int reps;
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
