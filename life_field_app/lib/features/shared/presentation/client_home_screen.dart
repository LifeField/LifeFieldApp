import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

import '../../../app/localization/app_localizations.dart';
import '../../../app/router/route_paths.dart';
import '../data/datasources/meal_local_data_source.dart';
import '../data/datasources/workout_plan_local_data_source.dart';
import '../domain/entities/meal_models.dart';
import '../domain/entities/workout_models.dart';
import 'meal_detail_screen.dart';
import 'workout_selection_screen.dart';
import '../../profile/presentation/profile_screen.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedTabIndex = 1;
  final MealLocalDataSource _mealDataSource = MealLocalDataSource.instance;
  final WorkoutPlanLocalDataSource _planDataSource =
      WorkoutPlanLocalDataSource.instance;
  final List<_Meal> _meals = [];
  WorkoutPlan? _currentPlan;
  List<PlanWorkout> _currentPlanWorkouts = [];
  PlanWorkout? _selectedWorkout;

  @override
  void initState() {
    super.initState();
    _loadMealsForDate();
    _loadCurrentPlan();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final localeName = l10n.locale.languageCode;
    final mealCards = _buildMealCards();
    final consumedCalories =
        _meals.fold<double>(0, (prev, meal) => prev + meal.totalCalories);
    const targetCalories = 2000.0;
    final completion = targetCalories > 0
        ? (consumedCalories / targetCalories).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final formattedDate =
        DateFormat.yMMMMEEEEd(localeName).format(_selectedDate);
    final numberFormatter = NumberFormat.decimalPattern(localeName);

    final isProfile = _selectedTabIndex == 2;

    return Scaffold(
      appBar: AppBar(
        title: Text(isProfile ? 'Profilo' : l10n.clientHome),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.go(RoutePaths.settings),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: isProfile
              ? const ProfileContent()
              : ListView(
                  children: [
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _pickDate,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.calendar_today_rounded,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Data da visualizzare',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                formattedDate,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 140,
                              height: 140,
                              child: CircularProgressIndicator(
                                value: completion,
                                strokeWidth: 12,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${(completion * 100).round()}%',
                                  style: Theme.of(context)
                                      .textTheme
                                      .headlineSmall
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'completato',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Calorie giornaliere',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '${numberFormatter.format(consumedCalories)} kcal assunte',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${numberFormatter.format(targetCalories)} kcal obiettivo',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Manca ${numberFormatter.format((targetCalories - consumedCalories).clamp(0, targetCalories))} kcal',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Alimentazione',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 200,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: mealCards.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final meal = mealCards[index];
                            final hasFoods =
                                meal.foods.isNotEmpty && !meal.isPlaceholder;
                            final title = 'Pasto ${meal.mealIndex}';
                            return InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _openMeal(meal),
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant,
                                  ),
                                  color: Theme.of(context)
                                      .colorScheme
                                      .surfaceVariant
                                      .withOpacity(0.25),
                                ),
                                width: 220,
                                padding: const EdgeInsets.all(12),
                                child: hasFoods
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        const SizedBox(height: 8),
                                        ...meal.foods.map(
                                          (food) => Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              '- ${food.name} (${numberFormatter.format(food.kcal)} kcal)',
                                            ),
                                          ),
                                        ),
                                          const Spacer(),
                                          Text(
                                            '${numberFormatter.format(meal.totalCalories)} kcal',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurfaceVariant,
                                                ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Text(
                                            title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 16),
                                          Container(
                                            width: 64,
                                            height: 64,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.08),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.add,
                                              size: 36,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Aggiungi alimenti',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyMedium,
                                          ),
                                        ],
                                      ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _openWorkoutSelection,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Allenamento',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.35),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.12),
                                ),
                                child: Icon(
                                  Icons.fitness_center_outlined,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _selectedWorkout != null
                                          ? _selectedWorkout!.name
                                          : 'Nessun workout selezionato',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _currentPlan == null
                                          ? 'Nessuna scheda corrente'
                                          : _currentPlanWorkouts.isNotEmpty
                                              ? 'Tocca per selezionare un workout'
                                              : 'Nessun workout nella scheda corrente',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    if (_selectedWorkout != null)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: _buildWorkoutExercises(
                                            _selectedWorkout!,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              if (_selectedWorkout != null)
                                IconButton.filled(
                                  onPressed: _openWorkoutSelection,
                                  icon: const Icon(Icons.play_arrow),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedTabIndex,
        onTap: _onTabSelected,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.more_horiz_outlined),
            activeIcon: Icon(Icons.more_horiz),
            label: 'Altro',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profilo',
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
      await _loadMealsForDate();
    }
  }

  Future<void> _openMeal(_Meal meal) async {
    final mealIndex = meal.mealIndex;
    final result = await context.push<MealDetailResult>(
      RoutePaths.mealDetailFor(mealIndex),
      extra: MealDetailArgs(
        mealIndex: mealIndex,
        foods: meal.foods,
      ),
    );

    if (result == null) return;

    await _mealDataSource.replaceMealFoods(
      _selectedDate,
      mealIndex,
      result.foods,
    );
    await _loadMealsForDate();
  }

  void _onTabSelected(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
  }

  Future<void> _openWorkoutSelection() async {
    if (_currentPlan == null || _currentPlanWorkouts.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nessuna scheda o workout disponibile. Gestisci dal profilo.',
          ),
        ),
      );
      return;
    }

    final selected = await Navigator.of(context).push<PlanWorkout>(
      MaterialPageRoute(
        builder: (_) => WorkoutSelectionScreen(
          planName: _currentPlan!.name,
          workouts: _currentPlanWorkouts,
        ),
      ),
    );

    if (selected != null) {
      setState(() {
        _selectedWorkout = selected;
      });
    }
  }

  Future<void> _loadCurrentPlan() async {
    final plans = await _planDataSource.fetchPlans();
    if (plans.isEmpty) {
      setState(() {
        _currentPlan = null;
        _currentPlanWorkouts = [];
        _selectedWorkout = null;
      });
      return;
    }
    final previousPlanId = _currentPlan?.id;
    final previousWorkoutId = _selectedWorkout?.id;
    var current = plans.firstWhere(
      (p) => p.isCurrent,
      orElse: () => plans.first,
    );
    if (!current.isCurrent) {
      await _planDataSource.setCurrentPlan(current.id);
      current = WorkoutPlan(
        id: current.id,
        name: current.name,
        details: current.details,
        isCurrent: true,
      );
    }
    final workouts = await _planDataSource.fetchPlanWorkouts(current.id);
    PlanWorkout? selected;
    if (previousPlanId == current.id && previousWorkoutId != null) {
      for (final w in workouts) {
        if (w.id == previousWorkoutId) {
          selected = w;
          break;
        }
      }
    }
    setState(() {
      _currentPlan = current;
      _currentPlanWorkouts = workouts;
      _selectedWorkout = selected;
    });
  }

  void _openCurrentPlanWorkouts() {
    if (_currentPlan != null) {
      context
          .pushNamed(
        RoutePaths.workoutPlanDetailName,
        pathParameters: {'planId': '${_currentPlan!.id}'},
        extra: _currentPlan!.name,
      )
          .then((_) {
        _loadCurrentPlan();
      });
    } else {
      context.pushNamed(RoutePaths.workoutName).then((_) => _loadCurrentPlan());
    }
  }

  List<Widget> _buildWorkoutExercises(PlanWorkout workout) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium;
    try {
      final decoded = jsonDecode(workout.details);
      if (decoded is List) {
        final items = decoded.whereType<Map>().map((e) {
          final name = (e['name'] ?? '').toString();
          final sets = e['sets']?.toString();
          final reps = e['reps']?.toString();
          final notes = (e['notes'] ?? '').toString();
          var line = name;
          if (sets != null && reps != null && sets.isNotEmpty && reps.isNotEmpty) {
            line += ' ${sets}x$reps';
          }
          if (notes.isNotEmpty) {
            line += ' · $notes';
          }
          return line;
        }).where((l) => l.trim().isNotEmpty).toList();
        if (items.isNotEmpty) {
          return items
              .map((line) => Text('• $line', style: textStyle))
              .toList();
        }
      }
    } catch (_) {
      // fallback
    }
    if (workout.details.isNotEmpty) {
      final parts = workout.details
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isNotEmpty) {
        return parts.map((p) => Text('• $p', style: textStyle)).toList();
      }
    }
    return [
      Text(
        'Esercizi non disponibili',
        style: textStyle?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }

  Future<void> _loadMealsForDate() async {
    final entries = await _mealDataSource.fetchMealsForDate(_selectedDate);
    setState(() {
      _meals
        ..clear()
        ..addAll(
          entries.map(
            (entry) => _Meal(
              mealIndex: entry.mealIndex,
              foods: entry.foods,
              totalCalories: entry.totalKcal,
            ),
          ),
        );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadCurrentPlan();
  }

  List<_Meal> _buildMealCards() {
    final cards = List<_Meal>.from(_meals)
      ..sort((a, b) => a.mealIndex.compareTo(b.mealIndex));
    final nextIndex = cards.isEmpty
        ? 1
        : (cards.last.mealIndex + (cards.last.foods.isNotEmpty ? 1 : 0));
    if (cards.isEmpty || cards.last.foods.isNotEmpty) {
      cards.add(_Meal.placeholder(mealIndex: nextIndex));
    }
    return cards;
  }
}

class _Meal {
  const _Meal({
    required this.mealIndex,
    required this.foods,
    this.totalCalories = 0,
    this.isPlaceholder = false,
  });

  const _Meal.placeholder({required this.mealIndex})
      : foods = const [],
        totalCalories = 0,
        isPlaceholder = true;

  final int mealIndex;
  final List<MealFood> foods;
  final double totalCalories;
  final bool isPlaceholder;
}
