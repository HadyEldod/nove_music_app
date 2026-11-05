import 'package:flutter/material.dart';

import 'package:musicc/core/genres.dart';
import 'package:musicc/presentation/pages/onboarding/artists_page.dart';
import 'package:musicc/presentation/pages/onboarding/onboarding_common.dart';

/// Second onboarding step — pick favorite genres.
///
/// Chips are rendered dynamically from [kGenres] (the same Jamendo-backed
/// genre list the rest of the app browses), and the selection is carried
/// forward in [OnboardingData].
class GenresPage extends StatefulWidget {
  const GenresPage({super.key, required this.data});

  final OnboardingData data;

  @override
  State<GenresPage> createState() => _GenresPageState();
}

class _GenresPageState extends State<GenresPage> {
  void _toggle(String tag) {
    setState(() {
      if (!widget.data.genreTags.add(tag)) {
        widget.data.genreTags.remove(tag);
      }
    });
  }

  void _next() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ArtistsPage(data: widget.data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Nova.bg,
      body: NovaBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 28),
                const Text(
                  'Choose your\nfavorite genres',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 36),
                Expanded(
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 16,
                      children: [
                        for (final genre in kGenres)
                          _GenreChip(
                            label: genre.name.toUpperCase(),
                            selected:
                                widget.data.genreTags.contains(genre.tag),
                            onTap: () => _toggle(genre.tag),
                          ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    onPressed: _next,
                    child: const Text(
                      'SKIP',
                      style: TextStyle(
                        color: Nova.textMuted,
                        fontSize: 14,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                NovaPrimaryButton(
                  label: 'CONTINUE',
                  onPressed: _next,
                  active: widget.data.genreTags.isNotEmpty,
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
        decoration: BoxDecoration(
          color: selected
              ? Nova.cyan.withValues(alpha: 0.16)
              : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected
                ? Nova.cyan
                : Colors.white.withValues(alpha: 0.14),
            width: 1.4,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : const Color(0xFFB9B6C7),
            fontSize: 15,
            letterSpacing: 1,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
