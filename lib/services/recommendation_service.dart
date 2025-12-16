import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/game_model.dart';
import 'cache_service.dart';

/// AI-based recommendation service using Content-Based Filtering with Cosine Similarity.
/// 
/// Analyzes user's game library to build a weighted feature vector of preferences,
/// then calculates similarity scores with candidate games to generate recommendations.
class RecommendationService {
  final CacheService _cache = CacheService();

  /// Analyzes user's games and generates personalized recommendations.
  /// 
  /// The Content-Based Filtering algorithm:
  /// 1. Builds a weighted feature vector from user's library (genres + tags)
  /// 2. Normalizes the vector to unit length for cosine similarity
  /// 3. Fetches candidate games from RAWG matching top preferences
  /// 4. Converts each candidate to a binary feature vector
  /// 5. Calculates Cosine Similarity between user and game vectors
  /// 6. Returns top recommendations sorted by similarity score
  Future<List<RecommendedGame>> getRecommendations(List<Game> userGames) async {
    if (userGames.isEmpty) {
      return [];
    }

    // Build normalized user preference vector
    final profile = _buildUserProfile(userGames);
    
    if (profile.featureVector.isEmpty) {
      return [];
    }

    // Get user's game IDs to exclude from recommendations
    final userGameIds = userGames.map((g) => g.id).toSet();

    // Fetch candidate games based on top preferences
    final candidates = await _fetchCandidateGames(profile);

    // Filter out games user already has
    final filteredCandidates = candidates
        .where((g) => !userGameIds.contains(g.id))
        .toList();

    // Score and rank using Cosine Similarity
    final recommendations = _scoreAndRankGames(filteredCandidates, profile);

    return recommendations.take(15).toList();
  }

  /// Builds a normalized user preference profile using weighted feature vectors.
  /// 
  /// Features are weighted by:
  /// - User's rating (higher rating = more weight)
  /// - Game status (Completed > Playing > Plan to Play)
  /// - Favorite status (extra weight)
  /// 
  /// The resulting vector is normalized to unit length (magnitude = 1.0)
  /// for proper cosine similarity calculation.
  UserPreferenceProfile _buildUserProfile(List<Game> games) {
    final featureVector = <String, double>{};
    
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

      // Add genre features (with 'genre:' prefix to avoid collisions)
      final genres = game.genre.split(', ');
      for (final genre in genres) {
        if (genre.isNotEmpty && genre != 'Unknown') {
          final key = 'genre:$genre';
          featureVector[key] = (featureVector[key] ?? 0) + weight;
        }
      }

      // Add tag features (with 'tag:' prefix)
      for (final tag in game.tags) {
        if (tag.isNotEmpty) {
          final key = 'tag:$tag';
          featureVector[key] = (featureVector[key] ?? 0) + weight;
        }
      }
    }

    // Normalize the feature vector to unit length
    final normalizedVector = _normalizeVector(featureVector);

    // Extract top genres and tags for fetching candidates
    final genreScores = <String, double>{};
    final tagScores = <String, double>{};
    
    for (final entry in featureVector.entries) {
      if (entry.key.startsWith('genre:')) {
        genreScores[entry.key.substring(6)] = entry.value;
      } else if (entry.key.startsWith('tag:')) {
        tagScores[entry.key.substring(4)] = entry.value;
      }
    }

