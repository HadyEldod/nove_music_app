import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/domain/entities/playlist.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/widgets/playlist_cover.dart';

class PlaylistCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const PlaylistCard({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final repository = context.read<MusicRepository>();
    final coverFuture = PlaylistCover.of(repository, playlist.id);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 56,
          height: 56,
          child: FutureBuilder<String?>(
            future: coverFuture,
            builder: (context, snapshot) {
              final url = snapshot.data;
              if (url != null && url.isNotEmpty) {
                return CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  errorWidget: (context, u, e) => _placeholder(theme),
                );
              }
              return _placeholder(theme);
            },
          ),
        ),
      ),
      title: Text(
        playlist.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: playlist.userName.isEmpty
          ? null
          : Text(
              'by ${playlist.userName}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.queue_music,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
