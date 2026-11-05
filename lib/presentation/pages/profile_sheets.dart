import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/domain/entities/user.dart';
import 'package:musicc/presentation/cubit/auth_cubit.dart';
import 'package:musicc/presentation/cubit/auth_state.dart';

/// In-memory, "preview only" profile preferences (as the design notes, these
/// are demo settings saved locally for this session, not to an account).
class ProfilePrefs {
  ProfilePrefs._();
  static final audioQuality = ValueNotifier<String>('High');
  static final appearance = ValueNotifier<String>('Dark');
  static final language = ValueNotifier<String>('English');
  static final notifNewReleases = ValueNotifier<bool>(true);
  static final notifPlaylist = ValueNotifier<bool>(true);
}

Future<T?> _openSheet<T>(BuildContext context, Widget child) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppColors.surface,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (_) => child,
  );
}

/// Shared sheet chrome: grab handle, title, optional back + close.
class _Sheet extends StatelessWidget {
  final String title;
  final bool showBack;
  final List<Widget> children;

  const _Sheet({
    required this.title,
    required this.children,
    this.showBack = false,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
              child: Row(
                children: [
                  if (showBack)
                    _circle(Icons.arrow_back_ios_new,
                        () => Navigator.of(context).maybePop()),
                  if (showBack) const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _circle(Icons.close, () => Navigator.of(context).maybePop()),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: children,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _circle(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(icon, size: 16, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

Widget _footerNote(String text) {
  return Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Text(
      text,
      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
    ),
  );
}

// ---------------------------------------------------------------------------
// Preferences (main settings sheet)
// ---------------------------------------------------------------------------

void showPreferencesSheet(BuildContext context) {
  _openSheet(
    context,
    _Sheet(
      title: 'Your preferences',
      children: [
        ValueListenableBuilder<String>(
          valueListenable: ProfilePrefs.audioQuality,
          builder: (context, v, _) => _prefRow(
            context,
            icon: Icons.headphones,
            title: 'Audio Quality',
            subtitle: '$v quality',
            onTap: () => showAudioQualitySheet(context),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: ProfilePrefs.appearance,
          builder: (context, v, _) => _prefRow(
            context,
            icon: Icons.dark_mode_outlined,
            title: 'Appearance',
            subtitle: '$v · Discover profile',
            onTap: () => showAppearanceSheet(context),
          ),
        ),
        _prefRow(
          context,
          icon: Icons.notifications_none,
          title: 'Notifications',
          subtitle: 'Release & playlist preferences',
          onTap: () => showNotificationsSheet(context),
        ),
        ValueListenableBuilder<String>(
          valueListenable: ProfilePrefs.language,
          builder: (context, v, _) => _prefRow(
            context,
            icon: Icons.translate,
            title: 'Language',
            subtitle: v,
            onTap: () => showLanguageSheet(context),
          ),
        ),
        _prefRow(
          context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          subtitle: 'A little guidance, anytime',
          onTap: () => showHelpSheet(context),
        ),
        BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is! AuthLoggedIn) return const SizedBox.shrink();
            return _prefRow(
              context,
              icon: Icons.logout,
              title: 'Sign out',
              subtitle: 'Leave @${state.user.name}',
              onTap: () {
                context.read<AuthCubit>().signOut();
                Navigator.of(context).maybePop();
              },
            );
          },
        ),
        _footerNote('A profile that stays yours. Settings and edits are '
            'saved in this browser, not to an online account.'),
      ],
    ),
  );
}

Widget _prefRow(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 13),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Sub-sheets
// ---------------------------------------------------------------------------

void showAudioQualitySheet(BuildContext context) {
  const options = [
    ('Standard', '~96 kbps'),
    ('High', '~160 kbps'),
    ('Very high', '~320 kbps'),
  ];
  _openSheet(
    context,
    _Sheet(
      title: 'Audio Quality',
      showBack: true,
      children: [
        for (final o in options)
          ValueListenableBuilder<String>(
            valueListenable: ProfilePrefs.audioQuality,
            builder: (context, v, _) => _choiceRow(
              title: o.$1,
              subtitle: o.$2,
              selected: v == o.$1,
              onTap: () => ProfilePrefs.audioQuality.value = o.$1,
            ),
          ),
        const SizedBox(height: 8),
        _footerNote('Your preferred quality is saved locally. Demo playback '
            'always streams the available source.'),
        const SizedBox(height: 12),
        _outlineButton(
          icon: Icons.science_outlined,
          label: 'Open NOVA Audio Lab',
          onTap: () {
            Navigator.of(context).maybePop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('NOVA Audio Lab — coming soon.')),
            );
          },
        ),
      ],
    ),
  );
}

void showAppearanceSheet(BuildContext context) {
  const options = [
    ('Light', Icons.light_mode_outlined),
    ('Dark', Icons.dark_mode_outlined),
    ('System', Icons.brightness_auto_outlined),
  ];
  _openSheet(
    context,
    _Sheet(
      title: 'Appearance',
      showBack: true,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('Set the mood for your Discover profile.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
        ),
        ValueListenableBuilder<String>(
          valueListenable: ProfilePrefs.appearance,
          builder: (context, v, _) => Row(
            children: [
              for (final o in options)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: GestureDetector(
                      onTap: () => ProfilePrefs.appearance.value = o.$1,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: v == o.$1
                              ? AppColors.accent.withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: v == o.$1
                                ? AppColors.accent
                                : Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(o.$2,
                                color: v == o.$1
                                    ? AppColors.accent
                                    : AppColors.textSecondary),
                            const SizedBox(height: 10),
                            Text(
                              o.$1,
                              style: TextStyle(
                                color: v == o.$1
                                    ? AppColors.accent
                                    : AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _footerNote('Applies to this Discover experience. The rest of NOVA '
            'stays on its signature dark theme (demo).'),
      ],
    ),
  );
}

void showNotificationsSheet(BuildContext context) {
  _openSheet(
    context,
    _Sheet(
      title: 'Notifications',
      showBack: true,
      children: [
        _toggleRow(
          title: 'New releases',
          subtitle: 'Your preference for favorite artist updates.',
          notifier: ProfilePrefs.notifNewReleases,
        ),
        _toggleRow(
          title: 'Playlist updates',
          subtitle: 'Your preference for fresh mixes and playlist news.',
          notifier: ProfilePrefs.notifPlaylist,
        ),
        _footerNote('Preference preview only. Push notifications and emails '
            'are not sent in this demo.'),
      ],
    ),
  );
}

void showLanguageSheet(BuildContext context) {
  const options = [
    ('English', 'Discover profile & preferences'),
    ('العربية', 'بروفايل Discover والتفضيلات'),
  ];
  _openSheet(
    context,
    _Sheet(
      title: 'Language',
      showBack: true,
      children: [
        for (final o in options)
          ValueListenableBuilder<String>(
            valueListenable: ProfilePrefs.language,
            builder: (context, v, _) => _choiceRow(
              title: o.$1,
              subtitle: o.$2,
              selected: v == o.$1,
              onTap: () => ProfilePrefs.language.value = o.$1,
            ),
          ),
        _footerNote('Changes the language of this Discover profile and its '
            'preferences (demo).'),
      ],
    ),
  );
}

void showHelpSheet(BuildContext context) {
  const faqs = [
    (
      'Is this my real listening history?',
      'Not yet. Listening time, favorite genres and rankings are sample '
          'data for this demo profile.'
    ),
    (
      'Where are my profile edits saved?',
      'Locally, in this session only — nothing is sent to an online account.'
    ),
    (
      'How do I create a playlist?',
      'Playlist creation isn\'t available with the Jamendo catalog in this '
          'demo. You can like songs to build your library.'
    ),
  ];
  _openSheet(
    context,
    _Sheet(
      title: 'Help & Support',
      showBack: true,
      children: [
        for (final f in faqs)
          Theme(
            data: Theme.of(context).copyWith(
              dividerColor: Colors.transparent,
              splashColor: Colors.transparent,
            ),
            child: ExpansionTile(
              iconColor: AppColors.accent,
              collapsedIconColor: AppColors.textMuted,
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 12),
              title: Text(
                f.$1,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    f.$2,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        _outlineButton(
          icon: Icons.copy_outlined,
          label: 'Copy support details',
          onTap: () {
            Clipboard.setData(
                const ClipboardData(text: 'NOVA demo · support@nova.app'));
            Navigator.of(context).maybePop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Support details copied.')),
            );
          },
        ),
      ],
    ),
  );
}

// ---------------------------------------------------------------------------
// Edit profile
// ---------------------------------------------------------------------------

void showEditProfileSheet(BuildContext context, User? user) {
  _openSheet(context, _EditProfileSheet(user: user));
}

class _EditProfileSheet extends StatefulWidget {
  final User? user;

  const _EditProfileSheet({required this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _name =
      TextEditingController(text: widget.user?.displayName ?? '');
  late final TextEditingController _username =
      TextEditingController(text: widget.user?.name ?? '');
  late final TextEditingController _bio = TextEditingController(
      text: 'Somewhere between a late-night drive and a new favorite song.');

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Sheet(
      title: 'Edit Profile',
      children: [
        _field('Display name', _name),
        _field('Username', _username,
            hint: 'For this demo profile only.'),
        _field('Bio (optional)', _bio, maxLines: 3),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.of(context).maybePop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile saved (demo).')),
            );
          },
          child: Container(
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Save changes',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Saved only in this session. No online account or record is updated.',
          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
        ),
      ],
    );
  }

  Widget _field(String label, TextEditingController c,
      {String? hint, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(
            controller: c,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint,
                style:
                    const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Small shared bits
// ---------------------------------------------------------------------------

Widget _choiceRow({
  required String title,
  required String subtitle,
  required bool selected,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.accent : AppColors.textMuted,
            size: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _toggleRow({
  required String title,
  required String subtitle,
  required ValueNotifier<bool> notifier,
}) {
  return ValueListenableBuilder<bool>(
    valueListenable: notifier,
    builder: (context, on, _) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
          Switch(
            value: on,
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accent,
            inactiveTrackColor: AppColors.elevated,
            onChanged: (v) => notifier.value = v,
          ),
        ],
      ),
    ),
  );
}

Widget _outlineButton({
  required IconData icon,
  required String label,
  required VoidCallback onTap,
}) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.textPrimary),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    ),
  );
}
