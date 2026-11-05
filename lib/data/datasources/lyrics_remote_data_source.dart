import 'package:dio/dio.dart';

/// Fetches plain-text song lyrics from the free lyrics.ovh API.
///
/// No API key is required. The endpoint is
/// `https://api.lyrics.ovh/v1/{artist}/{title}` and returns either
/// `{"lyrics": "..."}` or `{"error": "..."}` when nothing is found.
class LyricsRemoteDataSource {
  final Dio _dio;

  LyricsRemoteDataSource([Dio? dio])
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://api.lyrics.ovh/v1',
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                headers: {'Accept': 'application/json'},
              ),
            );

  /// Returns the lyrics as a list of trimmed lines, or an empty list when
  /// lyrics could not be found for the given [artist] / [title].
  Future<List<String>> getLyrics({
    required String artist,
    required String title,
  }) async {
    final a = _clean(artist);
    final t = _clean(title);
    if (a.isEmpty || t.isEmpty) return const [];

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/${Uri.encodeComponent(a)}/${Uri.encodeComponent(t)}',
      );
      final raw = response.data?['lyrics'];
      if (raw is! String || raw.trim().isEmpty) return const [];
      return _toLines(raw);
    } on DioException {
      // 404 (not found) and network errors both surface as "no lyrics".
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Strips noise the API dislikes: "(feat. …)", bracketed extras, etc.
  String _clean(String value) {
    var v = value.trim();
    final featIndex = v.toLowerCase().indexOf(RegExp(r'\s*\(?feat\.?'));
    if (featIndex > 0) v = v.substring(0, featIndex);
    return v.trim();
  }

  List<String> _toLines(String raw) {
    // The API separates paragraphs with "\r\n\r\n"; normalise then split.
    return raw
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .split('\n')
        .map((l) => l.trim())
        .toList();
  }
}
