import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/presentation/cubit/library_cubit.dart';
import 'package:musicc/presentation/cubit/library_state.dart';
import 'package:musicc/presentation/pages/now_playing_page.dart';
import 'package:musicc/presentation/services/music_player_service.dart';

/// The persistent floating mini-player. A slim progress line sits on top;
/// tapping the track info expands it into the full-screen [NowPlayingPage].
class NowPlayingBar extends StatelessWidget {
  final MusicPlayerService playerService;

  const NowPlayingBar({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: playerService.currentIndex,
      builder: (context, currentIndex, _) {
        final Track? track = playerService.currentTrack;
        if (track == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Material(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => NowPlayingPage.open(context, playerService),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
                    child: Row(
                      children: [
                        Hero(
                          tag: 'nowPlayingArt',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: track.imageUrl,
                              width: 46,
                              height: 46,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                width: 46,
                                height: 46,
                                color: AppColors.elevated,
                                child: const Icon(Icons.music_note,
                                    color: Colors.white54),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                track.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                track.artistName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        BlocBuilder<LibraryCubit, LibraryState>(
                          builder: (context, libState) {
                            final liked = libState.isFavorite(track.id);
                            return IconButton(
                              visualDensity: VisualDensity.compact,
                              icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color: liked
                                    ? AppColors.like
                                    : AppColors.textMuted,
                                size: 22,
                              ),
                              onPressed: () => context
                                  .read<LibraryCubit>()
                                  .toggleFavorite(track),
                            );
                          },
                        ),
                        StreamBuilder<({bool playing, bool loading})>(
                          stream: playerService.playbackStream,
                          builder: (context, snapshot) {
                            final playing = snapshot.data?.playing ?? false;
                            final loading = snapshot.data?.loading ?? false;
                            return Container(
                              width: 40,
                              height: 40,
                              margin: const EdgeInsets.only(right: 2),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.textPrimary,
                              ),
                              child: loading
                                  ? const Padding(
                                      padding: EdgeInsets.all(11),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.black54,
                                      ),
                                    )
                                  : IconButton(
                                      iconSize: 24,
                                      padding: EdgeInsets.zero,
                                      color: Colors.black,
                                      icon: Icon(
                                        playing
                                            ? Icons.pause
                                            : Icons.play_arrow,
                                      ),
                                      onPressed:
                                          playerService.togglePlayPause,
                                    ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  _ProgressLine(playerService: playerService),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProgressLine extends StatelessWidget {
  final MusicPlayerService playerService;

  const _ProgressLine({required this.playerService});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: playerService.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: playerService.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final double progress = duration.inMilliseconds <= 0
                ? 0
                : (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0);
            return LinearProgressIndicator(
              value: progress,
              minHeight: 2.5,
              color: AppColors.accent,
              backgroundColor: AppColors.divider,
            );
          },
        );
      },
    );
  }
}
