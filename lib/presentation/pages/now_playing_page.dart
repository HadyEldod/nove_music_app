import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/presentation/cubit/library_cubit.dart';
import 'package:musicc/presentation/cubit/library_state.dart';
import 'package:musicc/presentation/pages/equalizer_page.dart';
import 'package:musicc/presentation/pages/lyrics_page.dart';
import 'package:musicc/presentation/services/music_player_service.dart';
import 'package:musicc/presentation/widgets/queue_sheet.dart';

/// Full-screen player, shown when the user taps the mini now-playing bar
/// or re-selects the track that is already playing.
class NowPlayingPage extends StatelessWidget {
  final MusicPlayerService playerService;

  const NowPlayingPage({super.key, required this.playerService});

  static Future<void> open(
    BuildContext context,
    MusicPlayerService playerService,
  ) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        pageBuilder: (context, animation, secondaryAnimation) =>
            NowPlayingPage(playerService: playerService),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final offset = Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return SlideTransition(position: offset, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: playerService.currentIndex,
      builder: (context, index, child) {
        final Track? track = playerService.currentTrack;

        // Nothing loaded (e.g. playlist stopped) — just close.
        if (track == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          });
          return const SizedBox.shrink();
        }

        return _DragToDismiss(
          child: Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            fit: StackFit.expand,
            children: [
              _BlurredBackdrop(imageUrl: track.imageUrl),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      _TopBar(playerService: playerService),
                      const Spacer(flex: 2),
                      // Large album art with a soft shadow + hero from the bar.
                      Hero(
                        tag: 'nowPlayingArt',
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 40,
                                  offset: const Offset(0, 16),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: CachedNetworkImage(
                                imageUrl: track.imageUrl,
                                fit: BoxFit.cover,
                                errorWidget: (context, url, error) => Container(
                                  color: Colors.white24,
                                  child: const Icon(
                                    Icons.music_note,
                                    size: 96,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const Spacer(flex: 2),
                      _TitleRow(track: track),
                      const Spacer(flex: 1),
                      _SeekBar(playerService: playerService),
                      const SizedBox(height: 16),
                      _Controls(playerService: playerService),
                      const Spacer(flex: 1),
                      _BottomBar(playerService: playerService, track: track),
                      const Spacer(flex: 1),
                    ],
                  ),
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

/// Lets the user swipe the full-screen player down to dismiss it — the page
/// follows the finger and pops once dragged far or flung downward, otherwise
/// it springs back. The screen behind shows through the opened gap.
class _DragToDismiss extends StatefulWidget {
  final Widget child;

  const _DragToDismiss({required this.child});

  @override
  State<_DragToDismiss> createState() => _DragToDismissState();
}

class _DragToDismissState extends State<_DragToDismiss>
    with SingleTickerProviderStateMixin {
  double _offset = 0;
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 240),
  );

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    _settle.stop();
    setState(() {
      _offset = (_offset + d.delta.dy).clamp(0.0, double.infinity);
    });
  }

  void _onEnd(DragEndDetails d) {
    final height = MediaQuery.of(context).size.height;
    final velocity = d.velocity.pixelsPerSecond.dy;
    final dismiss = _offset > height * 0.2 || velocity > 800;
    _animateTo(
      dismiss ? height : 0.0,
      onDone: dismiss ? () => Navigator.of(context).maybePop() : null,
    );
  }

  void _animateTo(double target, {VoidCallback? onDone}) {
    final anim = Tween<double>(begin: _offset, end: target).animate(
      CurvedAnimation(parent: _settle, curve: Curves.easeOut),
    );
    void listener() => setState(() => _offset = anim.value);
    anim.addListener(listener);
    _settle.forward(from: 0).whenComplete(() {
      anim.removeListener(listener);
      onDone?.call();
    });
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    // Fade + round the top as the page is dragged away.
    final progress = (_offset / (height * 0.5)).clamp(0.0, 1.0);
    final radius = (_offset.clamp(0.0, 28.0));
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: _onUpdate,
      onVerticalDragEnd: _onEnd,
      child: Transform.translate(
        offset: Offset(0, _offset),
        child: Opacity(
          opacity: 1 - progress * 0.4,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Full-bleed blurred album art with a dark gradient scrim for legibility.
class _BlurredBackdrop extends StatelessWidget {
  final String imageUrl;

  const _BlurredBackdrop({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) =>
              const ColoredBox(color: AppColors.background),
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 55, sigmaY: 55),
          child: const ColoredBox(color: Colors.black54),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.35),
                AppColors.background.withValues(alpha: 0.85),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final MusicPlayerService playerService;

  const _TopBar({required this.playerService});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new,
          iconSize: 18,
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
          icon: Icons.more_horiz_outlined,
          iconSize: 20,
          onTap: () => _showMoreSheet(context, playerService),
        ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final Track track;

  const _TitleRow({required this.track});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                track.name,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              Text(
                track.artistName,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        BlocBuilder<LibraryCubit, LibraryState>(
          builder: (context, state) {
            final liked = state.isFavorite(track.id);
            return IconButton(
              iconSize: 30,
              onPressed: () =>
                  context.read<LibraryCubit>().toggleFavorite(track),
              icon: Icon(
                liked ? Icons.favorite : Icons.favorite_border,
                color: liked ? AppColors.like : AppColors.textPrimary,
              ),
            );
          },
        ),
      ],
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
            final remaining = duration - position;
            return Column(
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.divider,
                    thumbColor: AppColors.textPrimary,
                  ),
                  child: Slider(
                    value: value,
                    max: maxMs,
                    onChanged: (v) => playerService.seek(
                      Duration(milliseconds: v.toInt()),
                    ),
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
                        '-${_format(remaining)}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _Controls extends StatelessWidget {
  final MusicPlayerService playerService;

  const _Controls({required this.playerService});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        IconButton(
          iconSize: 42,
          color: AppColors.textPrimary,
          icon: const Icon(Icons.skip_previous),
          onPressed: playerService.canSkip ? playerService.previous : null,
          disabledColor: AppColors.textMuted,
        ),
        StreamBuilder<({bool playing, bool loading})>(
          stream: playerService.playbackStream,
          builder: (context, snapshot) {
            final playing = snapshot.data?.playing ?? false;
            final loading = snapshot.data?.loading ?? false;
            return Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.textPrimary,
              ),
              child: loading
                  ? const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: Colors.black54,
                      ),
                    )
                  : IconButton(
                      iconSize: 42,
                      color: Colors.black,
                      icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                      onPressed: playerService.togglePlayPause,
                    ),
            );
          },
        ),
        IconButton(
          iconSize: 42,
          color: AppColors.textPrimary,
          icon: const Icon(Icons.skip_next),
          onPressed: playerService.canSkip ? () => playerService.next() : null,
          disabledColor: AppColors.textMuted,
        ),
      ],
    );
  }
}

