import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:musicc/domain/entities/track.dart';

enum RepeatMode { off, all, one }

class MusicPlayerService {
  /// Android audio effects wired into the playback pipeline. On other
  /// platforms these are inert, so the equalizer UI is visual-only there.
  final AndroidLoudnessEnhancer loudnessEnhancer = AndroidLoudnessEnhancer();
  final AndroidEqualizer equalizer = AndroidEqualizer();

  late final AudioPlayer player = AudioPlayer(
    audioPipeline: AudioPipeline(
      androidAudioEffects: [loudnessEnhancer, equalizer],
    ),
  );

  /// Current playback speed (1.0 = normal).
  final ValueNotifier<double> speed = ValueNotifier<double>(1.0);

  /// Whether the loudness "Enhance" boost is on.
  final ValueNotifier<bool> enhanceEnabled = ValueNotifier<bool>(false);

  /// Remaining time on the sleep timer, or null when inactive.
  final ValueNotifier<Duration?> sleepRemaining =
      ValueNotifier<Duration?>(null);

  Timer? _sleepEndTimer;
  Timer? _sleepTicker;

  /// The playlist currently loaded into the player.
  List<Track> _playlist = <Track>[];

  /// Index of the track currently playing, or null if nothing is loaded.
  final ValueNotifier<int?> currentIndex = ValueNotifier<int?>(null);

  /// Off / repeat-all / repeat-one.
  final ValueNotifier<RepeatMode> repeatMode =
      ValueNotifier<RepeatMode>(RepeatMode.off);

  /// Whether playback order is shuffled.
  final ValueNotifier<bool> shuffle = ValueNotifier<bool>(false);

  /// Invoked when a new track starts (used to record recently-played).
  void Function(Track track)? onTrackPlayed;

  MusicPlayerService() {
    // just_audio drives the current index (incl. auto-advance, notification
    // skip buttons and shuffle order) — mirror it into our notifier.
    player.currentIndexStream.listen((index) {
      currentIndex.value = index;
      final track = currentTrack;
      if (track != null) {
        onTrackPlayed?.call(track);
      }
    });
  }

  /// The tracks currently queued for playback.
  List<Track> get queue => List.unmodifiable(_playlist);

  /// Jump directly to a queue position.
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= _playlist.length) return;
    await player.seek(Duration.zero, index: index);
  }

  Track? get currentTrack {
    final index = currentIndex.value;
    if (index == null || index < 0 || index >= _playlist.length) {
      return null;
    }
    return _playlist[index];
  }

  bool get canSkip => _playlist.length > 1;

  // Streams the UI can listen to.
  Stream<bool> get playingStream => player.playingStream;
  Stream<Duration> get positionStream => player.positionStream;
  Stream<Duration?> get durationStream => player.durationStream;

  /// Combined playing + loading state so the UI can show a spinner while a
  /// track is being fetched/buffered.
  Stream<({bool playing, bool loading})> get playbackStream =>
      player.playerStateStream.map((s) {
        final loading = s.processingState == ProcessingState.loading ||
            s.processingState == ProcessingState.buffering;
        return (playing: s.playing, loading: loading);
      }).distinct();

  /// Wraps a [Track] in an audio source carrying [MediaItem] metadata so the
  /// system notification shows the title, artist and artwork.
  AudioSource _toSource(Track track) {
    final raw = track.audioUrl;
    // Remote streams are http(s), device songs are content:// URIs, and a
    // plain path is a local file.
    final Uri uri;
    if (raw.startsWith('http') || raw.startsWith('content://')) {
      uri = Uri.parse(raw);
    } else {
      uri = Uri.file(raw);
    }
    return AudioSource.uri(
      uri,
      tag: MediaItem(
        id: track.id,
        title: track.name,
        artist: track.artistName.isEmpty ? 'On this device' : track.artistName,
        album: track.albumName,
        artUri: track.imageUrl.isEmpty ? null : Uri.parse(track.imageUrl),
      ),
    );
  }

  /// Load a playlist and start playing the track at [index].
  Future<void> playPlaylist(List<Track> tracks, int index) async {
    _playlist = tracks;
    try {
      await player.setAudioSources(
        tracks.map(_toSource).toList(),
        initialIndex: index,
        initialPosition: Duration.zero,
      );
      await player.play();
    } catch (e) {
      debugPrint('PLAYER ERROR: $e');
    }
  }

  Future<void> togglePlayPause() async {
    if (player.playing) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  Future<void> pause() => player.pause();

  Future<void> resume() => player.play();

  Future<void> next() => player.seekToNext();

  Future<void> previous() async {
    // Restart the current track if we're more than 3s in.
    if (player.position > const Duration(seconds: 3)) {
      await player.seek(Duration.zero);
    } else {
      await player.seekToPrevious();
    }
  }

  Future<void> seek(Duration position) => player.seek(position);

  Future<void> stop() => player.stop();

  // --- Sound controls (equalizer screen) --------------------------------

  /// Enable/disable the Android equalizer effect (no-op elsewhere).
  Future<void> setEqualizerEnabled(bool enabled) async {
    try {
      await equalizer.setEnabled(enabled);
    } catch (_) {
      // Not supported on this platform.
    }
  }

  /// Playback speed, 0.5×–2× (works on all platforms).
  Future<void> setSpeed(double value) async {
    speed.value = value;
    await player.setSpeed(value);
  }

  /// Loudness "Enhance" boost (Android only).
  Future<void> setEnhance(bool enabled) async {
    enhanceEnabled.value = enabled;
    try {
      await loudnessEnhancer.setEnabled(enabled);
      await loudnessEnhancer.setTargetGain(enabled ? 5.0 : 0.0);
    } catch (_) {
      // Not supported on this platform.
    }
  }

  /// Pause playback after [duration]; call [cancelSleepTimer] to abort.
  void startSleepTimer(Duration duration) {
    cancelSleepTimer();
    var remaining = duration;
    sleepRemaining.value = remaining;
    _sleepTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      remaining -= const Duration(seconds: 1);
      sleepRemaining.value = remaining.isNegative ? Duration.zero : remaining;
    });
    _sleepEndTimer = Timer(duration, () async {
      await pause();
      cancelSleepTimer();
    });
  }

  void cancelSleepTimer() {
    _sleepEndTimer?.cancel();
    _sleepTicker?.cancel();
    _sleepEndTimer = null;
    _sleepTicker = null;
    sleepRemaining.value = null;
  }

  Future<void> toggleShuffle() async {
    final enabled = !shuffle.value;
    shuffle.value = enabled;
    if (enabled) {
      await player.shuffle();
    }
    await player.setShuffleModeEnabled(enabled);
  }

  Future<void> cycleRepeatMode() async {
    final next = RepeatMode
        .values[(repeatMode.value.index + 1) % RepeatMode.values.length];
    repeatMode.value = next;
    switch (next) {
      case RepeatMode.off:
        await player.setLoopMode(LoopMode.off);
      case RepeatMode.all:
        await player.setLoopMode(LoopMode.all);
      case RepeatMode.one:
        await player.setLoopMode(LoopMode.one);
    }
  }

  Future<void> dispose() async {
    cancelSleepTimer();
    currentIndex.dispose();
    repeatMode.dispose();
    shuffle.dispose();
    speed.dispose();
    enhanceEnabled.dispose();
    sleepRemaining.dispose();
    await player.dispose();
  }
}
