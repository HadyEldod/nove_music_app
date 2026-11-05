import 'package:musicc/domain/entities/album.dart';
import 'package:musicc/domain/entities/artist.dart';
import 'package:musicc/domain/entities/playlist.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/domain/entities/user.dart';

abstract class MusicRepository {
  Future<List<Track>> getTracks({String? query, String? order});

  Future<List<Track>> getTracksByTag(String tag);

  Future<List<Artist>> getArtists({String? query});

  Future<Artist?> getArtist(String artistId);

  Future<List<Track>> getArtistTracks(String artistId);

  Future<List<Album>> getAlbums({String? query});

  Future<List<Track>> getAlbumTracks(String albumId);

  Future<List<Playlist>> getPlaylists();

  Future<List<Track>> getPlaylistTracks(String playlistId);

  Future<String?> getPlaylistCover(String playlistId);

  Future<User?> getUser(String name);

  Future<List<Playlist>> getUserPlaylists(String userId);
}
