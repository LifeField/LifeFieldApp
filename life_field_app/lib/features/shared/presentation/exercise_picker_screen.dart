import 'package:flutter/material.dart';

import '../data/datasources/exercise_catalog_data_source.dart';
import '../domain/entities/exercise_catalog_entry.dart';

class ExercisePickerScreen extends StatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  State<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends State<ExercisePickerScreen> {
  final ExerciseCatalogDataSource _dataSource =
      ExerciseCatalogDataSource.instance;
  final TextEditingController _searchController = TextEditingController();
  List<ExerciseCatalogEntry> _all = [];
  List<ExerciseCatalogEntry> _filtered = [];

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final items = await _dataSource.loadCatalog();
    setState(() {
      _all = items;
      _filtered = items;
    });
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      _filtered = _all
          .where((ex) =>
              ex.name.toLowerCase().contains(query) ||
              (ex.muscle ?? '').toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleziona esercizio'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Cerca esercizio',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            Expanded(
              child: _filtered.isEmpty
                  ? const Center(child: Text('Nessun esercizio trovato'))
                  : ListView.separated(
                      itemCount: _filtered.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final ex = _filtered[index];
                        return ListTile(
                          title: Text(ex.name),
                          subtitle: ex.muscle != null || ex.notes != null
                              ? Text([
                                  if (ex.muscle?.isNotEmpty == true) ex.muscle!,
                                  if (ex.notes?.isNotEmpty == true) ex.notes!,
                                ].join(' | '))
                              : null,
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () => Navigator.of(context).pop(ex),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
