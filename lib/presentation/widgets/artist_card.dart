import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:musicc/domain/entities/artist.dart';

class ArtistCard extends StatelessWidget {
  final Artist artist;
  final VoidCallback onTap;

  const ArtistCard({
    super.key,
    required this.artist,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: artist.imageUrl,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                  child: const Icon(Icons.person, size: 48),
                ),
                placeholder: (context, url) => Container(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            artist.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