    final sortedGenres = genreScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final sortedTags = tagScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return UserPreferenceProfile(
      featureVector: normalizedVector,
      topGenres: sortedGenres.take(5).map((e) => e.key).toList(),
      topTags: sortedTags.take(10).map((e) => e.key).toList(),
      totalGames: games.length,
    );
  }

  /// Normalizes a vector to unit length (magnitude = 1.0).
  /// This is required for proper cosine similarity calculation.
  Map<String, double> _normalizeVector(Map<String, double> vector) {
    final magnitude = _calculateMagnitude(vector);
    
    if (magnitude == 0) return vector;
    
    return vector.map((key, value) => MapEntry(key, value / magnitude));
  }

  /// Calculates the magnitude (Euclidean length) of a vector.
  /// magnitude = sqrt(sum of squares of all values)
  double _calculateMagnitude(Map<String, double> vector) {
    double sumOfSquares = 0;
    for (final value in vector.values) {
      sumOfSquares += value * value;
    }
    return sqrt(sumOfSquares);
  }

  /// Calculates the dot product of two vectors.
  /// dotProduct = sum of (a[i] * b[i]) for all common features
  double _calculateDotProduct(
    Map<String, double> vectorA,
    Map<String, double> vectorB,
  ) {
    double dotProduct = 0;
    
    // Iterate over the smaller vector for efficiency
    final smaller = vectorA.length <= vectorB.length ? vectorA : vectorB;
    final larger = vectorA.length > vectorB.length ? vectorA : vectorB;
    
    for (final entry in smaller.entries) {
      if (larger.containsKey(entry.key)) {
        dotProduct += entry.value * larger[entry.key]!;
      }
    }
    
    return dotProduct;
  }

  /// Calculates Cosine Similarity between two vectors.
  /// 
  /// For normalized vectors (magnitude = 1), cosine similarity = dot product.
  /// Returns a value between 0.0 (no similarity) and 1.0 (identical).
  double _calculateCosineSimilarity(
    Map<String, double> userVector,
    Map<String, double> gameVector,
  ) {
    // Since userVector is already normalized, we only need to normalize gameVector
    final normalizedGameVector = _normalizeVector(gameVector);
    
    // For normalized vectors, cosine similarity equals the dot product
    return _calculateDotProduct(userVector, normalizedGameVector);
  }

  /// Converts a game to a binary feature vector (1.0 for present features).
  Map<String, double> _gameToFeatureVector(Game game) {
    final vector = <String, double>{};
    
    // Add genre features
    final genres = game.genre.split(', ');
    for (final genre in genres) {
      if (genre.isNotEmpty && genre != 'Unknown') {
        vector['genre:$genre'] = 1.0;
      }
    }
    
    // Add tag features
    for (final tag in game.tags) {
      if (tag.isNotEmpty) {
        vector['tag:$tag'] = 1.0;
      }
    }
    
    return vector;
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

  /// Scores and ranks games using Cosine Similarity.
  List<RecommendedGame> _scoreAndRankGames(
    List<Game> candidates,
    UserPreferenceProfile profile,
  ) {
    final recommendations = <RecommendedGame>[];

    for (final game in candidates) {
      // Convert game to feature vector
      final gameVector = _gameToFeatureVector(game);
      
      if (gameVector.isEmpty) continue;

      // Calculate cosine similarity between user and game vectors
      final similarity = _calculateCosineSimilarity(
        profile.featureVector,
        gameVector,
      );

      // Only include games with meaningful similarity
      if (similarity > 0.01) {
        // Find matched features for explanation
        final matchedGenres = <String>[];
        final matchedTags = <String>[];
        
        for (final key in gameVector.keys) {
          if (profile.featureVector.containsKey(key)) {
            if (key.startsWith('genre:')) {
              matchedGenres.add(key.substring(6));
            } else if (key.startsWith('tag:')) {
              matchedTags.add(key.substring(4));
            }
          }
        }

        // Apply small bonus for high-rated games (doesn't affect similarity much)
        double adjustedScore = similarity;
        if (game.metacritic != null && game.metacritic! >= 85) {
          adjustedScore *= 1.05;
        } else if (game.rawgRating >= 4.0) {
          adjustedScore *= 1.02;
        }

        recommendations.add(RecommendedGame(
          game: game,
          similarityScore: similarity,
          adjustedScore: adjustedScore,
          matchedGenres: matchedGenres,
          matchedTags: matchedTags.take(5).toList(),
          reason: _generateRecommendationReason(matchedGenres, matchedTags),
        ));
      }
    }

    // Sort by adjusted score descending
    recommendations.sort((a, b) => b.adjustedScore.compareTo(a.adjustedScore));

    return recommendations;
  }

  /// Generates a human-readable reason for the recommendation.
  String _generateRecommendationReason(
    List<String> matchedGenres,
    List<String> matchedTags,
  ) {
    if (matchedGenres.isNotEmpty) {
      return 'You enjoy ${matchedGenres.take(2).join(' and ')} games';
    }

    if (matchedTags.isNotEmpty) {
      final formattedTags = matchedTags
          .take(2)
          .map((t) => t.replaceAll('-', ' '))
          .join(', ');
      return 'Similar to games with $formattedTags';
    }

    return 'Based on your gaming preferences';
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

/// User's gaming preference profile with normalized feature vector.
class UserPreferenceProfile {
  /// Normalized feature vector (magnitude = 1.0) for cosine similarity.
  final Map<String, double> featureVector;
  
  /// Top genres for candidate fetching.
  final List<String> topGenres;
  
  /// Top tags for candidate fetching.
  final List<String> topTags;
  
  /// Total games in user's library.
  final int totalGames;

  UserPreferenceProfile({
    required this.featureVector,
    required this.topGenres,
    required this.topTags,
    required this.totalGames,
  });
}

/// A recommended game with cosine similarity scoring.
class RecommendedGame {
  final Game game;
  
  /// Raw cosine similarity score (0.0 to 1.0).
  final double similarityScore;
  
  /// Score adjusted with rating bonus.
  final double adjustedScore;
  
  /// Genres that matched user preferences.
  final List<String> matchedGenres;
  
  /// Tags that matched user preferences.
  final List<String> matchedTags;
  
  /// Human-readable recommendation reason.
  final String reason;

  RecommendedGame({
    required this.game,
    required this.similarityScore,
    required this.adjustedScore,
    required this.matchedGenres,
    required this.matchedTags,
    required this.reason,
  });

  /// Confidence level as a percentage (0-100) based on similarity.
  int get confidence => (similarityScore * 100).round().clamp(0, 100);
}
