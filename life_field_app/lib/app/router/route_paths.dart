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
  static const workoutPlanDetail = '$workout/:planId';
  static const workoutPlanDetailName = 'workout-plan-detail';
  static const workoutExecutionBase = '/workout/execution';
  static const workoutExecution = '$workoutExecutionBase/:workoutId';
  static const workoutExecutionName = 'workout-execution';
  static const profile = '/profile';
  static const profileName = 'profile';

  static String mealDetailFor(int mealIndex) => '$mealBase/$mealIndex';
  static String workoutExecutionFor(int workoutId) =>
      '$workoutExecutionBase/$workoutId';
}
