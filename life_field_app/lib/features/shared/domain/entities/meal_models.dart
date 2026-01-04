class MealFood {
  const MealFood({required this.name, required this.kcal});

  final String name;
  final double kcal;
}

class MealEntry {
  const MealEntry({
    required this.mealIndex,
    required this.foods,
  });

  final int mealIndex;
  final List<MealFood> foods;

  double get totalKcal =>
      foods.fold<double>(0, (prev, el) => prev + el.kcal);
}
  