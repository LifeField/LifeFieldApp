import 'package:flutter/material.dart';

import '../../../app/localization/app_localizations.dart';

class MealDetailScreen extends StatefulWidget {
  const MealDetailScreen({
    super.key,
    required this.mealIndex,
    this.initialFoods = const [],
  });

  final int mealIndex;
  final List<MealFood> initialFoods;

  @override
  State<MealDetailScreen> createState() => _MealDetailScreenState();
}

class _MealDetailScreenState extends State<MealDetailScreen> {
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _kcalController = TextEditingController();
  late List<MealFood> _foods = List.of(widget.initialFoods);

  @override
  void dispose() {
    _foodController.dispose();
    _kcalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final title = 'Pasto ${widget.mealIndex}';
    final totalKcal =
        _foods.fold<double>(0, (prev, element) => prev + element.kcal);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: BackButton(
            onPressed: _popWithResult,
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(
                  'Gestisci il pasto in locale. Aggiungi gli alimenti e le calorie direttamente sul dispositivo.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _foodController,
                        decoration: const InputDecoration(
                          labelText: 'Alimento',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 120,
                      child: TextField(
                        controller: _kcalController,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Kcal',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _addFood,
                      icon: const Icon(Icons.add),
                      label: const Text('Aggiungi'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (_foods.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.add,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Nessun alimento aggiunto. Inizia qui sopra.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      itemCount: _foods.length + 1,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        if (index == _foods.length) {
                          return _TotalCard(totalKcal: totalKcal);
                        }
                        final food = _foods[index];
                        return Dismissible(
                          key: ValueKey(food),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .error
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                          onDismissed: (_) => setState(() {
                            _foods.removeAt(index);
                          }),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    Theme.of(context).colorScheme.surfaceVariant,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      food.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleSmall
                                          ?.copyWith(fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${food.kcal.toStringAsFixed(0)} kcal',
                                      style:
                                          Theme.of(context).textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => setState(() {
                                    _foods.removeAt(index);
                                  }),
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
      ),
    );
  }

  void _addFood() {
    final name = _foodController.text.trim();
    final kcal = double.tryParse(_kcalController.text.trim());
    if (name.isEmpty || kcal == null || kcal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un alimento e calorie valide')),
      );
      return;
    }

    setState(() {
      _foods.add(MealFood(name: name, kcal: kcal));
      _foodController.clear();
      _kcalController.clear();
    });
  }

  Future<bool> _onWillPop() async {
    _popWithResult();
    return false;
  }

  void _popWithResult() {
    Navigator.of(context).pop(
      MealDetailResult(
        mealIndex: widget.mealIndex,
        foods: _foods,
        totalKcal: _foods.fold<double>(0, (prev, el) => prev + el.kcal),
      ),
    );
  }
}

class MealFood {
  const MealFood({required this.name, required this.kcal});

  final String name;
  final double kcal;
}

class MealDetailArgs {
  const MealDetailArgs({
    required this.mealIndex,
    this.foods = const [],
  });

  final int mealIndex;
  final List<MealFood> foods;
}

class MealDetailResult {
  const MealDetailResult({
    required this.mealIndex,
    required this.foods,
    required this.totalKcal,
  });

  final int mealIndex;
  final List<MealFood> foods;
  final double totalKcal;
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.totalKcal});

  final double totalKcal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Totale pasto',
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          Text(
            '${totalKcal.toStringAsFixed(0)} kcal',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
          ),
        ],
      ),
    );
  }
}
