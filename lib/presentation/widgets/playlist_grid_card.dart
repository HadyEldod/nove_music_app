import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:musicc/domain/entities/playlist.dart';
import 'package:musicc/domain/repositories/music_repository.dart';
import 'package:musicc/presentation/widgets/playlist_cover.dart';

class PlaylistGridCard extends StatelessWidget {
  final Playlist playlist;
  final VoidCallback onTap;

  const PlaylistGridCard({
    super.key,
    required this.playlist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final coverFuture =
        PlaylistCover.of(context.read<MusicRepository>(), playlist.id);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  FutureBuilder<String?>(
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
                  // Bottom scrim so a peeking play button always reads.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.55, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      child: Icon(
                        Icons.play_arrow,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            playlist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (playlist.userName.isNotEmpty)
            Text(
              playlist.userName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  Widget _placeholder(ThemeData theme) {
    return Container(
      color: theme.colorScheme.primaryContainer,
      child: Icon(
        Icons.queue_music,
        size: 40,
        color: theme.colorScheme.onPrimaryContainer,
      ),
    );
  }
}
