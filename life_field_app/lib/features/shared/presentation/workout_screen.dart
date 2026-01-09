import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../data/datasources/workout_plan_local_data_source.dart';
import '../domain/entities/workout_models.dart';
import 'workout_plan_detail_screen.dart';
import '../../../app/router/route_paths.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final WorkoutPlanLocalDataSource _dataSource =
      WorkoutPlanLocalDataSource.instance;
  final List<WorkoutPlan> _plans = [];

  @override
  void initState() {
    super.initState();
    _loadPlans();
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
            itemCount: _plans.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == _plans.length) {
                return _AddPlanCard(onTap: _showAddPlanDialog);
              }
              final plan = _plans[index];
              return Dismissible(
                key: ValueKey('plan-${plan.id}'),
                background: _buildCurrentBackground(context),
                secondaryBackground: _buildDeleteBackground(context),
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    await _dataSource.setCurrentPlan(plan.id);
                    await _loadPlans();
                    return false;
                  }
                  return await _confirmDelete(context, plan);
                },
                onDismissed: (direction) async {
                  if (direction == DismissDirection.endToStart) {
                    await _removePlan(plan.id);
                  }
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        const Icon(Icons.folder_special_outlined),
                        if (plan.isCurrent)
                          Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    title: Text(plan.name),
                    subtitle:
                        plan.details.isNotEmpty ? Text(plan.details) : null,
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => _openPlan(plan),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _loadPlans() async {
    final items = await _dataSource.fetchPlans();
    setState(() {
      _plans
        ..clear()
        ..addAll(items);
    });
  }

  Future<void> _showAddPlanDialog() async {
    final nameController = TextEditingController();
    final detailsController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nuova scheda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nome scheda',
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
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
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
      final newPlan = await _dataSource.addPlan(
        name: nameController.text.trim(),
        details: detailsController.text.trim(),
      );
      await _dataSource.setCurrentPlan(newPlan.id);
      await _loadPlans();
    }
  }

  Future<void> _removePlan(int id) async {
    await _dataSource.deletePlan(id);
    await _loadPlans();
  }

  void _openPlan(WorkoutPlan plan) {
    context.pushNamed(
      RoutePaths.workoutPlanDetailName,
      pathParameters: {'planId': '${plan.id}'},
      extra: plan.name,
    );
  }

  Future<bool> _confirmDelete(BuildContext context, WorkoutPlan plan) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Elimina scheda'),
        content: Text('Sei sicuro di voler eliminare la scheda "${plan.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Annulla'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Widget _buildCurrentBackground(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Imposta come corrente'),
        ],
      ),
    );
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
}

class _AddPlanCard extends StatelessWidget {
  const _AddPlanCard({required this.onTap});

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
                    'Nuova scheda',
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
