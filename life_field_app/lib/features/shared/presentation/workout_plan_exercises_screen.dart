import 'package:flutter/cupertino.dart';
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
        await _saveAndFinish();
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.workoutName),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: _saveAndFinish,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveAndFinish,
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: _loading
                ? const Center(child: CircularProgressIndicator())
              : ReorderableListView.builder(
                    itemCount: _exercises.length + 1,
                    buildDefaultDragHandles: false,
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    onReorder: (oldIndex, newIndex) async {
                      if (oldIndex >= _exercises.length ||
                          newIndex > _exercises.length) {
                        return;
                      }
                      if (newIndex > oldIndex) newIndex -= 1;
                      setState(() {
                        final item = _exercises.removeAt(oldIndex);
                        _exercises.insert(newIndex, item);
                        _modified = true;
                      });
                      await _dataSource.updateExerciseOrder(
                        workoutId: widget.workoutId,
                        orderedExerciseIds:
                            _exercises.map((e) => e.id).toList(),
                      );
                    },
                    itemBuilder: (context, index) {
                      if (index == _exercises.length) {
                        return Padding(
                          key: const ValueKey('add-exercise'),
                          padding: const EdgeInsets.only(top: 12),
                          child: _AddExerciseCard(onTap: _showAddExerciseDialog),
                        );
                      }
                      final ex = _exercises[index];
                      final card = Dismissible(
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
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.fitness_center_outlined),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        ex.exerciseName,
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Listener(
                                        onPointerDown: (_) =>
                                            FocusScope.of(context).unfocus(),
                                        child: const Icon(
                                          Icons.drag_indicator_outlined,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  initialValue: ex.notes ?? '',
                                  decoration: const InputDecoration(
                                    hintText: 'Note esercizio',
                                    isDense: true,
                                    border: InputBorder.none,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                  ),
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                  onChanged: (value) {
                                    setState(() {
                                      _modified = true;
                                      _exercises[index] =
                                          ex.copyWith(notes: value.trim());
                                    });
                                  },
                                ),
                                _ExerciseSetsTable(
                                  exercise: ex,
                                  onChanged: (updated) {
                                    setState(() {
                                      _modified = true;
                                      _exercises[index] = updated;
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      return Padding(
                        key: ValueKey('exercise-card-${ex.id}'),
                        padding: const EdgeInsets.only(bottom: 12),
                        child: card,
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
    final created = await _dataSource.addExercise(
      workoutId: widget.workoutId,
      exercise: picked,
      setDetails: const [ExerciseSetDetail(setNumber: 1)],
    );
    setState(() {
      _modified = true;
      _exercises.add(created);
    });
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

  Future<void> _saveAndFinish() async {
    if (!mounted) return;
    for (final ex in _exercises) {
      await _dataSource.updateExerciseSets(
        exerciseId: ex.id,
        setDetails: ex.setDetails.isNotEmpty
            ? ex.setDetails
            : [const ExerciseSetDetail(setNumber: 1)],
        notes: ex.notes,
        recoverySeconds: ex.recoverySeconds,
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop(_modified);
  }
}

class _ExerciseSetsTable extends StatelessWidget {
  const _ExerciseSetsTable({
    required this.exercise,
    required this.onChanged,
  });

  final PlanWorkoutExercise exercise;
  final ValueChanged<PlanWorkoutExercise> onChanged;

  @override
  Widget build(BuildContext context) {
    final rows = exercise.setDetails.isNotEmpty
        ? exercise.setDetails
        : [const ExerciseSetDetail(setNumber: 1)];
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          const SizedBox(height: 12),
          Row(
            children: [
              SizedBox(
                width: 60,
                child: Center(
                  child: Text(
                    'Serie',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: Text(
                    'Peso (kg)',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: Text(
                    'Ripetizioni',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            children: rows.map((set) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Center(
                        child: Text(
                          '${set.setNumber}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('weight-${exercise.id}-${set.setNumber}'),
                        initialValue: set.weight ?? '',
                        decoration: const InputDecoration(
                          hintText: '—',
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          _updateSet(set.setNumber, value, null);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        key: ValueKey('reps-${exercise.id}-${set.setNumber}'),
                        initialValue: set.reps ?? '',
                        decoration: const InputDecoration(
                          hintText: '—',
                          isDense: true,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                        ),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        onChanged: (value) {
                          _updateSet(set.setNumber, null, value);
                        },
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                final next = rows.length + 1;
                final updated = List<ExerciseSetDetail>.from(rows)
                  ..add(ExerciseSetDetail(setNumber: next));
                _emitUpdated(updated);
              },
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi serie'),
            ),
          ),
          const SizedBox(height: 8),
          exercise.recoverySeconds == null
              ? SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showRecoveryPicker(context),
                    icon: const Icon(Icons.timer_outlined),
                    label: const Text('Aggiungi recupero'),
                  ),
                )
              : InkWell(
                  onTap: () => _showRecoveryPicker(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceVariant
                          .withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.timer_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Recupero: ${_formatRecovery(exercise.recoverySeconds!)}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Future<void> _showRecoveryPicker(BuildContext context) async {
    Duration selected = Duration(
      seconds: exercise.recoverySeconds ?? 60,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seleziona recupero',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 180,
                  child: CupertinoTimerPicker(
                    mode: CupertinoTimerPickerMode.ms,
                    initialTimerDuration: selected,
                    onTimerDurationChanged: (value) {
                      selected = value;
                    },
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          if (selected < const Duration(seconds: 5)) {
                            selected = const Duration(seconds: 5);
                          }
                          onChanged(
                            exercise.copyWith(
                              recoverySeconds:
                                  selected.inSeconds.clamp(5, 600),
                            ),
                          );
                          Navigator.of(context).pop();
                        },
                        child: const Text('Conferma'),
                      ),
                      TextButton(
                        onPressed: () {
                          onChanged(exercise.copyWith(clearRecovery: true));
                          Navigator.of(context).pop();
                        },
                        child: const Text('Disattiva recupero'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRecovery(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    if (minutes <= 0) return '${secs}s';
    final padded = secs.toString().padLeft(2, '0');
    return '$minutes:$padded';
  }

  void _updateSet(int setNumber, String? weight, String? reps) {
    final updated = exercise.setDetails.isNotEmpty
        ? List<ExerciseSetDetail>.from(exercise.setDetails)
        : [const ExerciseSetDetail(setNumber: 1)];
    final index = updated.indexWhere((s) => s.setNumber == setNumber);
    if (index == -1) return;
    final current = updated[index];
    updated[index] = ExerciseSetDetail(
      setNumber: current.setNumber,
      weight: weight ?? current.weight,
      reps: reps ?? current.reps,
    );
    _emitUpdated(updated);
  }

  void _emitUpdated(List<ExerciseSetDetail> updated) {
    final repsValue =
        updated.isNotEmpty ? int.tryParse(updated.first.reps ?? '') ?? 0 : 0;
    onChanged(
      exercise.copyWith(
        setDetails: updated,
        sets: updated.length,
        reps: repsValue,
      ),
    );
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
