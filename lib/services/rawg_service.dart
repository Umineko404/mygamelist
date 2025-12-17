import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/game_model.dart';
import 'cache_service.dart';

/// Service for interacting with the RAWG Video Games Database API.
/// 
/// Provides methods for searching, fetching game details, trending lists,
/// and various category data. Implements caching to reduce API calls.
/// 
/// API Documentation: https://rawg.io/apidocs
class RawgService {
  final CacheService _cache = CacheService();

  /// Formats DateTime to YYYY-MM-DD string for API queries.
  static String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Filters out games with Adults Only rating or NSFW tags.
  List<Game> _filterMatureContent(List<Game> games) {
    return games.where((g) => !g.isMatureRated && !g.hasNsfwTags).toList();
  }

  Future<List<Game>> searchGames(String query) async {
    final cacheKey = CacheKeys.search(query.toLowerCase());
    final cached = _cache.get<List<Game>>(cacheKey);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'search': query,
      'page_size': '30',
      'search_precise': 'true',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final games = _filterMatureContent(
          results.map((json) => Game.fromJson(json)).toList(),
        );
        _cache.set(cacheKey, games, duration: CacheService.shortCache);
        return games;
      } else {
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to connect to RAWG API: $e');
    }
  }

  Future<Game> getGameDetails(int id) async {
    final cacheKey = CacheKeys.gameDetails(id);
    final cached = _cache.get<Game>(cacheKey);
    if (cached != null) return cached;

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games/$id?key=${ApiConfig.rawgApiKey}',
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final game = Game.fromJson(data);
        _cache.set(cacheKey, game, duration: CacheService.mediumCache);
        return game;
      } else {
        throw Exception('Failed to load game details');
      }
    } catch (e) {
      throw Exception('Failed to connect to RAWG API');
    }
  }

  Future<List<Game>> getTrendingGames() async {
    final cached = _cache.get<List<Game>>(CacheKeys.trending);
    if (cached != null) return cached;

    final now = DateTime.now();
    final sixMonthsAgo = now.subtract(const Duration(days: 180));

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'dates': '${_formatDate(sixMonthsAgo)},${_formatDate(now)}',
      'ordering': '-added',
      'page_size': '25',
      'exclude_additions': 'true',
      'ratings_count': '100',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final filtered = _filterMatureContent(
          results.map((json) => Game.fromJson(json)).toList(),
        );
        final games = filtered.take(10).toList();
        _cache.set(
          CacheKeys.trending,
          games,
          duration: CacheService.mediumCache,
        );
        return games;
      } else {
        throw Exception(
          'Failed to load trending games: ${response.statusCode}',
        );
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Game>> getNewReleases() async {
    final cached = _cache.get<List<Game>>(CacheKeys.newReleases);
    if (cached != null) return cached;

    final now = DateTime.now();
    final oneMonthAgo = now.subtract(const Duration(days: 30));
    final threeMonthsAhead = now.add(const Duration(days: 90));

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'dates': '${_formatDate(oneMonthAgo)},${_formatDate(threeMonthsAhead)}',
      'ordering': '-added',
      'page_size': '25',
      'exclude_additions': 'true',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final filtered = _filterMatureContent(
          results.map((json) => Game.fromJson(json)).toList(),
        );
        final games = filtered.take(10).toList();
        _cache.set(
          CacheKeys.newReleases,
          games,
          duration: CacheService.mediumCache,
        );
        return games;
      } else {
        throw Exception('Failed to load new releases: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  Future<List<Game>> getTopRated() async {
    final cached = _cache.get<List<Game>>(CacheKeys.topRated);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'ordering': '-metacritic',
      'page_size': '25',
      'exclude_additions': 'true',
      'metacritic': '75,100',
      'ratings_count': '2000',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final filtered = _filterMatureContent(
          results.map((json) => Game.fromJson(json)).toList(),
        );
        final games = filtered.take(10).toList();
        _cache.set(CacheKeys.topRated, games, duration: CacheService.longCache);
        return games;
      } else {
        throw Exception('Failed to load top rated: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  Future<String?> getBestGameImageForYear(int year) async {
    final cacheKey = CacheKeys.yearImage(year);
    final cached = _cache.get<String>(cacheKey);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'dates': '$year-01-01,$year-12-31',
      'ordering': '-rating,-added',
      'page_size': '1',
      'exclude_additions': 'true',
      'ratings_count': '500',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        if (results.isNotEmpty) {
          final imageUrl = results[0]['background_image'] as String?;
          if (imageUrl != null) {
            _cache.set(cacheKey, imageUrl, duration: CacheService.longCache);
          }
          return imageUrl;
        }
      }
    } catch (_) {
      // Silently fail - image not critical
    }
    return null;
  }

  Future<List<Game>> getGames({
    int page = 1,
    int pageSize = 40,
    String? ordering,
    String? dates,
    String? genres,
    String? platforms,
    String? parentPlatforms,
    String? stores,
    String? tags,
    String? developers,
    String? publishers,
    String? search,
    int? metacriticMin,
    int? metacriticMax,
    int? minRatingsCount,
  }) async {
    final queryParameters = <String, String>{
      'key': ApiConfig.rawgApiKey,
      'page': page.toString(),
      'page_size': pageSize.toString(),
      'exclude_additions': 'true',
    };

    if (ordering != null) queryParameters['ordering'] = ordering;
    if (dates != null) queryParameters['dates'] = dates;
    if (genres != null) queryParameters['genres'] = genres;
    if (platforms != null) queryParameters['platforms'] = platforms;
    if (parentPlatforms != null) {
      queryParameters['parent_platforms'] = parentPlatforms;
    }
    if (stores != null) queryParameters['stores'] = stores;
    if (tags != null) queryParameters['tags'] = tags;
    if (developers != null) queryParameters['developers'] = developers;
    if (publishers != null) queryParameters['publishers'] = publishers;
    if (search != null) queryParameters['search'] = search;
    if (metacriticMin != null || metacriticMax != null) {
      queryParameters['metacritic'] =
          '${metacriticMin ?? 1},${metacriticMax ?? 100}';
    }
    if (minRatingsCount != null) {
      queryParameters['ratings_count'] = minRatingsCount.toString();
    }

    // Generate unique cache key based on non-auth parameters
    final cacheParams = Map.from(queryParameters)..remove('key');
    final paramsString = cacheParams.entries.map((e) => '${e.key}=${e.value}').join('&');
    final cacheKey = CacheKeys.gameList(paramsString);

    final cached = _cache.get<List<Game>>(cacheKey);
    if (cached != null) return cached;

    final uri = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games',
    ).replace(queryParameters: queryParameters);

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'];
        final games = _filterMatureContent(
          results.map((json) => Game.fromJson(json)).toList(),
        );
        _cache.set(cacheKey, games, duration: CacheService.shortCache);
        return games;
      } else {
        throw Exception('Failed to load games: ${response.statusCode}');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get all genres - Cached for 2 hours
  Future<List<Map<String, dynamic>>> getGenres() async {
    final cached = _cache.get<List<Map<String, dynamic>>>(CacheKeys.genres);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'ordering': '-games_count',
      'page_size': '20',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/genres',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final genres = List<Map<String, dynamic>>.from(data['results']);
        _cache.set(CacheKeys.genres, genres, duration: CacheService.longCache);
        return genres;
      } else {
        throw Exception('Failed to load genres');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get all platforms - Cached for 2 hours
  Future<List<Map<String, dynamic>>> getPlatforms() async {
    final cached = _cache.get<List<Map<String, dynamic>>>(CacheKeys.platforms);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'ordering': '-games_count',
      'page_size': '50',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/platforms',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final platforms = List<Map<String, dynamic>>.from(data['results']);
        _cache.set(
          CacheKeys.platforms,
          platforms,
          duration: CacheService.longCache,
        );
        return platforms;
      } else {
        throw Exception('Failed to load platforms');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get all stores - Cached for 2 hours
  Future<List<Map<String, dynamic>>> getStores() async {
    final cached = _cache.get<List<Map<String, dynamic>>>(CacheKeys.stores);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'ordering': '-games_count',
      'page_size': '20',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/stores',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stores = List<Map<String, dynamic>>.from(data['results']);
        _cache.set(CacheKeys.stores, stores, duration: CacheService.longCache);
        return stores;
      } else {
        throw Exception('Failed to load stores');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get popular tags - Cached for 2 hours
  Future<List<Map<String, dynamic>>> getTags() async {
    final cached = _cache.get<List<Map<String, dynamic>>>(CacheKeys.tags);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'ordering': '-games_count',
      'page_size': '40',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/tags',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final tags = List<Map<String, dynamic>>.from(data['results']);
        _cache.set(CacheKeys.tags, tags, duration: CacheService.longCache);
        return tags;
      } else {
        throw Exception('Failed to load tags');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get popular developers - Cached for 2 hours
  Future<List<Map<String, dynamic>>> getDevelopers() async {
    final cached = _cache.get<List<Map<String, dynamic>>>(CacheKeys.developers);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'ordering': '-games_count',
      'page_size': '40',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/developers',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final developers = List<Map<String, dynamic>>.from(data['results']);
        _cache.set(
          CacheKeys.developers,
          developers,
          duration: CacheService.longCache,
        );
        return developers;
      } else {
        throw Exception('Failed to load developers');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get popular publishers - Cached for 2 hours
  Future<List<Map<String, dynamic>>> getPublishers() async {
    final cached = _cache.get<List<Map<String, dynamic>>>(CacheKeys.publishers);
    if (cached != null) return cached;

    final queryParams = {
      'key': ApiConfig.rawgApiKey,
      'ordering': '-games_count',
      'page_size': '40',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/publishers',
    ).replace(queryParameters: queryParams);

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final publishers = List<Map<String, dynamic>>.from(data['results']);
        _cache.set(
          CacheKeys.publishers,
          publishers,
          duration: CacheService.longCache,
        );
        return publishers;
      } else {
        throw Exception('Failed to load publishers');
      }
    } catch (e) {
      return [];
    }
  }

  /// Get development team for a specific game
  /// Returns list of creators with their roles
  Future<List<Map<String, dynamic>>> getDevelopmentTeam(int gameId) async {
    final cacheKey = CacheKeys.developmentTeam(gameId);
    final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) return cached;

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games/$gameId/development-team?key=${ApiConfig.rawgApiKey}&page_size=40',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = List<Map<String, dynamic>>.from(data['results'] ?? []);
        _cache.set(cacheKey, result, duration: CacheService.longCache);
        return result;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get games in the same series/franchise
  Future<List<Game>> getGameSeries(int gameId) async {
    final cacheKey = CacheKeys.gameSeries(gameId);
    final cached = _cache.get<List<Game>>(cacheKey);
    if (cached != null) return cached;

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games/$gameId/game-series?key=${ApiConfig.rawgApiKey}&page_size=10',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        final games = _filterMatureContent(
          results.map((json) => Game.fromJson(json)).toList(),
        );
        _cache.set(cacheKey, games, duration: CacheService.mediumCache);
        return games;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get DLCs and editions for a game
  Future<List<Game>> getDLCsAndAdditions(int gameId) async {
    final cacheKey = CacheKeys.gameDLCs(gameId);
    final cached = _cache.get<List<Game>>(cacheKey);
    if (cached != null) return cached;

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games/$gameId/additions?key=${ApiConfig.rawgApiKey}&page_size=10',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        final games = results.map((json) => Game.fromJson(json)).toList();
        _cache.set(cacheKey, games, duration: CacheService.mediumCache);
        return games;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get individual creator details with their full portfolio
  Future<Map<String, dynamic>?> getCreatorDetails(int creatorId) async {
    final cacheKey = CacheKeys.creatorDetails(creatorId);
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) return cached;

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/creators/$creatorId?key=${ApiConfig.rawgApiKey}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _cache.set(cacheKey, data as Map<String, dynamic>, duration: CacheService.longCache);
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get stores where a game can be purchased
  Future<List<Map<String, dynamic>>> getGameStores(int gameId) async {
    final cacheKey = CacheKeys.gameStores(gameId);
    final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) return cached;

    // Map store_id to store name
    const storeNames = {
      1: 'Steam',
      2: 'Xbox Store',
      3: 'PlayStation Store',
      4: 'App Store',
      5: 'GOG',
      6: 'Nintendo Store',
      7: 'Xbox 360 Store',
      8: 'Google Play',
      9: 'itch.io',
      11: 'Epic Games',
    };

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games/$gameId/stores?key=${ApiConfig.rawgApiKey}',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        
        final result = results.map((store) {
          final storeId = store['store_id'] as int?;
          final storeName = storeNames[storeId] ?? 'Store';
          return {
            'store': {'id': storeId, 'name': storeName},
            'url': store['url'] ?? '',
          };
        }).toList();
        _cache.set(cacheKey, result, duration: CacheService.longCache);
        return result;

      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get games by a specific creator
  Future<List<Map<String, dynamic>>> getGamesByCreator(int creatorId) async {
    final cacheKey = CacheKeys.creatorGames(creatorId);
    final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
    if (cached != null) return cached;

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games?key=${ApiConfig.rawgApiKey}&creators=$creatorId&page_size=15&ordering=-added',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['results'] ?? []);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Get screenshots for a game from dedicated endpoint
  Future<List<String>> getGameScreenshots(int gameId) async {
    final cacheKey = CacheKeys.gameScreenshots(gameId);
    final cached = _cache.get<List<String>>(cacheKey);
    if (cached != null) return cached;

    final url = Uri.parse(
      '${ApiConfig.rawgBaseUrl}/games/$gameId/screenshots?key=${ApiConfig.rawgApiKey}&page_size=10',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        final urls = results
            .map((s) => s['image']?.toString() ?? '')
            .where((url) => url.isNotEmpty)
            .toList();
        _cache.set(cacheKey, urls, duration: CacheService.longCache);
        return urls;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
