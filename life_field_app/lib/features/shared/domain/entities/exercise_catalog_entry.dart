class ExerciseCatalogEntry {
  const ExerciseCatalogEntry({
    required this.id,
    required this.name,
    this.muscle,
    this.notes,
    this.videoUrl,
  });

  final String id;
  final String name;
  final String? muscle;
  final String? notes;
  final String? videoUrl;
}
