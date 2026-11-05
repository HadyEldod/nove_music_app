import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/core/genres.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/cubit/music_state.dart';
import 'package:musicc/presentation/cubit/track_list_cubit.dart';
import 'package:musicc/presentation/services/music_player_service.dart';
import 'package:musicc/presentation/widgets/now_playing_bar.dart';
import 'package:musicc/presentation/widgets/track_list_body.dart';

class GenreTracksPage extends StatelessWidget {
  final Genre genre;
  final MusicPlayerService playerService;

  const GenreTracksPage({
    super.key,
    required this.genre,
    required this.playerService,
  });

  @override
  Widget build(BuildContext context) {
    final repository = context.read<MusicRepository>();

    return BlocProvider(
      create: (_) =>
          TrackListCubit(() => repository.getTracksByTag(genre.tag))..load(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(genre.name),
          backgroundColor: genre.color,
          foregroundColor: Colors.white,
        ),
        body: BlocBuilder<TrackListCubit, MusicState>(
          builder: (context, state) {
            return TrackListBody(
              state: state,
              playerService: playerService,
              onRefresh: () => context.read<TrackListCubit>().load(),
            );
          },
        ),
        bottomNavigationBar: NowPlayingBar(playerService: playerService),
      ),
    );
  }
}
