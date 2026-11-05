import 'package:musicc/data/datasources/music_remote_data_source.dart';
import 'package:musicc/domain/entities/album.dart';
import 'package:musicc/domain/entities/artist.dart';
import 'package:musicc/domain/entities/playlist.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/domain/entities/user.dart';
import 'package:musicc/domain/repositories/music_repository.dart';

class MusicRepositoryImpl implements MusicRepository {
  final MusicRemoteDataSource remoteDataSource;

  MusicRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Track>> getTracks({String? query, String? order}) async {
    return await remoteDataSource.getTracks(
      query: query,
      order: order ?? 'popularity_total',
    );
  }

  @override
  Future<List<Artist>> getArtists({String? query}) async {
    return await remoteDataSource.getArtists(query: query);
  }

  @override
  Future<Artist?> getArtist(String artistId) async {
    return await remoteDataSource.getArtist(artistId);
  }

  @override
  Future<List<Track>> getArtistTracks(String artistId) async {
    return await remoteDataSource.getArtistTracks(artistId);
  }

  @override
  Future<List<Track>> getTracksByTag(String tag) async {
    return await remoteDataSource.getTracksByTag(tag);
  }

  @override
  Future<List<Album>> getAlbums({String? query}) async {
    return await remoteDataSource.getAlbums(query: query);
  }

  @override
  Future<List<Track>> getAlbumTracks(String albumId) async {
    return await remoteDataSource.getAlbumTracks(albumId);
  }

  @override
  Future<List<Playlist>> getPlaylists() async {
    return await remoteDataSource.getPlaylists();
  }

  @override
  Future<List<Track>> getPlaylistTracks(String playlistId) async {
    return await remoteDataSource.getPlaylistTracks(playlistId);
  }

  @override
  Future<String?> getPlaylistCover(String playlistId) async {
    return await remoteDataSource.getPlaylistCover(playlistId);
  }

  @override
  Future<User?> getUser(String name) async {
    return await remoteDataSource.getUser(name);
  }

  @override
  Future<List<Playlist>> getUserPlaylists(String userId) async {
    return await remoteDataSource.getUserPlaylists(userId);
  }
}
