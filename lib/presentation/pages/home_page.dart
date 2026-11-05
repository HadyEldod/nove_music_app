import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart' show Ticker;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/artist.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/albums_cubit.dart';
import 'package:musicc/presentation/cubit/albums_state.dart';
import 'package:musicc/presentation/cubit/artists_cubit.dart';
import 'package:musicc/presentation/cubit/artists_state.dart';
import 'package:musicc/presentation/cubit/auth_cubit.dart';
import 'package:musicc/presentation/cubit/auth_state.dart';
import 'package:musicc/presentation/cubit/device_music_cubit.dart';
import 'package:musicc/presentation/cubit/device_music_state.dart';
import 'package:musicc/presentation/cubit/library_cubit.dart';
import 'package:musicc/presentation/cubit/library_state.dart';
import 'package:musicc/presentation/cubit/music_cubit.dart';
import 'package:musicc/presentation/cubit/music_state.dart';
import 'package:musicc/presentation/cubit/playlists_cubit.dart';
import 'package:musicc/presentation/cubit/playlists_state.dart';
import 'package:musicc/presentation/pages/artist_page.dart';
import 'package:musicc/presentation/pages/collection_page.dart';
import 'package:musicc/presentation/pages/now_playing_page.dart';
import 'package:musicc/presentation/pages/profile_page.dart';
import 'package:musicc/presentation/services/music_player_service.dart';
import 'package:musicc/presentation/widgets/now_playing_bar.dart';
import 'package:musicc/presentation/widgets/track_tile.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final MusicPlayerService playerService = MusicPlayerService();

  @override
  void initState() {
    super.initState();
    // Record recently-played tracks as playback moves.
    playerService.onTrackPlayed = context.read<LibraryCubit>().recordPlayed;
    // Ask for notification permission (Android 13+) so the media
    // notification can appear. Harmless where not required.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Permission.notification.request();
      } catch (_) {
        // Not available on this platform / in tests — ignore.
      }
    });
  }

  @override
  void dispose() {
    playerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) =>
              PlaylistsCubit(context.read<MusicRepository>())..load(),
        ),
        BlocProvider(
          create: (_) => ArtistsCubit(context.read<MusicRepository>())..load(),
        ),
        BlocProvider(
          create: (_) => AlbumsCubit(context.read<MusicRepository>())..load(),
        ),
        BlocProvider(
          create: (_) => DeviceMusicCubit()..load(),
        ),
      ],
      child: _HomeShell(playerService: playerService),
    );
  }
}

/// Hosts the four bottom-navigation destinations and the floating mini player.
class _HomeShell extends StatefulWidget {
  final MusicPlayerService playerService;

