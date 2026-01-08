import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/datasources/workout_plan_local_data_source.dart';
import '../domain/entities/workout_models.dart';

class WorkoutExecutionScreen extends StatefulWidget {
  const WorkoutExecutionScreen({
    super.key,
    required this.workoutId,
    required this.workoutName,
  });

  final int workoutId;
  final String workoutName;

  @override
  State<WorkoutExecutionScreen> createState() => _WorkoutExecutionScreenState();
}

class _WorkoutExecutionScreenState extends State<WorkoutExecutionScreen> {
  final WorkoutPlanLocalDataSource _dataSource =
      WorkoutPlanLocalDataSource.instance;
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _timer;
  final List<PlanWorkoutExercise> _exercises = [];
  bool _loading = true;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showStartDialog();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metrics = _buildMetrics();
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workoutName),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: _MetricsGrid(metrics: metrics),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _exercises.isEmpty
                        ? const Center(
                            child: Text('Nessun esercizio disponibile'),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _exercises.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final ex = _exercises[index];
                              return _ExerciseCard(
                                exercise: ex,
                                onSetChanged: (setNumber, weight, reps) {
                                  _updateExerciseSet(
                                    ex.id,
                                    setNumber,
                                    weight,
                                    reps,
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  void _startTimer() {
    if (_started) return;
    _started = true;
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });
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

  WorkoutMetrics _buildMetrics() {
    var totalSets = 0;
    var totalReps = 0;
    var tonnage = 0.0;
    for (final ex in _exercises) {
      final details = ex.setDetails;
      totalSets += details.length;
      for (final set in details) {
        final reps = int.tryParse(set.reps ?? '') ?? 0;
        totalReps += reps;
        final weight = _parseWeight(set.weight);
        tonnage += weight * reps;
      }
    }
    return WorkoutMetrics(
      duration: _stopwatch.elapsed,
      totalSets: totalSets,
      totalReps: totalReps,
      tonnage: tonnage,
    );
  }

  double _parseWeight(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 0;
    final normalized = raw.replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0;
  }

  Future<void> _showStartDialog() async {
    final shouldStart = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Avvia allenamento'),
        content: const Text('Vuoi iniziare l\'allenamento adesso?'),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Annulla'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(true),
                  icon: const Icon(Icons.play_arrow),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  label: const Text('Avvia'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (shouldStart == true) {
      _startTimer();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _updateExerciseSet(
    int exerciseId,
    int setNumber,
    String? weight,
    String? reps,
  ) async {
    final index = _exercises.indexWhere((e) => e.id == exerciseId);
    if (index == -1) return;
    final current = _exercises[index];
    final updatedDetails = current.setDetails.map((set) {
      if (set.setNumber != setNumber) return set;
      return ExerciseSetDetail(
        setNumber: set.setNumber,
        weight: weight ?? set.weight,
        reps: reps ?? set.reps,
      );
    }).toList();
    final updated = current.copyWith(setDetails: updatedDetails);
    setState(() {
      _exercises[index] = updated;
    });
    await _dataSource.updateExerciseSets(
      exerciseId: updated.id,
      setDetails: updated.setDetails,
      notes: updated.notes,
      recoverySeconds: updated.recoverySeconds,
    );
  }
}

class WorkoutMetrics {
  const WorkoutMetrics({
    required this.duration,
    required this.totalSets,
    required this.totalReps,
    required this.tonnage,
  });

  final Duration duration;
  final int totalSets;
  final int totalReps;
  final double tonnage;
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid({required this.metrics});

  final WorkoutMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.decimalPattern();
    return Row(
      children: [
        Expanded(
          child: _MetricTile(
            label: 'Tempo',
            value: _formatDuration(metrics.duration),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: 'Serie',
            value: '${metrics.totalSets}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: 'Ripetizioni',
            value: '${metrics.totalReps}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _MetricTile(
            label: 'Tonnellaggio',
            value: '${formatter.format(metrics.tonnage)} kg',
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    if (hours > 0) {
      final hh = hours.toString().padLeft(2, '0');
      return '$hh:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.35),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelMedium
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onSetChanged,
  });

  final PlanWorkoutExercise exercise;
  final void Function(int setNumber, String? weight, String? reps) onSetChanged;

  @override
  Widget build(BuildContext context) {
    final details = exercise.setDetails.isNotEmpty
        ? exercise.setDetails
        : [const ExerciseSetDetail(setNumber: 1)];
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              exercise.exerciseName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (exercise.notes != null && exercise.notes!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  exercise.notes!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            if (exercise.recoverySeconds != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Recupero: ${_formatRecovery(exercise.recoverySeconds!)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
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
                      'Peso',
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
            const SizedBox(height: 6),
            Column(
              children: details.map((set) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60,
                        child: Center(
                          child: Text('Serie ${set.setNumber}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Center(
                          child: TextFormField(
                            initialValue: set.weight ?? '',
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '-',
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            keyboardType:
                                const TextInputType.numberWithOptions(decimal: true),
                            onChanged: (value) =>
                                onSetChanged(set.setNumber, value, null),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Center(
                          child: TextFormField(
                            initialValue: set.reps ?? '',
                            textAlign: TextAlign.center,
                            decoration: const InputDecoration(
                              hintText: '-',
                              isDense: true,
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) =>
                                onSetChanged(set.setNumber, null, value),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
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
}
