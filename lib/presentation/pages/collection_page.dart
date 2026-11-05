import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/artist.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/albums_cubit.dart';
import 'package:musicc/presentation/cubit/albums_state.dart';
import 'package:musicc/presentation/cubit/artists_cubit.dart';
import 'package:musicc/presentation/cubit/artists_state.dart';
import 'package:musicc/presentation/cubit/library_cubit.dart';
import 'package:musicc/presentation/cubit/library_state.dart';
import 'package:musicc/presentation/cubit/playlists_cubit.dart';
import 'package:musicc/presentation/cubit/playlists_state.dart';
import 'package:musicc/presentation/pages/album_detail_page.dart';
import 'package:musicc/presentation/pages/artist_page.dart';
import 'package:musicc/presentation/pages/now_playing_page.dart';
import 'package:musicc/presentation/pages/playlist_detail_page.dart';
import 'package:musicc/presentation/services/music_player_service.dart';
import 'package:musicc/presentation/widgets/now_playing_bar.dart';

/// All liked songs — the designed "Liked Songs" screen.
class LikedSongsPage extends StatefulWidget {
  final MusicPlayerService playerService;

  const LikedSongsPage({super.key, required this.playerService});

  @override
  State<LikedSongsPage> createState() => _LikedSongsPageState();
}

