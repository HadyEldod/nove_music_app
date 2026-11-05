import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:musicc/presentation/services/music_player_service.dart';

/// Bottom sheet showing the current playback queue; tap a row to jump to it.
Future<void> showQueueSheet(
  BuildContext context,
  MusicPlayerService playerService,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) {
      final queue = playerService.queue;
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'Up next',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${queue.length} songs',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<int?>(
                  valueListenable: playerService.currentIndex,
                  builder: (context, currentIndex, _) {
                    return ListView.builder(
                      controller: scrollController,
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        final track = queue[index];
                        final isCurrent = index == currentIndex;
                        return ListTile(
                          selected: isCurrent,
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: CachedNetworkImage(
                              imageUrl: track.imageUrl,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => Container(
                                width: 44,
                                height: 44,
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                child: const Icon(Icons.music_note, size: 20),
                              ),
                            ),
                          ),
                          title: Text(
                            track.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isCurrent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                          subtitle: Text(
                            track.artistName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: isCurrent
                              ? Icon(
                                  Icons.equalizer,
                                  color: Theme.of(context).colorScheme.primary,
                                )
                              : null,
                          onTap: () {
                            playerService.jumpTo(index);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}
