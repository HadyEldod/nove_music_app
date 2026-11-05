import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/onboarding_storage.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/music_cubit.dart';
import 'package:musicc/presentation/pages/home_page.dart';
import 'package:musicc/presentation/pages/onboarding/discover_page.dart';
import 'package:musicc/presentation/pages/onboarding/onboarding_common.dart';

/// Animated launch screen ("Cover") — the NOVA brand splash.
///
/// Fades the NOVA mark in over the signature dark/purple backdrop, then
/// routes to onboarding (first launch) or straight into the app.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  final _storage = OnboardingStorage();
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _scale = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
      ),
    );

    Timer(const Duration(milliseconds: 2400), _route);
  }

  Future<void> _route() async {
    if (!mounted) return;
    final done = await _storage.isComplete();
    if (!mounted) return;

    final repository = context.read<MusicRepository>();
    final Widget destination = done
        ? BlocProvider(
            create: (_) => MusicCubit(repository),
            child: const HomePage(),
          )
        : DiscoverPage(data: OnboardingData());

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, animation, _) =>
            FadeTransition(opacity: animation, child: destination),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Nova.bg,
      ),
      child: Scaffold(
        backgroundColor: Nova.bg,
        body: NovaBackground(
          child: Center(
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                child: Image.asset(
                  'assets/images/nova_logo.png',
                  width: width * 0.68,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
