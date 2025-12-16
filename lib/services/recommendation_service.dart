import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/game_model.dart';
import 'cache_service.dart';

/// AI-based recommendation service that analyzes user's game library
/// to suggest new games based on preferences, genres, tags, and ratings.
class RecommendationService {
  final CacheService _cache = CacheService();

  /// Analyzes user's games and generates personalized recommendations.
  /// 
  /// The algorithm:
  /// 1. Extracts genres and tags from user's library
  /// 2. Weights them by user ratings (higher rated = more weight)
  /// 3. Fetches games matching top preferences from RAWG
  /// 4. Scores each game based on preference matching
  /// 5. Returns top recommendations excluding games user already has
  Future<List<RecommendedGame>> getRecommendations(List<Game> userGames) async {
    if (userGames.isEmpty) {
      return [];
    }

    // Build user preference profile
    final profile = _buildUserProfile(userGames);
    
    if (profile.topGenres.isEmpty && profile.topTags.isEmpty) {
      return [];
    }

    // Get user's game IDs to exclude from recommendations
    final userGameIds = userGames.map((g) => g.id).toSet();

    // Fetch candidate games based on preferences
    final candidates = await _fetchCandidateGames(profile);

    // Filter out games user already has
    final filteredCandidates = candidates
        .where((g) => !userGameIds.contains(g.id))
        .toList();

    // Score and rank recommendations
    final recommendations = _scoreAndRankGames(filteredCandidates, profile);

    return recommendations.take(15).toList();
  }

  /// Builds a preference profile from user's game library.
  UserPreferenceProfile _buildUserProfile(List<Game> games) {
    final genreScores = <String, double>{};
    final tagScores = <String, double>{};
    
    for (final game in games) {
      // Calculate weight based on rating and status
      double weight = 1.0;
      
      // Games with higher platform ratings get more weight
      if (game.platformRating != null && game.platformRating! > 0) {
        weight = game.platformRating! / 5.0; // Normalize to 0-1
      } else if (game.rawgRating > 0) {
        weight = game.rawgRating / 5.0;
      }
      
      // Completed/Playing games indicate stronger preference
      if (game.status == 'Completed') {
        weight *= 1.5;
      } else if (game.status == 'Playing') {
        weight *= 1.3;
      }
      
      // Favorites get extra weight
      if (game.isFavorite) {
        weight *= 1.5;
      }

      // Score genres
      final genres = game.genre.split(', ');
      for (final genre in genres) {
        if (genre.isNotEmpty && genre != 'Unknown') {
          genreScores[genre] = (genreScores[genre] ?? 0) + weight;
        }
      }

      // Score tags
      for (final tag in game.tags) {
        if (tag.isNotEmpty) {
          tagScores[tag] = (tagScores[tag] ?? 0) + weight;
        }
      }
    }

    // Sort and get top preferences
    final sortedGenres = genreScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedTags = tagScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return UserPreferenceProfile(
      topGenres: sortedGenres.take(5).map((e) => e.key).toList(),
      topTags: sortedTags.take(10).map((e) => e.key).toList(),
      genreScores: genreScores,
      tagScores: tagScores,
      totalGames: games.length,
    );
  }

  /// Fetches candidate games from RAWG based on user preferences.
  Future<List<Game>> _fetchCandidateGames(UserPreferenceProfile profile) async {
    final allCandidates = <Game>[];

    // Fetch games for top genres
    for (final genre in profile.topGenres.take(3)) {
      final games = await _fetchGamesByGenre(genre);
      allCandidates.addAll(games);
    }

    // Fetch games for top tags
    for (final tag in profile.topTags.take(3)) {
      final games = await _fetchGamesByTag(tag);
      allCandidates.addAll(games);
    }

    // Remove duplicates by ID
    final seen = <int>{};
    return allCandidates.where((g) => seen.add(g.id)).toList();
  }

  /// Fetches games by genre from RAWG.
  Future<List<Game>> _fetchGamesByGenre(String genre) async {
    final cacheKey = 'rec_genre_${genre.toLowerCase()}';
    final cached = _cache.get<List<Game>>(cacheKey);
    if (cached != null) return cached;

    // Map genre names to RAWG genre slugs
    final genreSlug = _mapGenreToSlug(genre);
    if (genreSlug == null) return [];

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'genres': genreSlug,
      'ordering': '-rating',
      'page_size': '20',
      'metacritic': '70,100',
      'exclude_additions': 'true',
    };

