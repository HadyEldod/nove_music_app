import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/album.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/library_cubit.dart';
import 'package:musicc/presentation/cubit/library_state.dart';
import 'package:musicc/presentation/cubit/music_state.dart';
import 'package:musicc/presentation/cubit/track_list_cubit.dart';
import 'package:musicc/presentation/pages/now_playing_page.dart';
import 'package:musicc/presentation/services/music_player_service.dart';
import 'package:musicc/presentation/widgets/now_playing_bar.dart';

class AlbumDetailPage extends StatelessWidget {
  final Album album;
  final MusicPlayerService playerService;

  const AlbumDetailPage({
    super.key,
    required this.album,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MusicRepository>();
    return BlocProvider(
      create: (_) =>
          TrackListCubit(() => repository.getAlbumTracks(album.id))..load(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<TrackListCubit, MusicState>(
          builder: (context, state) {
            final tracks =
                state is MusicSuccess ? state.tracks : const <Track>[];
            return _AlbumBody(
              album: album,
              tracks: tracks,
              loading: state is MusicLoading || state is MusicInitial,
              playerService: playerService,
            );
          },
        ),
        bottomNavigationBar: NowPlayingBar(playerService: playerService),
      ),
    );
  }
}

class _AlbumBody extends StatefulWidget {
  final Album album;
  final List<Track> tracks;
  final bool loading;
  final MusicPlayerService playerService;

  const _AlbumBody({
    required this.album,
    required this.tracks,
    required this.loading,
    required this.playerService,
  });

  @override
  State<_AlbumBody> createState() => _AlbumBodyState();
}

class _AlbumBodyState extends State<_AlbumBody> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final album = widget.album;
    final tracks = widget.tracks;
    final year =
        album.releaseDate.length >= 4 ? album.releaseDate.substring(0, 4) : '';
    final subtitle = [
      if (year.isNotEmpty) year,
      '${tracks.length} ${tracks.length == 1 ? 'song' : 'songs'}',
    ].join('  ·  ');

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _CircleButton(
                icon: Icons.arrow_back_ios_new,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(
              imageUrl: album.imageUrl,
              width: 230,
              height: 230,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 230,
                height: 230,
                color: AppColors.card,
                child: const Icon(Icons.album, size: 64, color: Colors.white24),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            album.name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _PlayAlbumButton(
                  onTap: tracks.isEmpty
                      ? null
                      : () => widget.playerService.playPlaylist(tracks, 0),
                ),
              ),
              const SizedBox(width: 12),
              _CircleButton(
                icon: _saved ? Icons.favorite : Icons.favorite_border,
                iconColor: _saved ? AppColors.like : AppColors.textPrimary,
                size: 52,
                onTap: () => setState(() => _saved = !_saved),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else
          for (var i = 0; i < tracks.length; i++)
            _AlbumTrackRow(
              number: i + 1,
              tracks: tracks,
              index: i,
              playerService: widget.playerService,
            ),
      ],
    );
  }
}

class _PlayAlbumButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _PlayAlbumButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.elevated : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: Colors.black, size: 22),
            SizedBox(width: 6),
            Text(
              'Play album',
              style: TextStyle(
                color: Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumTrackRow extends StatelessWidget {
  final int number;
  final List<Track> tracks;
  final int index;
  final MusicPlayerService playerService;

  const _AlbumTrackRow({
    required this.number,
    required this.tracks,
    required this.index,
    required this.playerService,
  });

  Track get track => tracks[index];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: playerService.currentIndex,
      builder: (context, _, _) {
        final isCurrent = playerService.currentTrack?.id == track.id;
        return InkWell(
          onTap: () {
            if (isCurrent) {
              NowPlayingPage.open(context, playerService);
            } else {
              playerService.playPlaylist(tracks, index);
            }
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 26,
                      child: isCurrent
                          ? const Icon(Icons.equalizer,
                              color: AppColors.accent, size: 18)
                          : Text(
                              '$number',
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 15,
                              ),
                            ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            track.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent
                                  ? AppColors.accent
                                  : AppColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 3),
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
                    if (track.durationText.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        track.durationText,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(width: 4),
                    BlocBuilder<LibraryCubit, LibraryState>(
                      builder: (context, lib) {
                        final liked = lib.isFavorite(track.id);
                        return PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              color: AppColors.textMuted, size: 20),
                          color: AppColors.elevated,
                          onSelected: (v) {
                            if (v == 'like') {
                              context.read<LibraryCubit>().toggleFavorite(track);
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'like',
                              child: Text(
                                liked ? 'Remove from Liked' : 'Add to Liked',
                                style: const TextStyle(
                                    color: AppColors.textPrimary),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(
                height: 1,
                color: AppColors.divider,
                indent: 20,
                endIndent: 20,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.iconColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(
        side: BorderSide(color: AppColors.divider),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
