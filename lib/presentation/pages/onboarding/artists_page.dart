import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/onboarding_storage.dart';
import 'package:musicc/domain/entities/artist.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/artists_cubit.dart';
import 'package:musicc/presentation/cubit/artists_state.dart';
import 'package:musicc/presentation/cubit/music_cubit.dart';
import 'package:musicc/presentation/pages/home_page.dart';
import 'package:musicc/presentation/pages/onboarding/onboarding_common.dart';

/// Final onboarding step — pick favorite artists.
///
/// Artists are loaded dynamically from the [MusicRepository] (live Jamendo
/// data with real images) and are searchable. Selecting artists updates
/// [OnboardingData]; finishing persists the taste profile and enters the app.
class ArtistsPage extends StatelessWidget {
  const ArtistsPage({super.key, required this.data});

  final OnboardingData data;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ArtistsCubit(context.read<MusicRepository>())..load(),
      child: _ArtistsView(data: data),
    );
  }
}

class _ArtistsView extends StatefulWidget {
  const _ArtistsView({required this.data});

  final OnboardingData data;

  @override
  State<_ArtistsView> createState() => _ArtistsViewState();
}

class _ArtistsViewState extends State<_ArtistsView> {
  final _storage = OnboardingStorage();
  final _searchController = TextEditingController();
  Timer? _debounce;
  bool _finishing = false;

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      context.read<ArtistsCubit>().search(value.trim());
    });
  }

  void _toggle(Artist artist) {
    setState(() {
      if (!widget.data.artistIds.add(artist.id)) {
        widget.data.artistIds.remove(artist.id);
      }
    });
  }

  Future<void> _finish() async {
    if (_finishing) return;
    _finishing = true;
    await _storage.complete(
      genreTags: widget.data.genreTags.toList(),
      artistIds: widget.data.artistIds.toList(),
    );
    if (!mounted) return;
    final repository = context.read<MusicRepository>();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => MusicCubit(repository),
          child: const HomePage(),
        ),
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Nova.bg,
      body: NovaBackground(
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  const SliverToBoxAdapter(child: _Header()),
                  SliverToBoxAdapter(child: _searchField()),
                  const SliverToBoxAdapter(child: SizedBox(height: 20)),
                  _grid(),
                  const SliverToBoxAdapter(child: SizedBox(height: 140)),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: _bottomBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        textInputAction: TextInputAction.search,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Search artists',
          hintStyle: const TextStyle(color: Nova.textMuted, fontSize: 16),
          prefixIcon: const Icon(Icons.search, color: Nova.textMuted),
          filled: true,
          fillColor: Colors.white.withValues(alpha: 0.05),
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: const BorderSide(color: Nova.cyan),
          ),
        ),
      ),
    );
  }

  Widget _grid() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: BlocBuilder<ArtistsCubit, ArtistsState>(
        builder: (context, state) {
          if (state is ArtistsLoading || state is ArtistsInitial) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: CircularProgressIndicator(color: Nova.cyan),
                ),
              ),
            );
          }
          if (state is ArtistsError) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: Text(
                    'Could not load artists.\n${state.message}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Nova.textMuted),
                  ),
                ),
              ),
            );
          }
          final artists = (state as ArtistsSuccess).artists;
          if (artists.isEmpty) {
            return const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(
                  child: Text(
                    'No artists found.',
                    style: TextStyle(color: Nova.textMuted),
                  ),
                ),
              ),
            );
          }
          return _MasonryArtists(
            artists: artists,
            selected: widget.data.artistIds,
            onToggle: _toggle,
          );
        },
      ),
    );
  }

  Widget _bottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Nova.bg, Nova.bg],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: _finish,
            child: const Text(
              'SKIP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 4),
          NovaPrimaryButton(
            label: 'CONTINUE',
            onPressed: _finish,
            active: widget.data.artistIds.isNotEmpty,
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(24, 28, 24, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose your\nfavorite artists',
            style: TextStyle(
              color: Colors.white,
              fontSize: 40,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Pick a few artists you already love.',
            style: TextStyle(color: Nova.textMuted, fontSize: 16),
          ),
        ],
      ),
    );
  }
}

/// A two-column staggered layout mirroring the mockup's masonry grid.
class _MasonryArtists extends StatelessWidget {
  const _MasonryArtists({
    required this.artists,
    required this.selected,
    required this.onToggle,
  });

  final List<Artist> artists;
  final Set<String> selected;
  final void Function(Artist) onToggle;

  @override
  Widget build(BuildContext context) {
    final left = <Widget>[];
    final right = <Widget>[];
    // Cycle of card heights to create the staggered rhythm.
    const heights = [230.0, 190.0];
    for (var i = 0; i < artists.length; i++) {
      final artist = artists[i];
      final card = Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: _ArtistCard(
          artist: artist,
          height: heights[i % heights.length],
          selected: selected.contains(artist.id),
          onTap: () => onToggle(artist),
        ),
      );
      (i.isEven ? left : right).add(card);
    }

    return SliverToBoxAdapter(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Column(children: left)),
          const SizedBox(width: 16),
          Expanded(
            // Offset the right column to stagger against the left.
            child: Column(children: [const SizedBox(height: 36), ...right]),
          ),
        ],
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({
    required this.artist,
    required this.height,
    required this.selected,
    required this.onTap,
  });

  final Artist artist;
  final double height;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? Nova.cyan : Colors.transparent,
            width: 2.5,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (artist.imageUrl.isNotEmpty)
                CachedNetworkImage(
                  imageUrl: artist.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, _) =>
                      const ColoredBox(color: Nova.surface),
                  errorWidget: (_, _, _) => const ColoredBox(
                    color: Nova.surface,
                    child: Icon(Icons.person, color: Nova.textMuted, size: 48),
                  ),
                )
              else
                const ColoredBox(
                  color: Nova.surface,
                  child: Icon(Icons.person, color: Nova.textMuted, size: 48),
                ),
              // Bottom scrim for legible text.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black87],
                    stops: [0.45, 1.0],
                  ),
                ),
              ),
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Text(
                  artist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Nova.cyan,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check,
                        color: Colors.black, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
