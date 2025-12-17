/// In-memory cache service with TTL support.
/// 
/// Singleton implementation for caching API responses
/// to reduce network calls and improve performance.
class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  final Map<String, _CacheEntry> _cache = {};

  /// Cache duration presets.
  static const Duration shortCache = Duration(minutes: 5);
  static const Duration mediumCache = Duration(minutes: 30);
  static const Duration longCache = Duration(hours: 2);
  static const Duration newsCache = Duration(hours: 1);

  /// Retrieves cached data by key, returns null if expired or not found.
  T? get<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(key);
      return null;
    }

    return entry.data as T?;
  }

  /// Stores data in cache with specified TTL duration.
  void set<T>(String key, T data, {Duration duration = mediumCache}) {
    _cache[key] = _CacheEntry(
      data: data,
      expiresAt: DateTime.now().add(duration),
    );
  }

  /// Removes a specific entry from cache.
  void remove(String key) {
    _cache.remove(key);
  }
}

class _CacheEntry {
  final dynamic data;
  final DateTime expiresAt;

  _CacheEntry({required this.data, required this.expiresAt});
}

/// Cache key constants for consistent key naming.
class CacheKeys {
  CacheKeys._();

  // Game lists
  static const String trending = 'games_trending';
  static const String newReleases = 'games_new_releases';
  static const String topRated = 'games_top_rated';

  // Categories
  static const String genres = 'categories_genres';
  static const String platforms = 'categories_platforms';
  static const String stores = 'categories_stores';
  static const String tags = 'categories_tags';
  static const String developers = 'categories_developers';
  static const String publishers = 'categories_publishers';

  // Other
  static const String news = 'news_articles_v2';

  // Dynamic keys
  static String gameDetails(int id) => 'game_details_$id';
  static String bestOfYear(int year) => 'games_best_of_$year';
  static String yearImage(int year) => 'image_year_$year';
  static String gameList(String params) => 'games_list_$params';
  static String search(String query) => 'search_$query';
  
  static String gameSeries(int id) => 'game_series_$id';
  static String gameDLCs(int id) => 'game_dlcs_$id';
  static String gameStores(int id) => 'game_stores_$id';
  static String gameScreenshots(int id) => 'game_screenshots_$id';
  static String creatorDetails(int id) => 'creator_details_$id';
  static String creatorGames(int id) => 'creator_games_$id';
  static String developmentTeam(int id) => 'game_team_$id';
}
