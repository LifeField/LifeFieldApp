class ExerciseCatalogEntry {
  const ExerciseCatalogEntry({
    required this.name,
    this.muscle,
    this.notes,
  });

  final String name;
  final String? muscle;
  final String? notes;
}
