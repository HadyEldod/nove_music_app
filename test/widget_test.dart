// Smoke test for the Jamendo Music app.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:musicc/domain/entities/album.dart';
import 'package:musicc/domain/entities/artist.dart';
import 'package:musicc/domain/entities/playlist.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/domain/entities/user.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/main.dart';

/// A repository that returns fixed data without touching the network.
class FakeMusicRepository implements MusicRepository {
  @override
  Future<List<Track>> getTracks({String? query, String? order}) async {
    return const [
      Track(
        id: '1',
        name: 'Test Song',
        artistId: '10',
        artistName: 'Test Artist',
        albumName: 'Test Album',
        imageUrl: '',
        audioUrl: '',
      ),
    ];
  }

  @override
  Future<List<Artist>> getArtists({String? query}) async => const [
        Artist(id: '10', name: 'Test Artist', imageUrl: ''),
      ];

  @override
  Future<Artist?> getArtist(String artistId) async =>
      const Artist(id: '10', name: 'Test Artist', imageUrl: '');

  @override
  Future<List<Track>> getArtistTracks(String artistId) async => getTracks();

  @override
  Future<List<Track>> getTracksByTag(String tag) async => getTracks();

  @override
  Future<List<Album>> getAlbums({String? query}) async => const [];

  @override
  Future<List<Track>> getAlbumTracks(String albumId) async => getTracks();

  @override
  Future<List<Playlist>> getPlaylists() async => const [];

  @override
  Future<List<Track>> getPlaylistTracks(String playlistId) async =>
      getTracks();

  @override
  Future<String?> getPlaylistCover(String playlistId) async => null;

  @override
  Future<User?> getUser(String name) async => null;

  @override
  Future<List<Playlist>> getUserPlaylists(String userId) async => const [];
}

void main() {
  testWidgets('App builds and shows tracks', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MyApp(repository: FakeMusicRepository()));
    await tester.pumpAndSettle();

    expect(find.text('Jamendo Music'), findsOneWidget);
    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
  });
}
