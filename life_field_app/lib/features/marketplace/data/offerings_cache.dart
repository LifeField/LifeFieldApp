import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/offering.dart';

class OfferingsCache {
  OfferingsCache({this.ttl = const Duration(minutes: 30)});

  final Duration ttl;
  static const _dataKey = 'offerings_cache_data';
  static const _timestampKey = 'offerings_cache_ts';

  Future<void> save(List<Offering> offerings) async {
    final prefs = await SharedPreferences.getInstance();
    final data = offerings.map((e) => e.toJson()).toList();
    await prefs.setString(_dataKey, jsonEncode(data));
    await prefs.setInt(_timestampKey, DateTime.now().millisecondsSinceEpoch);
  }

  Future<List<Offering>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt(_timestampKey);
    final raw = prefs.getString(_dataKey);
    if (ts == null || raw == null) {
      return [];
    }

    final isExpired = DateTime.now().difference(
          DateTime.fromMillisecondsSinceEpoch(ts),
        ) >
        ttl;
    if (isExpired) {
      await clear();
      return [];
    }

    final decoded = jsonDecode(raw);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Offering.fromJson)
          .toList();
    }
    return [];
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_dataKey);
    await prefs.remove(_timestampKey);
  }
}
