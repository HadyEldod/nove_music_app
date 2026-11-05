import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Persists onboarding completion and the user's taste selections
/// (favorite genre tags and artist ids) locally.
class OnboardingStorage {
  static const _completeKey = 'onboarding_complete';
  static const _genresKey = 'onboarding_genres';
  static const _artistsKey = 'onboarding_artists';

  Future<bool> isComplete() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completeKey) ?? false;
  }

  Future<void> complete({
    required List<String> genreTags,
    required List<String> artistIds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_completeKey, true);
    await prefs.setString(_genresKey, jsonEncode(genreTags));
    await prefs.setString(_artistsKey, jsonEncode(artistIds));
  }

  Future<List<String>> readGenres() => _readList(_genresKey);

  Future<List<String>> readArtists() => _readList(_artistsKey);

  Future<List<String>> _readList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [];
    }
  }
}
