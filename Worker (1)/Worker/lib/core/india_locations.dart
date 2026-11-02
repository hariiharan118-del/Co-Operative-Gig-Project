import 'dart:convert';

import 'package:flutter/services.dart';

class IndiaState {
  const IndiaState({required this.name, required this.cities});

  final String name;
  final List<String> cities;
}

class IndiaLocations {
  IndiaLocations._();

  static List<IndiaState>? _cache;

  static Future<List<IndiaState>> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/india_locations.json');
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = [
      for (final item in list)
        if (item is Map)
          IndiaState(
            name: '${item['state'] ?? ''}',
            cities: [
              for (final city in (item['cities'] as List? ?? const [])
                ) '$city',
            ],
          ),
    ]..removeWhere((state) => state.name.isEmpty);
    return _cache!;
  }

  static (String? state, String? city) splitStoredCity(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return (null, null);
    final comma = text.lastIndexOf(',');
    if (comma <= 0) return (null, text);
    final city = text.substring(0, comma).trim();
    final state = text.substring(comma + 1).trim();
    if (city.isEmpty) return (null, text);
    return (state.isEmpty ? null : state, city);
  }

  static String? stateForCity(String city, List<IndiaState> states) {
    final needle = city.trim().toLowerCase();
    if (needle.isEmpty) return null;
    for (final state in states) {
      for (final name in state.cities) {
        if (name.toLowerCase() == needle) return state.name;
      }
    }
    return null;
  }
}
