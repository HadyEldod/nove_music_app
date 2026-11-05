import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/library_cubit.dart';
import 'package:musicc/presentation/cubit/library_state.dart';
import 'package:musicc/presentation/cubit/music_state.dart';
import 'package:musicc/presentation/cubit/track_list_cubit.dart';
import 'package:musicc/presentation/pages/now_playing_page.dart';
import 'package:musicc/presentation/services/music_player_service.dart';
import 'package:musicc/presentation/widgets/now_playing_bar.dart';

class PlaylistDetailPage extends StatelessWidget {
  final String playlistId;
  final String playlistName;
  final String userName;
  final MusicPlayerService playerService;

  const PlaylistDetailPage({
    super.key,
    required this.playlistId,
    required this.playlistName,
    required this.userName,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MusicRepository>();
    return BlocProvider(
      create: (_) =>
          TrackListCubit(() => repository.getPlaylistTracks(playlistId))..load(),
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: BlocBuilder<TrackListCubit, MusicState>(
          builder: (context, state) {
            final tracks =
                state is MusicSuccess ? state.tracks : const <Track>[];
            return _PlaylistBody(
              name: playlistName,
              userName: userName,
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

class _PlaylistBody extends StatefulWidget {
  final String name;
  final String userName;
  final List<Track> tracks;
  final bool loading;
  final MusicPlayerService playerService;

  const _PlaylistBody({
    required this.name,
    required this.userName,
    required this.tracks,
    required this.loading,
    required this.playerService,
  });

  @override
  State<_PlaylistBody> createState() => _PlaylistBodyState();
}

class _PlaylistBodyState extends State<_PlaylistBody> {
  final TextEditingController _search = TextEditingController();
  bool _sortAZ = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Track> get _visible {
    final q = _search.text.trim().toLowerCase();
    var list = widget.tracks;
    if (q.isNotEmpty) {
      list = list
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.artistName.toLowerCase().contains(q))
          .toList();
    }
    if (_sortAZ) {
      list = [...list]..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final maker =
        widget.userName.isEmpty ? 'NOVA' : widget.userName.toUpperCase();
    final visible = _visible;

    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                _CircleButton(
                  icon: Icons.arrow_back_ios_new,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                const Expanded(
                  child: Text(
                    'YOUR PLAYLIST',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                const SizedBox(width: 42),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Title block: gradient icon + maker + name.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF9B6BFF), Color(0xFF6D28D9)],
                  ),
                ),
                child: const Icon(Icons.queue_music,
                    color: Colors.white, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'MADE BY $maker',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 11,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            '${widget.tracks.length} ${widget.tracks.length == 1 ? 'song' : 'songs'} · tap to play',
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        // Search inside the playlist.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: TextField(
            controller: _search,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Find a song in the playlist',
              hintStyle: const TextStyle(color: AppColors.textMuted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _search.text.isEmpty
                  ? const Icon(Icons.mic_none, color: AppColors.textMuted)
                  : IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.textMuted),
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(26),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Play all · shuffle · sort.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _PlayAllButton(
                onTap: widget.tracks.isEmpty
                    ? null
                    : () => widget.playerService.playPlaylist(widget.tracks, 0),
              ),
              const SizedBox(width: 12),
              ValueListenableBuilder<bool>(
                valueListenable: widget.playerService.shuffle,
                builder: (context, on, _) => _CircleButton(
                  icon: Icons.shuffle,
                  iconColor: on ? AppColors.accent : AppColors.textPrimary,
                  onTap: widget.playerService.toggleShuffle,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _sortAZ = !_sortAZ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sort,
                          size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        _sortAZ ? 'A–Z' : 'Recent',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Your tracks',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Adding songs isn\'t available for '
                        'Jamendo playlists.'),
                  ),
                ),
                child: const Text(
                  '+ Add songs',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (widget.loading)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          )
        else if (widget.tracks.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: _EmptyPlaylistCard(
              onFindSongs: () => Navigator.of(context).maybePop(),
            ),
          )
        else if (visible.isEmpty)
          const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No results',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          for (var i = 0; i < visible.length; i++)
            _PlaylistTrackRow(
              tracks: visible,
              index: i,
              playerService: widget.playerService,
            ),
      ],
    );
  }
}

class _PlayAllButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _PlayAllButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.elevated : Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, color: Colors.black, size: 20),
            SizedBox(width: 6),
            Text(
              'Play all',
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistTrackRow extends StatelessWidget {
  final List<Track> tracks;
  final int index;
  final MusicPlayerService playerService;

  const _PlaylistTrackRow({
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
                          child: const Icon(Icons.music_note,
                              color: Colors.white54),
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
                        return IconButton(
                          visualDensity: VisualDensity.compact,
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            color: liked ? AppColors.like : AppColors.textMuted,
                            size: 22,
                          ),
                          onPressed: () =>
                              context.read<LibraryCubit>().toggleFavorite(track),
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

/// Empty-playlist state: a dashed card nudging the user to add songs.
class _EmptyPlaylistCard extends StatelessWidget {
  final VoidCallback onFindSongs;

  const _EmptyPlaylistCard({required this.onFindSongs});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedRectPainter(
        radius: 20,
        color: Colors.white.withValues(alpha: 0.2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          children: [
            const Icon(Icons.music_note, color: AppColors.accent, size: 40),
            const SizedBox(height: 14),
            const Text(
              'Every playlist starts with one song.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add a few favorites to make this space yours.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: onFindSongs,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Text(
                  'FIND SONGS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final double radius;
  final Color color;

  _DashedRectPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final source = Path()..addRRect(rrect);
    final dashed = Path();
    for (final metric in source.computeMetrics()) {
      var dist = 0.0;
      while (dist < metric.length) {
        dashed.addPath(metric.extractPath(dist, dist + 6), Offset.zero);
        dist += 11; // 6px dash + 5px gap
      }
    }
    canvas.drawPath(dashed, paint);
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) =>
      old.radius != radius || old.color != color;
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(side: BorderSide(color: AppColors.divider)),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
