import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/artist.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/music_state.dart';
import 'package:musicc/presentation/cubit/track_list_cubit.dart';
import 'package:musicc/presentation/pages/now_playing_page.dart';
import 'package:musicc/presentation/services/music_player_service.dart';
import 'package:musicc/presentation/widgets/now_playing_bar.dart';

class ArtistPage extends StatefulWidget {
  final String artistId;
  final String artistName;
  final MusicPlayerService playerService;

  const ArtistPage({
    super.key,
    required this.artistId,
    required this.artistName,
    required this.playerService,
  });

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  late final MusicRepository _repository = context.read<MusicRepository>();
  late final Future<Artist?> _artistFuture =
      _repository.getArtist(widget.artistId);
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) =>
          TrackListCubit(() => _repository.getArtistTracks(widget.artistId))
            ..load(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<TrackListCubit, MusicState>(
          builder: (context, state) {
            final tracks = state is MusicSuccess ? state.tracks : <Track>[];
            return FutureBuilder<Artist?>(
              future: _artistFuture,
              builder: (context, snapshot) {
                final imageUrl = snapshot.data?.imageUrl ??
                    (tracks.isNotEmpty ? tracks.first.imageUrl : '');
                return _ArtistBody(
                  artistName: widget.artistName,
                  imageUrl: imageUrl,
                  tracks: tracks,
                  loading: state is MusicLoading || state is MusicInitial,
                  playerService: widget.playerService,
                  following: _following,
                  onToggleFollow: () =>
                      setState(() => _following = !_following),
                );
              },
            );
          },
        ),
        bottomNavigationBar:
            NowPlayingBar(playerService: widget.playerService),
      ),
    );
  }
}

class _ArtistBody extends StatelessWidget {
  final String artistName;
  final String imageUrl;
  final List<Track> tracks;
  final bool loading;
  final MusicPlayerService playerService;
  final bool following;
  final VoidCallback onToggleFollow;

  const _ArtistBody({
    required this.artistName,
    required this.imageUrl,
    required this.tracks,
    required this.loading,
    required this.playerService,
    required this.following,
    required this.onToggleFollow,
  });

  @override
  Widget build(BuildContext context) {
    // Unique albums derived from the artist's tracks (name + a cover).
    final albums = <String, Track>{};
    for (final t in tracks) {
      if (t.albumName.isNotEmpty) albums.putIfAbsent(t.albumName, () => t);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _Hero(artistName: artistName, imageUrl: imageUrl, trackCount: tracks.length),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: _PlayButton(
                  onTap: tracks.isEmpty
                      ? null
                      : () => playerService.playPlaylist(tracks, 0),
                ),
              ),
              const SizedBox(width: 12),
              _FollowButton(following: following, onTap: onToggleFollow),
            ],
          ),
        ),
        if (loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else ...[
          _SectionHeader(
            title: 'Songs',
            trailing: tracks.isEmpty
                ? null
                : '${tracks.length} RESULTS',
          ),
          for (var i = 0; i < tracks.length && i < 20; i++)
            _SongRow(
              tracks: tracks,
              index: i,
              playerService: playerService,
            ),
          if (albums.isNotEmpty) ...[
            const SizedBox(height: 8),
            const _SectionHeader(title: 'Album'),
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                itemCount: albums.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final entry = albums.entries.elementAt(i);
                  return _AlbumCard(
                    name: entry.key,
                    imageUrl: entry.value.imageUrl,
                    onTap: () {
                      final albumTracks = tracks
                          .where((t) => t.albumName == entry.key)
                          .toList();
                      if (albumTracks.isNotEmpty) {
                        playerService.playPlaylist(albumTracks, 0);
                      }
                    },
                  );
                },
              ),
            ),
          ],
        ],
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  final String artistName;
  final String imageUrl;
  final int trackCount;

  const _Hero({
    required this.artistName,
    required this.imageUrl,
    required this.trackCount,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 360,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (imageUrl.isNotEmpty)
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) =>
                  const ColoredBox(color: AppColors.card),
            )
          else
            const ColoredBox(color: AppColors.card),
          // Fade to the background colour at the bottom.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Color(0x3309090B),
                  AppColors.background,
                ],
                stops: [0.3, 0.6, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Align(
                alignment: Alignment.topLeft,
                child: Material(
                  color: Colors.black.withValues(alpha: 0.35),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).maybePop(),
                    child: const SizedBox(
                      width: 42,
                      height: 42,
                      child: Icon(Icons.arrow_back_ios_new,
                          size: 18, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'VERIFIED ARTIST',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  artistName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  trackCount == 1 ? '1 song' : '$trackCount songs',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _PlayButton({required this.onTap});

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
              'Play',
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

class _FollowButton extends StatelessWidget {
  final bool following;
  final VoidCallback onTap;

  const _FollowButton({required this.following, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 28),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: following ? AppColors.accent : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Text(
          following ? 'Following' : 'Follow',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }
}

class _SongRow extends StatelessWidget {
  final List<Track> tracks;
  final int index;
  final MusicPlayerService playerService;

  const _SongRow({
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: track.imageUrl,
                    width: 46,
                    height: 46,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => Container(
                      width: 46,
                      height: 46,
                      color: AppColors.card,
                      child: const Icon(Icons.music_note, color: Colors.white54),
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
                        track.durationText.isEmpty
                            ? track.artistName
                            : '${track.artistName} · ${track.durationText}',
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
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: 0.18),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Icon(
                    isCurrent ? Icons.equalizer : Icons.play_arrow,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _AlbumCard({
    required this.name,
    required this.imageUrl,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 140,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: 140,
                height: 140,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  width: 140,
                  height: 140,
                  color: AppColors.card,
                  child: const Icon(Icons.album, color: Colors.white24),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
