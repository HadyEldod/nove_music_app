import 'package:musicc/domain/entities/album.dart';

class AlbumModel extends Album {
  const AlbumModel({
    required super.id,
    required super.name,
    required super.artistId,
    required super.artistName,
    required super.imageUrl,
    required super.releaseDate,
  });

  factory AlbumModel.fromJson(Map<String, dynamic> json) {
    return AlbumModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      artistId: json['artist_id']?.toString() ?? '',
      artistName: json['artist_name'] ?? '',
      imageUrl: json['image'] ?? '',
      releaseDate: json['releasedate'] ?? '',
    );
  }
}