    try {
      final url = Uri.parse('${ApiConfig.rawgBaseUrl}/games')
          .replace(queryParameters: queryParams);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        final games = results
            .map((json) => Game.fromJson(json))
            .where((g) => !g.isMatureRated && !g.hasNsfwTags)
            .toList();
        _cache.set(cacheKey, games, duration: const Duration(hours: 6));
        return games;
      }
    } catch (e) {
      debugPrint('RecommendationService: Error fetching by genre: $e');
    }
    return [];
  }

  /// Fetches games by tag from RAWG.
  Future<List<Game>> _fetchGamesByTag(String tag) async {
    final cacheKey = 'rec_tag_${tag.toLowerCase()}';
    final cached = _cache.get<List<Game>>(cacheKey);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'tags': tag.toLowerCase(),
      'ordering': '-rating',
      'page_size': '15',
      'metacritic': '70,100',
      'exclude_additions': 'true',
    };

    try {
      final url = Uri.parse('${ApiConfig.rawgBaseUrl}/games')
          .replace(queryParameters: queryParams);
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        final games = results
            .map((json) => Game.fromJson(json))
            .where((g) => !g.isMatureRated && !g.hasNsfwTags)
            .toList();
        _cache.set(cacheKey, games, duration: const Duration(hours: 6));
        return games;
      }
    } catch (e) {
      debugPrint('RecommendationService: Error fetching by tag: $e');
    }
    return [];
  }

  /// Scores and ranks games based on user preferences.
  List<RecommendedGame> _scoreAndRankGames(
    List<Game> candidates,
    UserPreferenceProfile profile,
  ) {
    final recommendations = <RecommendedGame>[];

    for (final game in candidates) {
      double score = 0;
      final matchedGenres = <String>[];
      final matchedTags = <String>[];

      // Score based on genre matches
      final gameGenres = game.genre.split(', ');
      for (final genre in gameGenres) {
        if (profile.genreScores.containsKey(genre)) {
          score += profile.genreScores[genre]! * 2; // Genres weighted higher
          matchedGenres.add(genre);
        }
      }

      // Score based on tag matches
      for (final tag in game.tags) {
        if (profile.tagScores.containsKey(tag)) {
          score += profile.tagScores[tag]!;
          matchedTags.add(tag);
        }
      }

      // Bonus for high-rated games
      if (game.metacritic != null && game.metacritic! >= 85) {
        score *= 1.2;
      } else if (game.rawgRating >= 4.0) {
        score *= 1.1;
      }

      // Only include games with some match
      if (score > 0) {
        recommendations.add(RecommendedGame(
          game: game,
          score: score,
          matchedGenres: matchedGenres,
          matchedTags: matchedTags.take(5).toList(),
          reason: _generateRecommendationReason(matchedGenres, matchedTags),
        ));
      }
    }

    // Sort by score descending
    recommendations.sort((a, b) => b.score.compareTo(a.score));

    return recommendations;
  }

  /// Generates a human-readable reason for the recommendation.
  String _generateRecommendationReason(
    List<String> matchedGenres,
    List<String> matchedTags,
  ) {
    final reasons = <String>[];

    if (matchedGenres.isNotEmpty) {
      reasons.add('You enjoy ${matchedGenres.take(2).join(' and ')} games');
    }

    if (matchedTags.isNotEmpty) {
      final formattedTags = matchedTags
          .take(2)
          .map((t) => t.replaceAll('-', ' '))
          .join(', ');
      reasons.add('Similar to games with $formattedTags');
    }

    if (reasons.isEmpty) {
      return 'Based on your gaming preferences';
    }

    return reasons.first;
  }

  /// Maps common genre names to RAWG API slugs.
  String? _mapGenreToSlug(String genre) {
    final mapping = {
      'Action': 'action',
      'Adventure': 'adventure',
      'RPG': 'role-playing-games-rpg',
      'Role Playing': 'role-playing-games-rpg',
      'Shooter': 'shooter',
      'Strategy': 'strategy',
      'Simulation': 'simulation',
      'Sports': 'sports',
      'Racing': 'racing',
      'Puzzle': 'puzzle',
      'Platformer': 'platformer',
      'Fighting': 'fighting',
      'Indie': 'indie',
      'Casual': 'casual',
      'Arcade': 'arcade',
      'Massively Multiplayer': 'massively-multiplayer',
      'Family': 'family',
      'Board Games': 'board-games',
      'Card': 'card',
      'Educational': 'educational',
    };

    return mapping[genre] ?? genre.toLowerCase().replaceAll(' ', '-');
  }
}

/// User's gaming preference profile built from their library.
class UserPreferenceProfile {
  final List<String> topGenres;
  final List<String> topTags;
  final Map<String, double> genreScores;
  final Map<String, double> tagScores;
  final int totalGames;

  UserPreferenceProfile({
    required this.topGenres,
    required this.topTags,
    required this.genreScores,
    required this.tagScores,
    required this.totalGames,
  });
}

/// A recommended game with scoring information.
class RecommendedGame {
  final Game game;
  final double score;
  final List<String> matchedGenres;
  final List<String> matchedTags;
  final String reason;

  RecommendedGame({
    required this.game,
    required this.score,
    required this.matchedGenres,
    required this.matchedTags,
    required this.reason,
  });

  /// Confidence level as a percentage (0-100).
  int get confidence => min(100, (score * 10).round());
}
