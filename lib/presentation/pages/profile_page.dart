import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/track.dart';
import 'package:musicc/domain/entities/user.dart';
import 'package:musicc/presentation/cubit/auth_cubit.dart';
import 'package:musicc/presentation/cubit/auth_state.dart';
import 'package:musicc/presentation/cubit/library_cubit.dart';
import 'package:musicc/presentation/cubit/library_state.dart';
import 'package:musicc/presentation/pages/artist_page.dart';
import 'package:musicc/presentation/pages/collection_page.dart';
import 'package:musicc/presentation/pages/profile_sheets.dart';
import 'package:musicc/presentation/services/music_player_service.dart';

class ProfilePage extends StatelessWidget {
  final MusicPlayerService playerService;

  const ProfilePage({super.key, required this.playerService});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, authState) {
            final user = authState is AuthLoggedIn ? authState.user : null;
            return BlocBuilder<LibraryCubit, LibraryState>(
              builder: (context, lib) {
                return ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    const _TopBar(),
                    _Header(user: user),
                    const SizedBox(height: 20),
                    const _SectionTitle('Your Listening', trailingBars: true),
                    _StatsRow(lib: lib, playerService: playerService),
                    const SizedBox(height: 22),
                    const _SectionTitle('Your Sound', trailing: 'Sample taste'),
                    _YourSoundCard(lib: lib, playerService: playerService),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Row(
        children: [
          const Text(
            'Profile',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _CircleButton(
            icon: Icons.tune,
            onTap: () => showPreferencesSheet(context),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final User? user;

  const _Header({required this.user});

  @override
  Widget build(BuildContext context) {
    final name = user?.displayName.isNotEmpty == true
        ? user!.displayName
        : 'Guest';
    final handle =
        user?.name.isNotEmpty == true ? '@${user!.name}' : '@guest';
    return Column(
      children: [
        const SizedBox(height: 8),
        // Avatar with orbit rings + note badge.
        SizedBox(
          width: 170,
          height: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              _orbit(150),
              _orbit(120),
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.accent, width: 2.5),
                ),
                padding: const EdgeInsets.all(4),
                child: CircleAvatar(
                  backgroundColor: AppColors.card,
                  backgroundImage: user != null && user!.imageUrl.isNotEmpty
                      ? CachedNetworkImageProvider(user!.imageUrl)
                      : null,
                  child: user == null || user!.imageUrl.isEmpty
                      ? const Icon(Icons.person, size: 44, color: Colors.white54)
                      : null,
                ),
              ),
              Positioned(
                right: 34,
                bottom: 18,
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent,
                  ),
                  child: const Icon(Icons.music_note,
                      size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Text(
          name,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          handle,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 48),
          child: Text(
            'Somewhere between a late-night drive and a new favorite song.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ),
        const SizedBox(height: 16),
        _EditButton(user: user),
      ],
    );
  }

  Widget _orbit(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
    );
  }
}

class _EditButton extends StatelessWidget {
  final User? user;

  const _EditButton({required this.user});

  bool get loggedIn => user != null;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => loggedIn
          ? showEditProfileSheet(context, user)
          : _showAccountSheet(context, false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(loggedIn ? Icons.edit : Icons.login,
                size: 16, color: AppColors.textPrimary),
            const SizedBox(width: 8),
            Text(
              loggedIn ? 'EDIT PROFILE' : 'SIGN IN',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final LibraryState lib;
  final MusicPlayerService playerService;

  const _StatsRow({required this.lib, required this.playerService});

  @override
  Widget build(BuildContext context) {
    final artists = <String>{
      for (final t in [...lib.recent, ...lib.favorites])
        if (t.artistName.isNotEmpty) t.artistName,
    }.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.headphones,
              value: '${lib.recent.length}',
              label: 'Songs played',
              sub: 'Recently',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      LikedSongsPage(playerService: playerService),
                ),
              ),
              child: _StatCard(
                icon: Icons.favorite,
                value: '${lib.favorites.length}',
                label: 'Liked songs',
                sub: 'Your library ↗',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: Icons.queue_music,
              value: '$artists',
              label: 'Artists',
              sub: 'In library',
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String sub;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2A1E48), Color(0xFF17131F)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accent, size: 20),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 2),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.accent, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _YourSoundCard extends StatelessWidget {
  final LibraryState lib;
  final MusicPlayerService playerService;

  const _YourSoundCard({required this.lib, required this.playerService});

  @override
  Widget build(BuildContext context) {
    // Unique artists from the library, with artwork, for the avatar row.
    final seen = <String>{};
    final artists = <Track>[];
    for (final t in [...lib.recent, ...lib.favorites]) {
      if (t.artistName.isEmpty || seen.contains(t.artistName)) continue;
      seen.add(t.artistName);
      artists.add(t);
      if (artists.length >= 10) break;
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF241A3E), Color(0xFF15121E)],
          ),
          border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'A little electronic.',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'A lot of feeling.',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: const Icon(Icons.album,
                      color: AppColors.textSecondary, size: 22),
                ),
              ],
            ),
            if (artists.isNotEmpty) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 92,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: artists.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 14),
                  itemBuilder: (context, i) {
                    final t = artists[i];
                    return GestureDetector(
                      onTap: t.artistId.isEmpty
                          ? null
                          : () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ArtistPage(
                                    artistId: t.artistId,
                                    artistName: t.artistName,
                                    playerService: playerService,
                                  ),
                                ),
                              ),
                      child: SizedBox(
                        width: 62,
                        child: Column(
                          children: [
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: AppColors.card,
                              backgroundImage: t.imageUrl.isNotEmpty
                                  ? CachedNetworkImageProvider(t.imageUrl)
                                  : null,
                              child: t.imageUrl.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white54)
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              t.artistName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Favorite',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
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
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? trailing;
  final bool trailingBars;

  const _SectionTitle(this.title, {this.trailing, this.trailingBars = false});

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
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          if (trailing != null)
            Text(
              trailing!,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          if (trailingBars)
            const Icon(Icons.equalizer, color: AppColors.accent, size: 20),
        ],
      ),
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
      color: Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(icon, size: 18, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

/// Account bottom sheet — sign in (guest) or sign out (logged in).
void _showAccountSheet(BuildContext context, bool loggedIn) {
  final authCubit = context.read<AuthCubit>();
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 20,
          bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: loggedIn
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Account',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      backgroundColor: AppColors.accent,
                    ),
                    onPressed: () {
                      authCubit.signOut();
                      Navigator.of(sheetContext).pop();
                    },
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign out'),
                  ),
                ],
              )
            : _SignInSheet(authCubit: authCubit),
      );
    },
  );
}

class _SignInSheet extends StatefulWidget {
  final AuthCubit authCubit;

  const _SignInSheet({required this.authCubit});

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sign in',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Enter your Jamendo username to see your profile and playlists.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _controller,
          style: const TextStyle(color: AppColors.textPrimary),
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _submit(),
          decoration: InputDecoration(
            hintText: 'Jamendo username',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.06),
            prefixIcon:
                const Icon(Icons.alternate_email, color: AppColors.textMuted),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(48),
            backgroundColor: AppColors.accent,
          ),
          onPressed: _submit,
          child: const Text('Sign in'),
        ),
      ],
    );
  }

  void _submit() {
    widget.authCubit.signIn(_controller.text);
    Navigator.of(context).maybePop();
  }
}
