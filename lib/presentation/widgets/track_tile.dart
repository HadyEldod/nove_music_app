import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/presentation/cubit/library_cubit.dart';
import 'package:musicc/presentation/cubit/library_state.dart';
import 'package:musicc/presentation/pages/artist_page.dart';
import 'package:musicc/presentation/pages/now_playing_page.dart';
import 'package:musicc/presentation/services/music_player_service.dart';

/// A single track row. Tapping plays it (or opens the full-screen player if
/// it's already the current track); tapping the artist name opens the artist.
class TrackTile extends StatelessWidget {
  final List<Track> tracks;
  final int index;
  final MusicPlayerService playerService;

  const TrackTile({
    super.key,
    required this.tracks,
    required this.index,
    required this.playerService,
  });

  Track get track => tracks[index];

  void _openArtist(BuildContext context) {
    if (track.artistId.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistPage(
          artistId: track.artistId,
          artistName: track.artistName,
          playerService: playerService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: playerService.currentIndex,
      builder: (context, currentIndex, _) {
        final isCurrent = playerService.currentTrack?.id == track.id;

        return ListTile(
          selected: isCurrent,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: track.imageUrl,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.music_note),
                    ),
                  ),
                  if (isCurrent)
                    Container(
                      color: Colors.black45,
                      child: const Icon(Icons.equalizer, color: Colors.white),
                    ),
                ],
              ),
            ),
          ),
          title: Text(
            track.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          subtitle: GestureDetector(
            onTap: track.artistId.isEmpty ? null : () => _openArtist(context),
            child: Text(
              track.artistName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                decoration: track.artistId.isEmpty
                    ? null
                    : TextDecoration.underline,
              ),
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (track.durationText.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: Text(
                    track.durationText,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
              BlocBuilder<LibraryCubit, LibraryState>(
                builder: (context, libState) {
                  final liked = libState.isFavorite(track.id);
                  return IconButton(
                    tooltip: liked ? 'Remove from Liked' : 'Add to Liked',
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      liked ? Icons.favorite : Icons.favorite_border,
                      color: liked
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onPressed: () =>
                        context.read<LibraryCubit>().toggleFavorite(track),
                  );
                },
              ),
              if (isCurrent)
                StreamBuilder<({bool playing, bool loading})>(
                  stream: playerService.playbackStream,
                  builder: (context, snapshot) {
                    final playing = snapshot.data?.playing ?? false;
                    final loading = snapshot.data?.loading ?? false;
                    if (loading) {
                      return const SizedBox(
                        width: 32,
                        height: 32,
                        child: Padding(
                          padding: EdgeInsets.all(6),
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      );
                    }
                    return IconButton(
                      iconSize: 32,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        playing ? Icons.pause_circle : Icons.play_circle,
                      ),
                      onPressed: playerService.togglePlayPause,
                    );
                  },
                )
              else
                const Icon(Icons.play_arrow),
            ],
          ),
          onTap: () {
            if (isCurrent) {
              NowPlayingPage.open(context, playerService);
            } else {
              playerService.playPlaylist(tracks, index);
            }
          },
        );
      },
    );
  }
}
