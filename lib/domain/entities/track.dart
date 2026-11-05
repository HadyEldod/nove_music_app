class Track {
  final String id;
  final String name;
  final String artistId;
  final String artistName;
  final String albumName;
  final String imageUrl;
  final String audioUrl;

  /// Track length in seconds (0 when unknown).
  final int duration;

  const Track({
    required this.id,
    required this.name,
    required this.artistId,
    required this.artistName,
    required this.albumName,
    required this.imageUrl,
    required this.audioUrl,
    this.duration = 0,
  });

  /// Formatted length, e.g. "4:32" — empty when the duration is unknown.
  String get durationText {
    if (duration <= 0) return '';
    final m = duration ~/ 60;
    final s = (duration % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Serialization for local storage (favorites / recently played).
  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'artistId': artistId,
        'artistName': artistName,
        'albumName': albumName,
        'imageUrl': imageUrl,
        'audioUrl': audioUrl,
        'duration': duration,
      };

  factory Track.fromMap(Map<String, dynamic> map) => Track(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        artistId: map['artistId'] ?? '',
        artistName: map['artistName'] ?? '',
        albumName: map['albumName'] ?? '',
        imageUrl: map['imageUrl'] ?? '',
        audioUrl: map['audioUrl'] ?? '',
        duration: (map['duration'] as num?)?.toInt() ?? 0,
      );
}
