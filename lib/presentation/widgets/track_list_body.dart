import 'package:flutter/material.dart';

import 'package:musicc/presentation/cubit/music_state.dart';
import 'package:musicc/presentation/services/music_player_service.dart';
import 'package:musicc/presentation/widgets/track_tile.dart';

/// Renders the standard loading / error / empty / list states for a screen
/// backed by a [MusicState] of tracks.
class TrackListBody extends StatelessWidget {
  final MusicState state;
  final MusicPlayerService playerService;
  final Future<void> Function() onRefresh;
  final Widget? header;

  const TrackListBody({
    super.key,
    required this.state,
    required this.playerService,
    required this.onRefresh,
    this.header,
  });

  @override
  Widget build(BuildContext context) {
    final state = this.state;

    if (state is MusicLoading || state is MusicInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is MusicError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off, size: 48),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(state.message, textAlign: TextAlign.center),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state is MusicSuccess) {
      final tracks = state.tracks;
      if (tracks.isEmpty) {
        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            children: [
              ?header,
              const SizedBox(height: 120),
              const Center(child: Text('No songs here yet')),
            ],
          ),
        );
      }

      final hasHeader = header != null;
      return RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView.builder(
          itemCount: tracks.length + (hasHeader ? 1 : 0),
          itemBuilder: (context, index) {
            if (hasHeader && index == 0) return header!;
            final trackIndex = hasHeader ? index - 1 : index;
            return TrackTile(
              tracks: tracks,
              index: trackIndex,
              playerService: playerService,
            );
          },
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
