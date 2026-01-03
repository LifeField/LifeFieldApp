import 'package:flutter/material.dart';

import '../data/datasources/workout_local_data_source.dart';
import '../domain/entities/workout_models.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final WorkoutLocalDataSource _dataSource = WorkoutLocalDataSource.instance;
  final List<WorkoutEntry> _workouts = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Allenamenti'),
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
                  onLongPress: () => _removeWorkout(workout.id),
                  onTap: () {
                    // TODO: dettaglio allenamento locale
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadWorkouts() async {
    final items = await _dataSource.fetchWorkouts();
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
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuovo allenamento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(
                  labelText: 'Dettagli (opzionale)',
                ),
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
                if (nameController.text.trim().isEmpty) {
                  return;
                }
                Navigator.of(context).pop(true);
              },
              child: const Text('Salva'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newWorkout = await _dataSource.addWorkout(
        name: nameController.text.trim(),
        details: detailsController.text.trim(),
      );
      setState(() {
        _workouts.insert(0, newWorkout);
      });
    }
  }

  Future<void> _removeWorkout(int id) async {
    await _dataSource.deleteWorkout(id);
    await _loadWorkouts();
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
                    'Nuovo allenamento',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Crea una scheda allenamento',
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
