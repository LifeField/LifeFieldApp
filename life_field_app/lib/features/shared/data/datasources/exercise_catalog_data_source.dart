import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/exercise_catalog_entry.dart';

class ExerciseCatalogDataSource {
  ExerciseCatalogDataSource._();

  static final ExerciseCatalogDataSource instance =
      ExerciseCatalogDataSource._();

  List<ExerciseCatalogEntry>? _cache;

  Future<List<ExerciseCatalogEntry>> loadCatalog() async {
    if (_cache != null) return _cache!;
    final jsonStr = await rootBundle.loadString('assets/data/exercises.json');
    final raw = json.decode(jsonStr);
    if (raw is! List) {
      _cache = [];
      return _cache!;
    }
    _cache = raw
        .whereType<Map>()
        .map(_mapEntry)
        .where((ex) => ex.name.isNotEmpty)
        .toList();
    return _cache!;
  }

  ExerciseCatalogEntry _mapEntry(Map item) {
    final id = (item['id'] ?? item['codice'] ?? '').toString();
    final name = (item['name'] ?? item['nome'] ?? '').toString();
    final muscle = (item['muscle'] ?? item['muscoloTarget'] ?? '').toString();

    String? notes;
    final secondary = item['muscoliSecondari'];
    final equipment = item['materialeNecessario'];
    final difficolta = item['difficolta'];

    final parts = <String>[];
    if (secondary is List && secondary.isNotEmpty) {
      parts.add('Secondari: ${secondary.join(', ')}');
    }
    if (equipment is List && equipment.isNotEmpty) {
      parts.add('Attrezzi: ${equipment.join(', ')}');
    }
    if (difficolta != null) {
      parts.add('Diff: $difficolta/5');
    }
    if (parts.isNotEmpty) {
      notes = parts.join(' | ');
    } else {
      notes = (item['notes'] ?? '').toString();
    }

    final rawVideo = (item['videoUrl'] ?? '').toString();

    return ExerciseCatalogEntry(
      id: id.isNotEmpty ? id : name,
      name: name,
      muscle: muscle.isNotEmpty ? muscle : null,
      notes: notes?.isNotEmpty == true ? notes : null,
      videoUrl: rawVideo.isNotEmpty ? rawVideo : null,
    );
  }
}
