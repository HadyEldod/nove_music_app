import 'package:flutter/material.dart';

import 'package:musicc/presentation/pages/onboarding/genres_page.dart';
import 'package:musicc/presentation/pages/onboarding/onboarding_common.dart';

/// First onboarding step — the "Discover Your Sound" hero screen.
class DiscoverPage extends StatelessWidget {
  const DiscoverPage({super.key, required this.data});

  final OnboardingData data;

  void _next(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GenresPage(data: data)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Nova.bg,
      body: NovaBackground(
        glowAlignment: const Alignment(0.0, -1.0),
        child: Stack(
          children: [
            // Hero image anchored to the bottom, fading up into the dark.
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ShaderMask(
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.white],
                  stops: [0.0, 0.35],
                ).createShader(rect),
                blendMode: BlendMode.dstIn,
                child: Image.asset(
                  'assets/images/discover_hero.png',
                  fit: BoxFit.cover,
                  height: MediaQuery.of(context).size.height * 0.62,
                  width: double.infinity,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                child: Column(
                  children: [
                    Image.asset('assets/images/nova_mark.png', height: 56),
                    const SizedBox(height: 26),
                    const _Title(),
                    const SizedBox(height: 22),
                    const Text(
                      'EXPLORE MUSIC MADE FOR YOUR MOOD,\nYOUR MOMENTS AND YOUR TASTE.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const Spacer(),
                    NovaPrimaryButton(
                      label: 'GET STARTED',
                      trailingArrow: true,
                      onPressed: () => _next(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      letterSpacing: 2,
      height: 1.05,
    );
    return Column(
      children: [
        Text('DISCOVER', style: base.copyWith(color: Colors.white)),
        Text('YOUR SOUND', style: base.copyWith(color: Nova.cyan)),
      ],
    );
  }
}
