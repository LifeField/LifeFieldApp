import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../../domain/entities/meal_models.dart';

class MealLocalDataSource {
  MealLocalDataSource._();

  static final MealLocalDataSource instance = MealLocalDataSource._();

  Database? _db;
  final _dateFormatter = DateFormat('yyyy-MM-dd');

  Future<Database> _database() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'life_field_meals.db');
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
        CREATE TABLE meal_foods(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          meal_index INTEGER NOT NULL,
          name TEXT NOT NULL,
          kcal REAL NOT NULL
        );
        ''');
      },
    );
    return _db!;
  }

  Future<List<MealEntry>> fetchMealsForDate(DateTime date) async {
    final db = await _database();
    final dateKey = _dateFormatter.format(date);

    final rows = await db.query(
      'meal_foods',
      where: 'date = ?',
      whereArgs: [dateKey],
      orderBy: 'meal_index ASC, id ASC',
    );

    final Map<int, List<MealFood>> meals = {};
    for (final row in rows) {
      final mealIndex = row['meal_index'] as int;
      meals.putIfAbsent(mealIndex, () => []);
      meals[mealIndex]!.add(
        MealFood(
          name: row['name'] as String,
          kcal: (row['kcal'] as num).toDouble(),
        ),
      );
    }

    final entries = meals.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return entries
        .map(
          (entry) => MealEntry(
            mealIndex: entry.key,
            foods: entry.value,
          ),
        )
        .toList();
  }

  Future<void> replaceMealFoods(
    DateTime date,
    int mealIndex,
    List<MealFood> foods,
  ) async {
    final db = await _database();
    final dateKey = _dateFormatter.format(date);

    await db.transaction((txn) async {
      await txn.delete(
        'meal_foods',
        where: 'date = ? AND meal_index = ?',
        whereArgs: [dateKey, mealIndex],
      );

      for (final food in foods) {
        await txn.insert(
          'meal_foods',
          {
            'date': dateKey,
            'meal_index': mealIndex,
            'name': food.name,
            'kcal': food.kcal,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
