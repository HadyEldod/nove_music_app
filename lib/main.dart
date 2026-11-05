import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'package:musicc/core/app_colors.dart';
import 'package:musicc/core/auth_storage.dart';
import 'package:musicc/core/dio_factory.dart';
import 'package:musicc/core/library_storage.dart';
import 'package:musicc/data/datasources/lyrics_remote_data_source.dart';
import 'package:musicc/data/datasources/music_remote_data_source.dart';
import 'package:musicc/data/repositories/music_repository_impl.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/auth_cubit.dart';
import 'package:musicc/presentation/cubit/library_cubit.dart';
import 'package:musicc/presentation/cubit/lyrics_cubit.dart';
import 'package:musicc/presentation/pages/splash_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enables background playback and the system media notification.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.musicc.channel.audio',
    androidNotificationChannelName: 'Music playback',
    androidNotificationOngoing: true,
  );

  final dio = DioFactory.create();

  final remoteDataSource =
  MusicRemoteDataSource(dio);

  final repository =
  MusicRepositoryImpl(remoteDataSource);

  runApp(
    MyApp(
      repository: repository,
    ),
  );
}

class MyApp extends StatefulWidget {
  final MusicRepository repository;

  const MyApp({
    super.key,
    required this.repository,
  });

  static const _seed = AppColors.accent;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    // The whole app is a fixed dark theme — keep the system bars transparent
    // with light icons so they blend into the dark background.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );
  }

  ThemeData _buildTheme() {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: MyApp._seed,
      brightness: Brightness.dark,
    ).copyWith(
      surface: AppColors.background,
      primary: AppColors.accent,
      surfaceContainer: AppColors.surface,
      surfaceContainerHighest: AppColors.elevated,
    );

    // Primary English face from the design tokens ("Plus Jakarta Sans").
    // The brand display font "Luna" and the Arabic "Hail Elastic" are custom
    // files — drop their .ttf into assets/fonts to enable them.
    final textTheme = GoogleFonts.plusJakartaSansTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    ).apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      tabBarTheme: const TabBarThemeData(
        indicatorColor: AppColors.accent,
        labelColor: AppColors.textPrimary,
        unselectedLabelColor: AppColors.textMuted,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
      ),
      sliderTheme: const SliderThemeData(
        trackHeight: 4,
        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
        activeTrackColor: AppColors.accent,
        inactiveTrackColor: AppColors.divider,
        thumbColor: AppColors.textPrimary,
      ),
      listTileTheme: const ListTileThemeData(
        selectedColor: null,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        linearMinHeight: 2,
        color: AppColors.accent,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<MusicRepository>.value(
      value: widget.repository,
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                AuthCubit(widget.repository, AuthStorage())..restore(),
          ),
          BlocProvider(
            create: (_) => LibraryCubit(LibraryStorage())..load(),
          ),
          BlocProvider(
            create: (_) => LyricsCubit(LyricsRemoteDataSource()),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'NOVA',
          themeMode: ThemeMode.dark,
          theme: _buildTheme(),
          darkTheme: _buildTheme(),
          home: const SplashPage(),
        ),
      ),
    );
  }
}