/// The bottom row: shuffle (left), a pill showing the track name that opens the
/// lyrics view (center), and repeat (right).
class _BottomBar extends StatelessWidget {
  final MusicPlayerService playerService;
  final Track track;

  const _BottomBar({required this.playerService, required this.track});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ValueListenableBuilder<bool>(
          valueListenable: playerService.shuffle,
          builder: (context, shuffleOn, _) {
            return IconButton(
              tooltip: 'Shuffle',
              icon: const Icon(Icons.shuffle),
              color: shuffleOn ? AppColors.accent : AppColors.textSecondary,
              onPressed: playerService.toggleShuffle,
            );
          },
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => LyricsPage.open(context, playerService),
            child: Container(
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(23),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Text(
                track.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Equalizer',
          color: AppColors.textSecondary,
          icon: const Icon(Icons.tune),
          onPressed: () => EqualizerPage.open(context, playerService),
        ),
      ],
    );
  }
}

/// "More" sheet from the top-right button: repeat, queue and equalizer.
void _showMoreSheet(BuildContext context, MusicPlayerService playerService) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ValueListenableBuilder<RepeatMode>(
            valueListenable: playerService.repeatMode,
            builder: (context, mode, _) => ListTile(
              leading: Icon(
                mode == RepeatMode.one ? Icons.repeat_one : Icons.repeat,
                color: mode == RepeatMode.off
                    ? AppColors.textSecondary
                    : AppColors.accent,
              ),
              title: Text(
                'Repeat: ${mode.name}',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              onTap: playerService.cycleRepeatMode,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.queue_music,
                color: AppColors.textSecondary),
            title: const Text('Queue',
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.of(sheetContext).pop();
              showQueueSheet(context, playerService);
            },
          ),
          ListTile(
            leading: const Icon(Icons.tune, color: AppColors.textSecondary),
            title: const Text('Equalizer & sound',
                style: TextStyle(color: AppColors.textPrimary)),
            onTap: () {
              Navigator.of(sheetContext).pop();
              EqualizerPage.open(context, playerService);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

class _CircleButton extends StatelessWidget {
  final IconData icon;
  final double iconSize;
  final VoidCallback onTap;

  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: iconSize, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}
