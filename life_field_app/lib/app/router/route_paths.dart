class RoutePaths {
  static const login = '/login';
  static const clientHome = '/client/home';
  static const proHome = '/pro/home';
  static const adminHome = '/admin/home';
  static const settings = '/settings';
  static const mealBase = '/meal';
  static const mealDetail = '$mealBase/:mealIndex';
  static const mealDetailName = 'meal-detail';
  static const workout = '/workout';
  static const workoutName = 'workout';

  static String mealDetailFor(int mealIndex) => '$mealBase/$mealIndex';
}