class _LikedSongsPageState extends State<LikedSongsPage> {
  final TextEditingController _search = TextEditingController();
  bool _sortAZ = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Track> _filter(List<Track> favorites) {
    final q = _search.text.trim().toLowerCase();
    var list = favorites;
    if (q.isNotEmpty) {
      list = list
          .where((t) =>
              t.name.toLowerCase().contains(q) ||
              t.artistName.toLowerCase().contains(q))
          .toList();
    }
    if (_sortAZ) {
      list = [...list]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: NowPlayingBar(playerService: widget.playerService),
      body: BlocBuilder<LibraryCubit, LibraryState>(
        builder: (context, state) {
          final favorites = state.favorites;
          final visible = _filter(favorites);
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
                          'Your Library',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 42),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: const Icon(Icons.favorite,
                          color: AppColors.like, size: 30),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ALL YOUR FAVORITES',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Liked Songs',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'The songs that stay with you.',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  controller: _search,
                  style: const TextStyle(color: AppColors.textPrimary),
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search liked songs',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.06),
                    prefixIcon:
                        const Icon(Icons.search, color: AppColors.textMuted),
                    suffixIcon: _search.text.isEmpty
                        ? const Icon(Icons.mic_none, color: AppColors.textMuted)
                        : IconButton(
                            icon: const Icon(Icons.clear,
                                color: AppColors.textMuted),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _PlayAllButton(
                      onTap: favorites.isEmpty
                          ? null
                          : () => widget.playerService
                              .playPlaylist(favorites, 0),
                    ),
                    const SizedBox(width: 12),
                    ValueListenableBuilder<bool>(
                      valueListenable: widget.playerService.shuffle,
                      builder: (context, on, _) => _CircleButton(
                        icon: Icons.shuffle,
                        iconColor:
                            on ? AppColors.accent : AppColors.textPrimary,
                        onTap: widget.playerService.toggleShuffle,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _sortAZ = !_sortAZ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
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
                    Text(
                      '${favorites.length}',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              if (favorites.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(
                    child: Text('Songs you like will appear here',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                )
              else
                for (var i = 0; i < visible.length; i++)
                  _LikedRow(
                    tracks: visible,
                    index: i,
                    playerService: widget.playerService,
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _LikedRow extends StatelessWidget {
  final List<Track> tracks;
  final int index;
  final MusicPlayerService playerService;

  const _LikedRow({
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
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.favorite,
                          color: AppColors.like, size: 22),
                      onPressed: () =>
                          context.read<LibraryCubit>().toggleFavorite(track),
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

/// Shared chrome for the Albums / Artists / Playlists library grids:
/// back + "Your Library", an icon/title block, a search field and a sort
/// toggle. The caller supplies the grid, filtered by [query]/[sortAZ].
class _LibraryGridScreen extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String title;
  final String subtitle;
  final String searchHint;
  final String sectionTitle;
  final Widget? sectionLeading;
  final MusicPlayerService playerService;
  final Widget Function(String query, bool sortAZ) gridBuilder;

  const _LibraryGridScreen({
    required this.icon,
    this.iconColor = AppColors.accent,
    required this.label,
    required this.title,
    required this.subtitle,
    required this.searchHint,
    this.sectionTitle = '',
    this.sectionLeading,
    required this.playerService,
    required this.gridBuilder,
  });

  @override
  State<_LibraryGridScreen> createState() => _LibraryGridScreenState();
}

class _LibraryGridScreenState extends State<_LibraryGridScreen> {
  final TextEditingController _search = TextEditingController();
  bool _sortAZ = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      bottomNavigationBar: NowPlayingBar(playerService: widget.playerService),
      body: ListView(
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
                      'Your Library',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 42),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.06),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.12)),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
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
              widget.subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              style: const TextStyle(color: AppColors.textPrimary),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                hintStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.06),
                prefixIcon:
                    const Icon(Icons.search, color: AppColors.textMuted),
                suffixIcon: _search.text.isEmpty
                    ? const Icon(Icons.mic_none, color: AppColors.textMuted)
                    : IconButton(
                        icon: const Icon(Icons.clear,
                            color: AppColors.textMuted),
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
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                widget.sectionLeading ??
                    Text(
                      widget.sectionTitle,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _sortAZ = !_sortAZ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
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
          const SizedBox(height: 12),
          widget.gridBuilder(_search.text.trim().toLowerCase(), _sortAZ),
        ],
      ),
    );
  }
}

class AlbumsListPage extends StatelessWidget {
  final MusicPlayerService playerService;

  const AlbumsListPage({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AlbumsCubit(context.read<MusicRepository>())..load(),
      child: _LibraryGridScreen(
        icon: Icons.album,
        iconColor: AppColors.accent,
        label: 'MADE TO BE HEARD IN FULL',
        title: 'Albums',
        subtitle: 'Your favorite records, all in one place.',
        searchHint: 'Search Album',
        sectionTitle: 'you saved record',
        playerService: playerService,
        gridBuilder: (query, sortAZ) =>
            BlocBuilder<AlbumsCubit, AlbumsState>(
          builder: (context, state) {
            if (state is AlbumsLoading || state is AlbumsInitial) {
              return const _Loading();
            }
            if (state is AlbumsError) {
              return _Empty(message: state.message);
            }
            if (state is! AlbumsSuccess) return const SizedBox();
            var albums = state.albums;
            if (query.isNotEmpty) {
              albums = albums
                  .where((a) =>
                      a.name.toLowerCase().contains(query) ||
                      a.artistName.toLowerCase().contains(query))
                  .toList();
            }
            if (sortAZ) {
              albums = [...albums]..sort(
                  (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            }
            if (albums.isEmpty) {
              return const _Empty(message: 'No albums found');
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 18,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemCount: albums.length,
              itemBuilder: (context, i) {
                final album = albums[i];
                final year = album.releaseDate.length >= 4
                    ? album.releaseDate.substring(0, 4)
                    : '';
                return GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AlbumDetailPage(
                        album: album,
                        playerService: playerService,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: AspectRatio(
                          aspectRatio: 1,
                          child: CachedNetworkImage(
                            imageUrl: album.imageUrl,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => Container(
                              color: AppColors.card,
                              child: const Icon(Icons.album,
                                  color: Colors.white24, size: 40),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        album.name,
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
                        [
                          album.artistName.toUpperCase(),
                          if (year.isNotEmpty) year,
                        ].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class ArtistsListPage extends StatelessWidget {
  final MusicPlayerService playerService;

  const ArtistsListPage({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArtistsCubit(context.read<MusicRepository>())..load(),
      child: _LibraryGridScreen(
        icon: Icons.people_alt,
        label: 'THE VOICES IN YOUR WORLD',
        title: 'Artists',
        subtitle: 'Stay close to the artists you love.',
        searchHint: 'Search Artist',
        sectionTitle: 'In your orbit',
        playerService: playerService,
        gridBuilder: (query, sortAZ) =>
            BlocBuilder<ArtistsCubit, ArtistsState>(
          builder: (context, state) {
            if (state is ArtistsLoading || state is ArtistsInitial) {
              return const _Loading();
            }
            if (state is ArtistsError) {
              return _Empty(message: state.message);
            }
            if (state is! ArtistsSuccess) return const SizedBox();
            var artists = state.artists;
            if (query.isNotEmpty) {
              artists = artists
                  .where((a) => a.name.toLowerCase().contains(query))
                  .toList();
            }
            if (sortAZ) {
              artists = [...artists]..sort(
                  (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            }
            if (artists.isEmpty) {
              return const _Empty(message: 'No artists found');
            }
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 14,
                childAspectRatio: 0.78,
              ),
              itemCount: artists.length,
              itemBuilder: (context, i) => _ArtistGridCard(
                artist: artists[i],
                playerService: playerService,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// A bordered artist card: avatar + follow badge + name + Follow button.
class _ArtistGridCard extends StatefulWidget {
  final Artist artist;
  final MusicPlayerService playerService;

  const _ArtistGridCard({required this.artist, required this.playerService});

  @override
  State<_ArtistGridCard> createState() => _ArtistGridCardState();
}

class _ArtistGridCardState extends State<_ArtistGridCard> {
  bool _following = true;

  @override
  Widget build(BuildContext context) {
    final artist = widget.artist;
    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ArtistPage(
            artistId: artist.id,
            artistName: artist.name,
            playerService: widget.playerService,
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: AppColors.card,
                  backgroundImage: artist.imageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(artist.imageUrl)
                      : null,
                  child: artist.imageUrl.isEmpty
                      ? const Icon(Icons.person, color: Colors.white54)
                      : null,
                ),
                if (_following)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.accent,
                        border: Border.all(
                            color: AppColors.background, width: 2),
                      ),
                      child: const Icon(Icons.check,
                          size: 13, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              artist.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _following = !_following),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: _following
                      ? AppColors.accent.withValues(alpha: 0.22)
                      : AppColors.accent,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.5),
                  ),
                ),
                child: Text(
                  _following ? 'Following' : 'Follow',
                  style: TextStyle(
                    color: _following ? AppColors.accent : Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class PlaylistsListPage extends StatelessWidget {
  final MusicPlayerService playerService;

  // Gradient swatches cycled across the playlist row icons.
  static const _gradients = [
    [Color(0xFF9B6BFF), Color(0xFF6D28D9)],
    [Color(0xFFF43F6E), Color(0xFFB5295B)],
    [Color(0xFF35A0EE), Color(0xFF1E3A8A)],
    [Color(0xFF10D079), Color(0xFF0E7E7B)],
  ];

  const PlaylistsListPage({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => PlaylistsCubit(context.read<MusicRepository>())..load(),
      child: _LibraryGridScreen(
        icon: Icons.queue_music,
        label: 'A SOUNDTRACK FOR EVERY MOOD',
        title: 'Playlists',
        subtitle: 'Little worlds, made by you.',
        searchHint: 'Search Playlists',
        sectionLeading: Builder(
          builder: (context) => GestureDetector(
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Creating playlists isn\'t available for '
                    'Jamendo.'),
              ),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, color: Colors.black, size: 18),
                  SizedBox(width: 4),
                  Text(
                    'Create playlists',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        playerService: playerService,
        gridBuilder: (query, sortAZ) =>
            BlocBuilder<PlaylistsCubit, PlaylistsState>(
          builder: (context, state) {
            if (state is PlaylistsLoading || state is PlaylistsInitial) {
              return const _Loading();
            }
            if (state is PlaylistsError) {
              return _Empty(message: state.message);
            }
            if (state is! PlaylistsSuccess) return const SizedBox();
            var playlists = state.playlists;
            if (query.isNotEmpty) {
              playlists = playlists
                  .where((p) => p.name.toLowerCase().contains(query))
                  .toList();
            }
            if (sortAZ) {
              playlists = [...playlists]..sort(
                  (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
            }
            if (playlists.isEmpty) {
              return const _Empty(message: 'No playlists found');
            }
            return Column(
              children: [
                for (var i = 0; i < playlists.length; i++)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: _PlaylistRow(
                      name: playlists[i].name,
                      userName: playlists[i].userName,
                      colors: _gradients[i % _gradients.length],
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PlaylistDetailPage(
                            playlistId: playlists[i].id,
                            playlistName: playlists[i].name,
                            userName: playlists[i].userName,
                            playerService: playerService,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  final String name;
  final String userName;
  final List<Color> colors;
  final VoidCallback onTap;

  const _PlaylistRow({
    required this.name,
    required this.userName,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.03),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: colors,
                ),
              ),
              child: const Icon(Icons.queue_music,
                  color: Colors.white, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    userName.isEmpty ? 'By you' : 'By $userName',
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
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.accent),
    );
  }
}

class _Empty extends StatelessWidget {
  final String message;

  const _Empty({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.textMuted),
        ),
      ),
    );
  }
}
