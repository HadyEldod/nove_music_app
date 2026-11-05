import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:on_audio_query_pluse/on_audio_query.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/presentation/cubit/device_music_state.dart';

/// Automatically scans the device's music library via MediaStore.
class DeviceMusicCubit extends Cubit<DeviceMusicState> {
  final OnAudioQuery _audioQuery = OnAudioQuery();

  DeviceMusicCubit() : super(DeviceMusicInitial());

  Future<void> load() async {
    emit(DeviceMusicLoading());
    try {
      var granted = await _pluginHasPermission();

      // Ask via the plugin first (its request matches its own status check).
      if (!granted) {
        granted = await _pluginRequest();
      }
      // Backup: trigger the OS dialogs through permission_handler, then
      // re-check with the plugin. NOTE: on_audio_query requires BOTH audio
      // and images permission on Android 13+, so request both.
      if (!granted) {
        await [
          Permission.audio,
          Permission.photos,
          Permission.storage, // older Android
        ].request();
        granted = await _pluginHasPermission();
      }

      // CRITICAL: only query if the plugin itself confirms access —
      // querySongs crashes the app natively when permission is missing.
      if (!granted) {
        final permanently = await Permission.audio.isPermanentlyDenied ||
            await Permission.photos.isPermanentlyDenied;
        emit(DeviceMusicDenied(permanentlyDenied: permanently));
        return;
      }

      final songs = await _audioQuery.querySongs(
        sortType: SongSortType.TITLE,
        orderType: OrderType.ASC_OR_SMALLER,
        uriType: UriType.EXTERNAL,
        ignoreCase: true,
      );

      debugPrint('DEVICE MUSIC: found ${songs.length} songs');

      final tracks = songs
          .where((s) => s.uri != null || s.data.isNotEmpty)
          .map(_toTrack)
          .toList();

      emit(DeviceMusicLoaded(tracks));
    } catch (e) {
      debugPrint('DEVICE MUSIC ERROR: $e');
      emit(DeviceMusicError(e.toString()));
    }
  }

  Future<bool> _pluginHasPermission() async {
    try {
      return await _audioQuery.permissionsStatus();
    } catch (_) {
      return false;
    }
  }

  Future<bool> _pluginRequest() async {
    try {
      return await _audioQuery.permissionsRequest();
    } catch (_) {
      return false;
    }
  }

  Future<void> openSettings() => openAppSettings();

  Track _toTrack(SongModel song) {
    final artist = song.artist;
    return Track(
      id: 'device:${song.id}',
      name: song.title,
      artistId: '',
      artistName:
          (artist == null || artist == '<unknown>') ? 'Unknown artist' : artist,
      albumName: song.album ?? '',
      imageUrl: '',
      audioUrl: song.uri ?? song.data,
      duration: ((song.duration ?? 0) / 1000).round(),
    );
  }
}
