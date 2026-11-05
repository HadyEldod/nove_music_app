import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:musicc/domain/entities/track.dart';

/// Persists liked tracks and recently played history locally.
class LibraryStorage {
  static const _favoritesKey = 'favorite_tracks';
  static const _recentKey = 'recent_tracks';

  Future<List<Track>> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Track.fromMap(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(String key, List<Track> tracks) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(tracks.map((t) => t.toMap()).toList());
    await prefs.setString(key, raw);
  }

  Future<List<Track>> readFavorites() => _read(_favoritesKey);
  Future<void> saveFavorites(List<Track> tracks) =>
      _write(_favoritesKey, tracks);

  Future<List<Track>> readRecent() => _read(_recentKey);
  Future<void> saveRecent(List<Track> tracks) => _write(_recentKey, tracks);
}