  const _HomeShell({required this.playerService});

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  void _openProfile() => setState(() => _index = 3);

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _HomeFeed(
        playerService: widget.playerService,
        onProfileTap: _openProfile,
      ),
      _SearchTab(playerService: widget.playerService),
      _FavoritesTab(playerService: widget.playerService),
      ProfilePage(playerService: widget.playerService),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _AmbientBackground()),
          IndexedStack(index: _index, children: tabs),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          NowPlayingBar(playerService: widget.playerService),
          _BottomNav(
            index: _index,
            onTap: (i) => setState(() => _index = i),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home feed
// ---------------------------------------------------------------------------

class _HomeFeed extends StatefulWidget {
  final MusicPlayerService playerService;
  final VoidCallback onProfileTap;

  const _HomeFeed({required this.playerService, required this.onProfileTap});

  @override
  State<_HomeFeed> createState() => _HomeFeedState();
}

class _HomeFeedState extends State<_HomeFeed>
    with AutomaticKeepAliveClientMixin {
  static const _categories = ['All', 'New Release', 'Trending', 'Top Listing'];
  // Jamendo `order` values each chip loads, so the list really changes.
  static const _orders = [
    'popularity_total',
    'releasedate_desc',
    'popularity_week',
    'listens_total',
  ];
  int _category = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    context.read<MusicCubit>().getTracks();
  }

  void _openSeeAll() {
    final state = context.read<MusicCubit>().state;
    final tracks = state is MusicSuccess ? state.tracks : <Track>[];
    if (tracks.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _AllTracksPage(
          title: _categories[_category],
          tracks: tracks,
          playerService: widget.playerService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        onRefresh: () async {
          context.read<MusicCubit>().refresh();
          context.read<ArtistsCubit>().load();
        },
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            _GreetingHeader(onProfileTap: widget.onProfileTap),
            const SizedBox(height: 16),
            _CategoryChips(
              categories: _categories,
              selected: _category,
              onSelected: (i) {
                if (i == _category) return;
                setState(() => _category = i);
                context.read<MusicCubit>().setOrder(_orders[i]);
              },
            ),
            const SizedBox(height: 20),
            _ArtistOfDayCarousel(playerService: widget.playerService),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Top daily playlist',
              onSeeAll: _openSeeAll,
            ),
            const SizedBox(height: 4),
            _TopDailyList(playerService: widget.playerService),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  final VoidCallback onProfileTap;

  const _GreetingHeader({required this.onProfileTap});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final user = state is AuthLoggedIn ? state.user : null;
        final name = user?.displayName.isNotEmpty == true
            ? user!.displayName
            : 'there';
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: onProfileTap,
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.card,
                      backgroundImage: user != null && user.imageUrl.isNotEmpty
                          ? CachedNetworkImageProvider(user.imageUrl)
                          : null,
                      child: user == null || user.imageUrl.isEmpty
                          ? const Icon(Icons.person, color: Colors.white70)
                          : null,
                    ),
                  ),
                  const Spacer(),
                  _CircleIconButton(
                    icon: Icons.notifications_none_rounded,
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '${_greeting()}, $name',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 22, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final int selected;
  final ValueChanged<int> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final isSelected = i == selected;
          return GestureDetector(
            onTap: () => onSelected(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(21),
                border: isSelected
                    ? null
                    : Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: Text(
                categories[i],
                style: TextStyle(
                  color: isSelected
                      ? const Color(0xFF212121)
                      : Colors.white.withValues(alpha: 0.6),
                  fontWeight:
                      isSelected ? FontWeight.w500 : FontWeight.w300,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Horizontally paged artist carousel that auto-advances every 2 seconds and
/// scales the centered card up relative to its neighbours.
class _ArtistOfDayCarousel extends StatefulWidget {
  final MusicPlayerService playerService;

  const _ArtistOfDayCarousel({required this.playerService});

  @override
  State<_ArtistOfDayCarousel> createState() => _ArtistOfDayCarouselState();
}

class _ArtistOfDayCarouselState extends State<_ArtistOfDayCarousel> {
  // Start far from 0 so the carousel loops seamlessly in both directions.
  static const int _loopBase = 10000;

  PageController? _controller;
  Timer? _timer;
  double _page = _loopBase.toDouble();

  void _ensureSetup() {
    if (_controller != null) return;
    _controller = PageController(
      viewportFraction: 0.58,
      initialPage: _loopBase,
    )..addListener(() {
        final p = _controller?.page;
        if (p != null) setState(() => _page = p);
      });
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      final c = _controller;
      if (c == null || !c.hasClients) return;
      c.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArtistsCubit, ArtistsState>(
      builder: (context, state) {
        if (state is ArtistsSuccess && state.artists.isNotEmpty) {
          final artists = state.artists.take(8).toList();
          _ensureSetup();
          return SizedBox(
            height: 240,
            child: PageView.builder(
              controller: _controller,
              itemBuilder: (context, index) {
                final artist =
                    artists[((index % artists.length) + artists.length) %
                        artists.length];
                final distance = (_page - index).abs().clamp(0.0, 1.0);
                // Centre card is full size; neighbours shrink to ~0.82.
                final scale = 1.0 - distance * 0.18;
                return Center(
                  child: Transform.scale(
                    scale: scale,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 8,
                      ),
                      child: _ArtistCard(
                        artist: artist,
                        featured: distance < 0.5,
                        playerService: widget.playerService,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        }
        if (state is ArtistsError) {
          return const SizedBox(
            height: 240,
            child: Center(
              child: Text(
                'Could not load artists',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ),
          );
        }
        return const SizedBox(
          height: 240,
          child: Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          ),
        );
      },
    );
  }
}

class _ArtistCard extends StatelessWidget {
  final Artist artist;
  final bool featured;
  final MusicPlayerService playerService;

  const _ArtistCard({
    required this.artist,
    required this.featured,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ArtistPage(
            artistId: artist.id,
            artistName: artist.name,
            playerService: playerService,
          ),
        ),
      ),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.6),
            width: 0.9,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.42),
              blurRadius: 50,
              offset: const Offset(0, 24),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: artist.imageUrl,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                color: AppColors.card,
                child: const Icon(Icons.person, size: 64,
                    color: Colors.white24),
              ),
            ),
            // Dark scrim: rgba(5,5,11,0.94) at the bottom → transparent at 70%.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Color.fromRGBO(5, 5, 11, 0.94),
                    Color.fromRGBO(5, 5, 11, 0.04),
                  ],
                  stops: [0.0, 0.7],
                ),
              ),
            ),
            // "NOVA LIVE" badge (top-left).
            Positioned(
              left: 12,
              top: 18,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    _Dot(),
                    SizedBox(width: 6),
                    Text(
                      'NOVA LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Centered info (bottom).
            Positioned(
              left: 12,
              right: 12,
              bottom: 18,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Artist of the day',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 10,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.accent,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 21,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: const Text(
                'See all',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopDailyList extends StatelessWidget {
  final MusicPlayerService playerService;

  const _TopDailyList({required this.playerService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MusicCubit, MusicState>(
      builder: (context, state) {
        if (state is MusicSuccess) {
          if (state.tracks.isEmpty) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('No songs found',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            );
          }
          final tracks = state.tracks;
          final top = tracks.take(8).toList();
          return Column(
            children: [
              for (var i = 0; i < top.length; i++)
                _TrackRow(
                  tracks: tracks,
                  index: i,
                  playerService: playerService,
                ),
            ],
          );
        }
        if (state is MusicError) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(
                children: [
                  Text(state.message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textMuted)),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: () => context.read<MusicCubit>().refresh(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: CircularProgressIndicator(color: AppColors.accent)),
        );
      },
    );
  }
}

/// A compact track row for the home feed with artwork, title, artist and a
/// circular play button — tapping anywhere plays the track.
class _TrackRow extends StatelessWidget {
  final List<Track> tracks;
  final int index;
  final MusicPlayerService playerService;

  const _TrackRow({
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 7),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: AppColors.strokeGray,
                      width: 0.9,
                    ),
                  ),
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
                  width: 37,
                  height: 37,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.play_arrow,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Search tab
// ---------------------------------------------------------------------------

class _SearchTab extends StatefulWidget {
  final MusicPlayerService playerService;

  const _SearchTab({required this.playerService});

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();

  // Recent searches persist for the session and populate as the user searches.
  static final List<String> _recent = [];

  static const _popular = [
    'Afrobeats',
    'New releases',
    'Arabic indie',
    'Midnight drive',
    'Acoustic covers',
  ];

  static const _moods = <({String title, String subtitle, List<Color> colors})>[
    (title: 'Chill', subtitle: 'Ease into it',
        colors: [Color(0xFF0E7E7B), Color(0xFFB5295B)]),
    (title: 'Focus', subtitle: 'Clear the noise',
        colors: [Color(0xFF1E3A8A), Color(0xFF6D28D9)]),
    (title: 'Workout', subtitle: 'Turn it up',
        colors: [Color(0xFF6D28D9), Color(0xFFCE33B9)]),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _runSearch(String term) {
    final q = term.trim();
    _searchController.text = q;
    context.read<MusicCubit>().search(q);
    if (q.isNotEmpty) {
      _recent.remove(q);
      _recent.insert(0, q);
      if (_recent.length > 8) _recent.removeLast();
    }
    FocusScope.of(context).unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final hasQuery = _searchController.text.trim().isNotEmpty;
    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: _SearchField(
              controller: _searchController,
              onSubmitted: _runSearch,
              onChanged: () => setState(() {}),
              onClear: () {
                _searchController.clear();
                context.read<MusicCubit>().search('');
                setState(() {});
              },
            ),
          ),
          Expanded(
            child: hasQuery
                ? _buildResults()
                : _buildDiscovery(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    return BlocBuilder<MusicCubit, MusicState>(
      builder: (context, state) {
        if (state is MusicLoading || state is MusicInitial) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.accent),
          );
        }
        if (state is MusicError) {
          return _ErrorView(
            message: state.message,
            onRetry: () => context.read<MusicCubit>().refresh(),
          );
        }
        if (state is MusicSuccess) {
          if (state.tracks.isEmpty) {
            return Center(
              child: Text(
                'No results for "${_searchController.text}"',
                style: const TextStyle(color: AppColors.textMuted),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: state.tracks.length,
            itemBuilder: (context, index) => TrackTile(
              tracks: state.tracks,
              index: index,
              playerService: widget.playerService,
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildDiscovery() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (_recent.isNotEmpty) ...[
          _SearchSectionHeader(
            title: 'Recent searches',
            trailing: GestureDetector(
              onTap: () => setState(_recent.clear),
              child: const Text(
                'CLEAR',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                for (var i = 0; i < _recent.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.divider, indent: 16, endIndent: 16),
                  _RecentRow(
                    term: _recent[i],
                    onTap: () => _runSearch(_recent[i]),
                    onRemove: () => setState(() => _recent.removeAt(i)),
                  ),
                ],
              ],
            ),
          ),
        ],
        const _SearchSectionHeader(title: 'Popular now'),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final term in _popular)
                GestureDetector(
                  onTap: () => _runSearch(term),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      term,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const _SearchSectionHeader(
          title: 'Explore by mood',
          trailing: Icon(Icons.chevron_right, color: AppColors.textMuted),
        ),
        SizedBox(
          height: 130,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            itemCount: _moods.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final mood = _moods[i];
              return GestureDetector(
                onTap: () => _runSearch(mood.title),
                child: Container(
                  width: 150,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: mood.colors,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        mood.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        mood.subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.onSubmitted,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      style: const TextStyle(color: AppColors.textPrimary),
      onSubmitted: onSubmitted,
      onChanged: (_) => onChanged(),
      decoration: InputDecoration(
        hintText: 'What do you want to listen to?',
        hintStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.06),
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        suffixIcon: controller.text.isEmpty
            ? const Icon(Icons.mic_none, color: AppColors.textMuted)
            : IconButton(
                icon: const Icon(Icons.clear, color: AppColors.textMuted),
                onPressed: onClear,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}

class _SearchSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SearchSectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

class _RecentRow extends StatelessWidget {
  final String term;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _RecentRow({
    required this.term,
    required this.onTap,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.history, size: 18, color: AppColors.textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                term,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                ),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close, size: 18,
                  color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Favorites / Library tab
// ---------------------------------------------------------------------------

class _FavoritesTab extends StatelessWidget {
  final MusicPlayerService playerService;

  const _FavoritesTab({required this.playerService});

  void _open(BuildContext context, Widget page) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 2),
            child: Text(
              'Your Library',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 27,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Text(
              'YOUR MUSIC, YOUR WORLD.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          _LibraryCoverStrip(playerService: playerService),
          const SizedBox(height: 18),
          _LibraryStatGrid(playerService: playerService, onOpen: _open),
          const SizedBox(height: 16),
          _ListenAgainCard(playerService: playerService),
          const SizedBox(height: 4),
          // Recently played.
          BlocBuilder<LibraryCubit, LibraryState>(
            builder: (context, state) {
              if (state.recent.isEmpty) return const SizedBox();
              return Column(
                children: [
                  const _LibrarySectionHeader('Recently played'),
                  for (var i = 0; i < state.recent.length; i++)
                    TrackTile(
                      tracks: state.recent,
                      index: i,
                      playerService: playerService,
                    ),
                ],
              );
            },
          ),
          // On-device music (auto-scanned).
          _LibrarySectionHeader(
            'On this device',
            action: IconButton(
              tooltip: 'Rescan',
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: () => context.read<DeviceMusicCubit>().load(),
            ),
          ),
          BlocBuilder<DeviceMusicCubit, DeviceMusicState>(
            builder: (context, state) {
              if (state is DeviceMusicLoading ||
                  state is DeviceMusicInitial) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                );
              }
              if (state is DeviceMusicDenied) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.permanentlyDenied
                            ? 'Audio access is blocked. Open settings and allow '
                                'Music/Audio permission, then rescan.'
                            : 'Allow access to your audio files to play the '
                                'music stored on your phone.',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.tonal(
                        onPressed: state.permanentlyDenied
                            ? () =>
                                context.read<DeviceMusicCubit>().openSettings()
                            : () => context.read<DeviceMusicCubit>().load(),
                        child: Text(
                          state.permanentlyDenied
                              ? 'Open settings'
                              : 'Grant access',
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (state is DeviceMusicError) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                  child: Text(
                    'Could not read device music:\n${state.message}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                );
              }
              if (state is DeviceMusicLoaded) {
                final tracks = state.tracks;
                if (tracks.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'No music found on this device.',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < tracks.length; i++)
                      TrackTile(
                        tracks: tracks,
                        index: i,
                        playerService: playerService,
                      ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}

/// Horizontal strip of recent / liked / album cover art.
class _LibraryCoverStrip extends StatelessWidget {
  final MusicPlayerService playerService;

  const _LibraryCoverStrip({required this.playerService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, lib) {
        final tracks = [...lib.recent, ...lib.favorites];
        final images = <String>[];
        for (final t in tracks) {
          if (t.imageUrl.isNotEmpty && !images.contains(t.imageUrl)) {
            images.add(t.imageUrl);
          }
          if (images.length >= 10) break;
        }
        if (images.isEmpty) {
          // Fall back to album covers so the strip is never empty.
          return BlocBuilder<AlbumsCubit, AlbumsState>(
            builder: (context, state) {
              final albumImages = state is AlbumsSuccess
                  ? state.albums
                      .map((a) => a.imageUrl)
                      .where((u) => u.isNotEmpty)
                      .take(12)
                      .toList()
                  : <String>[];
              return _FannedCovers(images: albumImages);
            },
          );
        }
        return _FannedCovers(images: images);
      },
    );
  }
}

/// A 3D "coverflow" fan of album art on a convex cylinder — the centre cover
/// faces forward and side covers rotate away. Draggable, snaps to a cover.
class _FannedCovers extends StatefulWidget {
  final List<String> images;

  const _FannedCovers({required this.images});

  @override
  State<_FannedCovers> createState() => _FannedCoversState();
}

class _FannedCoversState extends State<_FannedCovers>
    with SingleTickerProviderStateMixin {
  // Continuous (fractional) centre position; grows without bound and wraps
  // over the image list via modulo, so the wall rotates forever.
  double _offset = 0;
  late final Ticker _ticker;
  Duration _lastTick = Duration.zero;
  bool _dragging = false;

  // Drag sensitivity (px of horizontal drag that advances one cover).
  double _dragPerIndex = 70;

  // Furthest a cover turns before it is culled (keeps edges from stacking).
  static const double _maxAngle = 1.0; // ~57°
  // Side covers shrink to this fraction of the centre's height.
  static const double _edgeScale = 0.5;
  // Auto-rotation speed, in covers per second.
  static const double _speed = 0.6;
  // How many covers to render on each side of the centre.
  static const int _half = 4;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    if (_lastTick == Duration.zero) {
      _lastTick = elapsed;
      return;
    }
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (_dragging || widget.images.length < 2) return;
    // Drift the wall so each left-hand poster rotates into the centre
    // (matches the reference animation).
    setState(() => _offset -= _speed * dt);
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails d) {
    _dragging = true;
    setState(() => _offset -= d.primaryDelta! / _dragPerIndex);
  }

  void _onDragEnd(DragEndDetails d) => _dragging = false;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) return const SizedBox(height: 200);
    final n = images.length;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive sizing: the centre poster is large but bounded.
        final coverW = (constraints.maxWidth * 0.30).clamp(110.0, 150.0);
        final coverH = coverW * 1.3;
        // A convex "cylinder wall": [rx] spreads covers across the full width,
        // [rotateY] turns the sides away, and an explicit linear scale shrinks
        // them from the centre (100%) down to [_edgeScale] at the edges so the
        // size gradient is exactly as designed. The whole strip stretches to
        // the available width and rotates continuously.
        final rx = constraints.maxWidth * 0.55;
        const theta = 0.333; // angular step → ~7 covers within ±_maxAngle
        final perspDepth = coverW * 2.5; // foreshortens the rotateY turn
        _dragPerIndex = coverW * 0.6;

        final base = _offset.round();
        final cards = <({double depth, Widget child})>[];
        for (var k = base - _half; k <= base + _half; k++) {
          final delta = k - _offset;
          final angle = delta * theta;
          if (angle.abs() >= _maxAngle) continue;
          final t = (angle.abs() / _maxAngle).clamp(0.0, 1.0);
          final s = 1 - t * (1 - _edgeScale); // centre 1.0 → edges _edgeScale
          final x = rx * math.sin(angle);
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 1 / perspDepth)
            ..translateByDouble(x, delta.abs() * coverH * 0.01, 0.0, 1.0)
            ..rotateY(-angle)
            ..scaleByDouble(s, s, s, 1.0);
          // Each slot [k] always maps to the same poster, so keying by slot
          // keeps that poster's element stable while it animates across.
          final img = images[((k % n) + n) % n];
          cards.add((
            depth: delta.abs(),
            child: Transform(
              key: ValueKey(k),
              alignment: Alignment.center,
              transform: transform,
              child: _cover(img, angle.abs(), coverW, coverH),
            ),
          ));
        }
        // Paint the farthest (largest |delta|) first so the centre sits on top.
        cards.sort((a, b) => b.depth.compareTo(a.depth));

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          onHorizontalDragCancel: () => _dragging = false,
          child: SizedBox(
            height: coverH + 36,
            width: double.infinity,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none, // let side covers recede off-edge
              children: [for (final c in cards) c.child],
            ),
          ),
        );
      },
    );
  }

  Widget _cover(String url, double angle, double w, double h) {
    // Darken + fade covers as they turn away so the centre is the focus.
    final t = (angle / _maxAngle).clamp(0.0, 1.0);
    return Opacity(
      opacity: (1 - t * 0.35).clamp(0.0, 1.0),
      child: Container(
        width: w,
        height: h,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.55),
              blurRadius: 20,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (context, u, e) => Container(
                color: AppColors.card,
                child:
                    const Icon(Icons.album, color: Colors.white24, size: 40),
              ),
            ),
            if (t > 0.02)
              ColoredBox(
                color: Colors.black.withValues(
                  alpha: (t * 0.4).clamp(0.0, 0.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The 2×2 grid of library stat cards (Liked / Playlists / Albums / Artists).
class _LibraryStatGrid extends StatelessWidget {
  final MusicPlayerService playerService;
  final void Function(BuildContext, Widget) onOpen;

  const _LibraryStatGrid({required this.playerService, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: BlocBuilder<LibraryCubit, LibraryState>(
                  builder: (context, lib) => _LibraryStatCard(
                    icon: Icons.favorite,
                    title: 'Liked Songs',
                    subtitle: '${lib.favorites.length} TRACKS',
                    colors: const [Color(0xFF4A2A7A), Color(0xFF241433)],
                    onTap: () => onOpen(
                      context,
                      LikedSongsPage(playerService: playerService),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BlocBuilder<PlaylistsCubit, PlaylistsState>(
                  builder: (context, state) => _LibraryStatCard(
                    icon: Icons.queue_music,
                    title: 'Playlists',
                    subtitle:
                        '${state is PlaylistsSuccess ? state.playlists.length : 0} PLAYLISTS',
                    colors: const [Color(0xFF3A1E5E), Color(0xFF1E1430)],
                    onTap: () => onOpen(
                      context,
                      PlaylistsListPage(playerService: playerService),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: BlocBuilder<AlbumsCubit, AlbumsState>(
                  builder: (context, state) => _LibraryStatCard(
                    icon: Icons.album,
                    title: 'Albums',
                    subtitle:
                        '${state is AlbumsSuccess ? state.albums.length : 0} SAVED',
                    colors: const [Color(0xFF2A2250), Color(0xFF191528)],
                    onTap: () => onOpen(
                      context,
                      AlbumsListPage(playerService: playerService),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BlocBuilder<ArtistsCubit, ArtistsState>(
                  builder: (context, state) => _LibraryStatCard(
                    icon: Icons.person,
                    title: 'Artists',
                    subtitle:
                        '${state is ArtistsSuccess ? state.artists.length : 0} FOLLOWING',
                    colors: const [Color(0xFF1C3A4A), Color(0xFF17202B)],
                    onTap: () => onOpen(
                      context,
                      ArtistsListPage(playerService: playerService),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LibraryStatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _LibraryStatCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: AppColors.accent, size: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// A "Listen again" hero card driven by the most recent / liked track.
class _ListenAgainCard extends StatelessWidget {
  final MusicPlayerService playerService;

  const _ListenAgainCard({required this.playerService});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LibraryCubit, LibraryState>(
      builder: (context, lib) {
        final queue = lib.recent.isNotEmpty ? lib.recent : lib.favorites;
        if (queue.isEmpty) return const SizedBox();
        final track = queue.first;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3A1E6E), Color(0xFF1C1430)],
              ),
              border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LISTEN AGAIN',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  track.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  track.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => playerService.playPlaylist(queue, 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.textPrimary,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.play_arrow, color: Colors.black, size: 20),
                        SizedBox(width: 6),
                        Text(
                          'PLAY',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
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

class _LibrarySectionHeader extends StatelessWidget {
  final String title;
  final Widget? action;

  const _LibrarySectionHeader(this.title, {this.action});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, action == null ? 20 : 8, 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          ?action,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom navigation
// ---------------------------------------------------------------------------

class _BottomNav extends StatelessWidget {
  final int index;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.index, required this.onTap});

  static const _items = <({IconData icon, String label})>[
    (icon: Icons.home_filled, label: 'Home'),
    (icon: Icons.search, label: 'Search'),
    (icon: Icons.favorite_border, label: 'Library'),
    (icon: Icons.person_outline, label: 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: ShapeDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                shape: RoundedRectangleBorder(
                  side: const BorderSide(
                    width: 0.9,
                    color: AppColors.strokeGray,
                  ),
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < _items.length; i++)
                    _NavItem(
                      icon: _items[i].icon,
                      label: _items[i].label,
                      selected: index == i,
                      onTap: () => onTap(i),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  /// Gradient fill for the active tab pill — exact Figma stops at 0.2 alpha
  /// (teal → magenta → pink → purple), which is what mutes them into the soft
  /// dark aubergine seen in the design. Angle 247.9° ≈ top-right → bottom-left.
  static const _selectedGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color.fromRGBO(0, 81, 109, 0.2),
      Color.fromRGBO(92, 0, 79, 0.2),
      Color.fromRGBO(255, 192, 192, 0.2),
      Color.fromRGBO(99, 0, 86, 0.2),
    ],
    stops: [0.013, 0.342, 0.639, 0.999],
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: selected ? _selectedPill() : _circleIcon(),
    );
  }

  Widget _selectedPill() {
    return Container(
      height: 46,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: ShapeDecoration(
        gradient: _selectedGradient,
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 0.9, color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: AppColors.textPrimary),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIcon() {
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          side: BorderSide(width: 1, color: Colors.white.withValues(alpha: 0.12)),
          borderRadius: BorderRadius.circular(100),
        ),
      ),
      child: Icon(icon, size: 21, color: AppColors.textPrimary),
    );
  }
}

/// Dark base with the soft coloured glow blobs from the design
/// (top-left cyan/purple + bottom magenta, all very low opacity).
class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(color: AppColors.background),
      child: Stack(
        children: [
          Positioned(
            left: -90,
            top: -90,
            child: _Glow(size: 300, color: Color.fromRGBO(53, 192, 238, 0.14)),
          ),
          Positioned(
            left: -30,
            top: -60,
            child: _Glow(size: 280, color: Color.fromRGBO(139, 92, 246, 0.16)),
          ),
          Positioned(
            right: -60,
            bottom: -130,
            child: _Glow(size: 320, color: Color.fromRGBO(206, 51, 185, 0.18)),
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final double size;
  final Color color;

  const _Glow({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ),
    );
  }
}

/// Full list opened from the "See all" link next to Top daily playlist.
class _AllTracksPage extends StatelessWidget {
  final String title;
  final List<Track> tracks;
  final MusicPlayerService playerService;

  const _AllTracksPage({
    required this.title,
    required this.tracks,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(title)),
      body: ListView.builder(
        padding: const EdgeInsets.only(bottom: 16),
        itemCount: tracks.length,
        itemBuilder: (context, i) => TrackTile(
          tracks: tracks,
          index: i,
          playerService: playerService,
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
