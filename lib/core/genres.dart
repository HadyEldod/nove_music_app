import 'package:flutter/material.dart';

class Genre {
  final String name;
  final String tag;
  final Color color;

  const Genre(this.name, this.tag, this.color);
}

/// Curated Jamendo tags surfaced as browsable genres.
const List<Genre> kGenres = [
  Genre('Rock', 'rock', Color(0xFFE53935)),
  Genre('Pop', 'pop', Color(0xFF8E24AA)),
  Genre('Jazz', 'jazz', Color(0xFF3949AB)),
  Genre('Electronic', 'electronic', Color(0xFF00897B)),
  Genre('Classical', 'classical', Color(0xFF6D4C41)),
  Genre('Hip-Hop', 'hiphop', Color(0xFFF4511E)),
  Genre('Metal', 'metal', Color(0xFF455A64)),
  Genre('Ambient', 'ambient', Color(0xFF00ACC1)),
  Genre('Folk', 'folk', Color(0xFF7CB342)),
  Genre('Reggae', 'reggae', Color(0xFF43A047)),
  Genre('Lounge', 'lounge', Color(0xFF5E35B1)),
  Genre('Soundtrack', 'soundtrack', Color(0xFFFB8C00)),
];
