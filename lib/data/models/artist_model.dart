import 'package:musicc/domain/entities/artist.dart';

class ArtistModel extends Artist {
  const ArtistModel({
    required super.id,
    required super.name,
    required super.imageUrl,
  });

  factory ArtistModel.fromJson(Map<String, dynamic> json) {
    return ArtistModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      imageUrl: json['image'] ?? '',
    );
  }
}
