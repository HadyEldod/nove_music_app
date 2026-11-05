import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import 'package:musicc/core/api_constants.dart';
import 'package:musicc/data/models/album_model.dart';
import 'package:musicc/data/models/artist_model.dart';
import 'package:musicc/data/models/playlist_model.dart';
import 'package:musicc/data/models/track_model.dart';
import 'package:musicc/data/models/user_model.dart';

class MusicRemoteDataSource {
  final Dio dio;

  MusicRemoteDataSource(this.dio);

  /// Runs a GET against Jamendo and returns the `results` array.
  Future<List<dynamic>> _getResults(
    String path,
    Map<String, dynamic> params,
  ) async {
    try {
      final response = await dio.get(
        path,
        queryParameters: {
          'client_id': ApiConstants.clientId,
          'format': 'jsonpretty',
          ...params,
        },
      );
      return (response.data['results'] as List<dynamic>?) ?? const [];
    } catch (e) {
      debugPrint('JAMENDO ERROR ($path): $e');
      rethrow;
    }
  }

  Future<List<TrackModel>> getTracks({
    String? query,
    String order = 'popularity_total',
    int limit = 40,
  }) async {
    final results = await _getResults(ApiConstants.tracks, {
      'limit': limit,
      'order': order,
      'audioformat': 'mp32',
      'include': 'musicinfo',
      if (query != null && query.trim().isNotEmpty)
        'namesearch': query.trim(),
    });

    return results
        .map((json) => TrackModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<ArtistModel>> getArtists({
    String? query,
    int limit = 40,
  }) async {
    final results = await _getResults(ApiConstants.artists, {
      'limit': limit,
      'order': 'popularity_total',
      'imagesize': 300,
      'hasimage': 1,
      if (query != null && query.trim().isNotEmpty)
        'namesearch': query.trim(),
    });

    return results
        .map((json) => ArtistModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrackModel>> getTracksByTag(String tag, {int limit = 40}) async {
    final results = await _getResults(ApiConstants.tracks, {
      'limit': limit,
      'order': 'popularity_total',
      'audioformat': 'mp32',
      'tags': tag,
    });
    return results
        .map((json) => TrackModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<AlbumModel>> getAlbums({String? query, int limit = 40}) async {
    final results = await _getResults(ApiConstants.albums, {
      'limit': limit,
      'order': 'popularity_total',
      'imagesize': 300,
      if (query != null && query.trim().isNotEmpty)
        'namesearch': query.trim(),
    });
    return results
        .map((json) => AlbumModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrackModel>> getAlbumTracks(String albumId) async {
    final results = await _getResults(ApiConstants.albumTracks, {
      'id': albumId,
      'audioformat': 'mp32',
    });
    if (results.isEmpty) return const [];

    final album = results.first as Map<String, dynamic>;
    final artistId = album['artist_id']?.toString() ?? '';
    final artistName = album['artist_name'] ?? '';
    final albumImage = album['image'] ?? '';
    final tracks = (album['tracks'] as List<dynamic>?) ?? const [];

    return tracks.map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      // Album-grouped tracks omit these — inject from the album level.
      json['artist_id'] ??= artistId;
      json['artist_name'] ??= artistName;
      json['album_image'] ??= albumImage;
      return TrackModel.fromJson(json);
    }).toList();
  }

  Future<ArtistModel?> getArtist(String artistId) async {
    final results = await _getResults(ApiConstants.artists, {
      'id': artistId,
    });
    if (results.isEmpty) return null;
    return ArtistModel.fromJson(results.first as Map<String, dynamic>);
  }

  Future<List<TrackModel>> getArtistTracks(String artistId) async {
    final results = await _getResults(ApiConstants.artistTracks, {
      'id': artistId,
      'audioformat': 'mp32',
    });
    if (results.isEmpty) return const [];

    final artist = results.first as Map<String, dynamic>;
    final artistName = artist['name'] ?? '';
    final tracks = (artist['tracks'] as List<dynamic>?) ?? const [];

    return tracks.map((raw) {
      final json = Map<String, dynamic>.from(raw as Map);
      // Artist-grouped tracks omit artist fields — inject them.
      json['artist_id'] ??= artistId;
      json['artist_name'] ??= artistName;
      return TrackModel.fromJson(json);
    }).toList();
  }

  Future<List<PlaylistModel>> getPlaylists({int limit = 40}) async {
    // /playlists only supports order by {name, id, creationdate}.
    final results = await _getResults(ApiConstants.playlists, {
      'limit': limit,
      'order': 'creationdate_desc',
    });

    return results
        .map((json) => PlaylistModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TrackModel>> getPlaylistTracks(String playlistId) async {
    final results = await _getResults(ApiConstants.playlistTracks, {
      'id': playlistId,
      'audioformat': 'mp32',
    });
    if (results.isEmpty) return const [];

    final playlist = results.first as Map<String, dynamic>;
    final tracks = (playlist['tracks'] as List<dynamic>?) ?? const [];

    return tracks
        .map((raw) =>
            TrackModel.fromJson(Map<String, dynamic>.from(raw as Map)))
        .toList();
  }

  /// Jamendo playlists have no cover image, so we derive one from the first
  /// track's album art.
  Future<String?> getPlaylistCover(String playlistId) async {
    final results = await _getResults(ApiConstants.playlistTracks, {
      'id': playlistId,
    });
    if (results.isEmpty) return null;

    final tracks =
        (results.first as Map<String, dynamic>)['tracks'] as List<dynamic>? ??
            const [];
    for (final raw in tracks) {
      final track = raw as Map<String, dynamic>;
      final image = (track['album_image'] ?? track['image']) as String?;
      if (image != null && image.isNotEmpty) return image;
    }
    return null;
  }

  /// Public profile lookup by username (no OAuth needed).
  Future<UserModel?> getUser(String name) async {
    final results = await _getResults(ApiConstants.users, {
      'name': name.trim(),
      'imagesize': 100,
    });
    if (results.isEmpty) return null;
    return UserModel.fromJson(results.first as Map<String, dynamic>);
  }

  Future<List<PlaylistModel>> getUserPlaylists(String userId) async {
    final results = await _getResults(ApiConstants.playlists, {
      'user_id': userId,
      'order': 'creationdate_desc',
      'limit': 50,
    });
    return results
        .map((json) => PlaylistModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
