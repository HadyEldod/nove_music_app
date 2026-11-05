import 'package:musicc/domain/entities/playlist.dart';

class PlaylistModel extends Playlist {
  const PlaylistModel({
    required super.id,
    required super.name,
    required super.userName,
    required super.creationDate,
  });

  factory PlaylistModel.fromJson(Map<String, dynamic> json) {
    return PlaylistModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      userName: json['user_name'] ?? '',
      creationDate: json['creationdate'] ?? '',
    );
  }
}
