import 'package:musicc/domain/entities/track.dart';

class TrackModel extends Track {
  const TrackModel({
    required super.id,
    required super.name,
    required super.artistId,
    required super.artistName,
    required super.albumName,
    required super.imageUrl,
    required super.audioUrl,
    super.duration,
  });

  factory TrackModel.fromJson(Map<String, dynamic> json) {
    return TrackModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      artistId: json['artist_id']?.toString() ?? '',
      artistName: json['artist_name'] ?? '',
      albumName: json['album_name'] ?? '',
      imageUrl: json['album_image'] ?? json['image'] ?? '',
      audioUrl: json['audio'] ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
    );
  }
}
