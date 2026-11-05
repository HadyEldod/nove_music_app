import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/presentation/cubit/lyrics_cubit.dart';
import 'package:musicc/presentation/cubit/lyrics_state.dart';
import 'package:musicc/presentation/services/music_player_service.dart';
import 'package:musicc/presentation/widgets/equalizer_bars.dart';

/// Full-screen scrolling lyrics view. The current line is highlighted and
/// auto-scrolled based on how far playback has progressed through the track.
class LyricsPage extends StatelessWidget {
  final MusicPlayerService playerService;

  const LyricsPage({super.key, required this.playerService});

  static Future<void> open(
    BuildContext context,
    MusicPlayerService playerService,
  ) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LyricsPage(playerService: playerService),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: playerService.currentIndex,
      builder: (context, _, _) {
        final track = playerService.currentTrack;
        if (track == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          });
          return const SizedBox.shrink();
        }
        return _LyricsView(playerService: playerService, track: track);
      },
    );
  }
}

class _LyricsView extends StatefulWidget {
  final MusicPlayerService playerService;
  final Track track;

  const _LyricsView({required this.playerService, required this.track});

  @override
  State<_LyricsView> createState() => _LyricsViewState();
}

class _LyricsViewState extends State<_LyricsView> {
  final ScrollController _scrollController = ScrollController();
  List<GlobalKey> _lineKeys = const [];
  int _lastScrolledLine = -1;

  @override
  void initState() {
    super.initState();
    _loadLyrics();
  }

  @override
  void didUpdateWidget(covariant _LyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.track.id != widget.track.id) {
      _lastScrolledLine = -1;
      _loadLyrics();
    }
  }

  void _loadLyrics() {
    context.read<LyricsCubit>().load(
          artist: widget.track.artistName,
          title: widget.track.name,
        );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Scrolls the active line towards the upper third of the viewport.
  void _scrollToLine(int lineIndex) {
    if (lineIndex == _lastScrolledLine) return;
    if (lineIndex < 0 || lineIndex >= _lineKeys.length) return;
    _lastScrolledLine = lineIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _lineKeys[lineIndex].currentContext;
      if (ctx == null) return;
      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        alignment: 0.32,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(title: widget.track.name),
            _TrackCard(
              track: widget.track,
              playerService: widget.playerService,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: BlocBuilder<LyricsCubit, LyricsState>(
                builder: (context, state) {
                  if (state is LyricsLoading || state is LyricsInitial) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.accent),
                    );
                  }
                  if (state is LyricsEmpty) {
                    return _EmptyLyrics(onRetry: _loadLyrics);
                  }
                  if (state is LyricsLoaded) {
                    return _LyricsList(
                      lines: state.lines,
                      scrollController: _scrollController,
                      playerService: widget.playerService,
                      onKeys: (keys) => _lineKeys = keys,
                      onCurrentLine: _scrollToLine,
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            _SeekBar(playerService: widget.playerService),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;

  const _TopBar({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Row(
        children: [
          _CircleButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.of(context).maybePop(),
          ),
          const Expanded(
            child: Text(
              'Now Playing',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          _CircleButton(
            icon: Icons.more_horiz,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  final Track track;
  final MusicPlayerService playerService;

  const _TrackCard({required this.track, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: track.imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: 48,
                height: 48,
                color: AppColors.elevated,
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          StreamBuilder<({bool playing, bool loading})>(
            stream: playerService.playbackStream,
            builder: (context, snapshot) {
              final playing = snapshot.data?.playing ?? false;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: EqualizerBars(
                  playing: playing,
                  color: AppColors.accent,
                  height: 22,
                  barCount: 5,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LyricsList extends StatelessWidget {
  final List<String> lines;
  final ScrollController scrollController;
  final MusicPlayerService playerService;
  final ValueChanged<List<GlobalKey>> onKeys;
  final ValueChanged<int> onCurrentLine;

  const _LyricsList({
    required this.lines,
    required this.scrollController,
    required this.playerService,
    required this.onKeys,
    required this.onCurrentLine,
  });

  @override
  Widget build(BuildContext context) {
    final keys = List<GlobalKey>.generate(lines.length, (_) => GlobalKey());
    onKeys(keys);

    // Indices of non-blank lines — used to map playback progress to a line.
    final contentIndices = <int>[
      for (var i = 0; i < lines.length; i++)
        if (lines[i].isNotEmpty) i,
    ];

    return StreamBuilder<Duration?>(
      stream: playerService.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: playerService.positionStream,
          builder: (context, positionSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final fraction = duration.inMilliseconds <= 0
                ? 0.0
                : (position.inMilliseconds / duration.inMilliseconds)
                    .clamp(0.0, 1.0);

            int currentLine = -1;
            if (contentIndices.isNotEmpty) {
              final pos = (fraction * contentIndices.length)
                  .floor()
                  .clamp(0, contentIndices.length - 1);
              currentLine = contentIndices[pos];
              onCurrentLine(currentLine);
            }

            return ListView.builder(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              itemCount: lines.length,
              itemBuilder: (context, index) {
                final line = lines[index];
                if (line.isEmpty) {
                  return const SizedBox(height: 18);
                }
                final isCurrent = index == currentLine;
                final isPast = currentLine >= 0 && index < currentLine;
                return Padding(
                  key: keys[index],
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 250),
                    style: TextStyle(
                      fontSize: isCurrent ? 21 : 18,
                      height: 1.3,
                      fontWeight:
                          isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? AppColors.textPrimary
                          : isPast
                              ? AppColors.textMuted
                              : AppColors.textSecondary,
                    ),
                    child: Text(line),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _EmptyLyrics extends StatelessWidget {
  final VoidCallback onRetry;

  const _EmptyLyrics({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lyrics_outlined, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          const Text(
            'No lyrics found for this track',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: AppColors.accent),
            label: const Text(
              'Try again',
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SeekBar extends StatelessWidget {
  final MusicPlayerService playerService;

  const _SeekBar({required this.playerService});

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: playerService.durationStream,
      builder: (context, durationSnapshot) {
        final duration = durationSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration>(
          stream: playerService.positionStream,
          builder: (context, positionSnapshot) {
            var position = positionSnapshot.data ?? Duration.zero;
            if (position > duration) position = duration;
            final double maxMs = duration.inMilliseconds <= 0
                ? 1.0
                : duration.inMilliseconds.toDouble();
            final double value =
                position.inMilliseconds.toDouble().clamp(0.0, maxMs);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      overlayShape:
                          const RoundSliderOverlayShape(overlayRadius: 12),
                    ),
                    child: Slider(
                      value: value,
                      max: maxMs,
                      onChanged: (v) =>
                          playerService.seek(Duration(milliseconds: v.toInt())),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _format(position),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          _format(duration),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
