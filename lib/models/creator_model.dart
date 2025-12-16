/// Represents a game development team member from RAWG API.
///
/// Contains creator info like roles, portfolio, and stats.
class Creator {
  final int id;
  final String name;
  final String? image;
  final String? imageBackground;
  final int gamesCount;
  final List<String> positions;
  final String? description;
  final List<CreatorGame> games;

  Creator({
    required this.id,
    required this.name,
    this.image,
    this.imageBackground,
    this.gamesCount = 0,
    this.positions = const [],
    this.description,
    this.games = const [],
  });

  factory Creator.fromJson(Map<String, dynamic> json) {
    return Creator(
      id: json['id'] ?? 0,
      name: json['name'] ?? 'Unknown',
      image: json['image'] as String?,
      imageBackground: json['image_background'] as String?,
      gamesCount: json['games_count'] as int? ?? 0,
      positions: _extractPositions(json['positions']),
      description: json['description'] as String?,
      games: _extractGames(json['games']),
    );
  }

  static List<String> _extractPositions(List<dynamic>? positionsJson) {
    if (positionsJson == null || positionsJson.isEmpty) return [];
    return positionsJson
        .map((p) => p['name']?.toString() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
  }

  static List<CreatorGame> _extractGames(List<dynamic>? gamesJson) {
    if (gamesJson == null || gamesJson.isEmpty) return [];
    return gamesJson.take(10).map((g) => CreatorGame.fromJson(g)).toList();
  }

  String get positionsString => positions.join(', ');
}

/// Simplified game info for creator portfolios.
class CreatorGame {
  final int id;
  final String slug;
  final String name;
  final int? added;

  CreatorGame({
    required this.id,
    required this.slug,
    required this.name,
    this.added,
  });

  factory CreatorGame.fromJson(Map<String, dynamic> json) {
    return CreatorGame(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      name: json['name'] ?? 'Unknown',
      added: json['added'] as int?,
    );
  }
}
