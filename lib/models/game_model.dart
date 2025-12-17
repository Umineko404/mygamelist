/// Represents a video game with data from RAWG API and user-specific fields.
/// 
/// Combines external API data (ratings, metadata) with local user data
/// (library status, personal rating, favorites).
class Game {
  final int id;
  final String slug;
  final String title;
  final String genre;
  final String platform;
  final int? metacritic;
  final double rawgRating;
  final int rawgRatingCount;
  final double? platformRating;
  final int platformRatingCount;
  final String imageUrl;
  final String description;
  final String releaseDate;
  final String esrbRating;
  final List<String> tags;
  final int addedCount;
  final List<String> developers;
  final List<String> publishers;
  final List<Map<String, String>> stores;
  final int? playtime;
  final String? website;
  final String? redditUrl;
  final List<String> screenshots;
  final double? personalRating;
  final String? playedOnPlatform;
  final String status;
  final bool isFavorite;

  Game({
    required this.id,
    this.slug = '',
    required this.title,
    required this.genre,
    required this.platform,
    this.metacritic,
    this.rawgRating = 0,
    this.rawgRatingCount = 0,
    this.platformRating,
    this.platformRatingCount = 0,
    required this.imageUrl,
    required this.description,
    required this.releaseDate,
    this.esrbRating = '',
    this.tags = const [],
    this.addedCount = 0,
    this.developers = const [],
    this.publishers = const [],
    this.stores = const [],
    this.playtime,
    this.website,
    this.redditUrl,
    this.screenshots = const [],
    this.personalRating,
    this.playedOnPlatform,
    this.status = 'Plan to Play',
    this.isFavorite = false,
  });

  /// Checks for NSFW content based on tag slugs.
  bool get hasNsfwTags {
    const nsfwTags = [
      'sexual-content',
      'nsfw',
      'hentai',
      'adult',
      'erotic',
    ];
    return tags.any((tag) => nsfwTags.contains(tag.toLowerCase()));
  }

  /// Returns true if game has Adults Only ESRB rating.
  bool get isMatureRated => esrbRating == 'adults-only';

  /// Returns true if game has any displayable rating.
  bool get hasRating => metacritic != null || rawgRating > 0;

  /// Unified rating value for display (0-100 scale).
  /// Prefers Metacritic; converts RAWG 0-5 scale using tier mapping.
  int? get displayRatingValue {
    if (metacritic != null) return metacritic;

    if (rawgRating > 0) {
      // Tier-based conversion to align with Metacritic color zones
      if (rawgRating >= 4.5) return 92;
      if (rawgRating >= 4.0) return 85;
      if (rawgRating >= 3.5) return 75;
      if (rawgRating >= 3.0) return 65;
      if (rawgRating >= 2.5) return 55;
      if (rawgRating >= 2.0) return 45;
      return (rawgRating * 20).round();
    }

    return null;
  }

  factory Game.fromJson(Map<String, dynamic> json) {
    String getGenres(dynamic genresData) {
      // If we already have the computed string from Firebase, use it
      if (json['genre'] is String && (json['genre'] as String).isNotEmpty) {
        return json['genre'];
      }
      
      if (genresData == null || genresData is! List || genresData.isEmpty) return 'Unknown';
      return genresData.take(3).map((g) => g['name'].toString()).join(', ');
    }

    String getPlatforms(dynamic platformsData) {
      // If we already have the computed string from Firebase, use it
      if (json['platform'] is String && (json['platform'] as String).isNotEmpty) {
        return json['platform'];
      }

      if (platformsData == null || platformsData is! List || platformsData.isEmpty) return 'Unknown';
      return platformsData
          .take(3)
          .map((p) => p['platform']['name'].toString())
          .join(', ');
    }

    String getEsrbRating(dynamic esrb) {
      if (esrb is String) return esrb; // Handle Firebase stored format
      if (esrb == null || esrb is! Map) return '';
      return esrb['slug']?.toString() ?? '';
    }

    List<String> getTags(List<dynamic>? tagsJson) {
      if (tagsJson == null || tagsJson.isEmpty) return [];
      
      // Handle Firebase format (List<String>)
      if (tagsJson.first is String) {
        return tagsJson.cast<String>();
      }

      // Handle RAWG format (List<Map>)
      return tagsJson
          .map((t) => t is Map ? (t['slug']?.toString() ?? '') : '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    int? getHighestMetacritic(int? directMetacritic, List<dynamic>? platforms) {
      int? highest = directMetacritic;

      if (platforms != null && platforms.isNotEmpty) {
        for (var platform in platforms) {
          if (platform is Map) {
            final score = platform['metascore'] as int?;
            if (score != null && (highest == null || score > highest)) {
              highest = score;
            }
          }
        }
      }

      return highest;
    }

    List<String> getDevelopers(List<dynamic>? devs) {
      if (devs == null || devs.isEmpty) return [];
      if (devs.first is String) return devs.cast<String>();
      
      return devs
          .map((d) => d is Map ? (d['name']?.toString() ?? '') : '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    List<String> getPublishers(List<dynamic>? pubs) {
      if (pubs == null || pubs.isEmpty) return [];
      if (pubs.first is String) return pubs.cast<String>();

      return pubs
          .map((p) => p is Map ? (p['name']?.toString() ?? '') : '')
          .where((s) => s.isNotEmpty)
          .toList();
    }

    List<Map<String, String>> getStores(List<dynamic>? storesJson) {
      if (storesJson == null || storesJson.isEmpty) return [];
      
      // Already correct format (from Firebase)
      if (storesJson.first is Map<String, String>) {
         return storesJson.cast<Map<String, String>>();
      }
      
      // Handle generic Map from JSON (Firebase or RAWG)
      return storesJson
          .map((s) {
            if (s is Map) {
              // Firebase stored format often looks like {name: 'Steam', url: '...'} directly inside the list
              if (s.containsKey('name') && s.containsKey('url')) {
                 return {'name': s['name'].toString(), 'url': s['url'].toString()};
              }
              // RAWG format: {store: {name: ...}, url: ...}
              final storeName = s['store']?['name']?.toString() ?? '';
              final storeUrl = s['url']?.toString() ?? '';
              if (storeName.isNotEmpty && storeUrl.isNotEmpty) {
                return {'name': storeName, 'url': storeUrl};
              }
            }
            return null;
          })
          .whereType<Map<String, String>>()
          .toList();
    }

    List<String> getScreenshots(Map<String, dynamic> json) {
      // Handle Firebase stored format (simple list of strings)
      if (json['screenshots'] != null && 
          json['screenshots'] is List && 
          (json['screenshots'] as List).isNotEmpty &&
          (json['screenshots'] as List).first is String) {
        return (json['screenshots'] as List).cast<String>();
      }

      // Handle RAWG format
      if (json['screenshots'] != null &&
          json['screenshots'] is List &&
          (json['screenshots'] as List).isNotEmpty) {
        return (json['screenshots'] as List)
            .take(8)
            .map((s) => s is Map ? (s['image']?.toString() ?? '') : '')
            .where((url) => url.isNotEmpty)
            .toList();
      }
      if (json['short_screenshots'] != null &&
          json['short_screenshots'] is List) {
        return (json['short_screenshots'] as List)
            .skip(1)
            .take(6)
            .map((s) => s is Map ? (s['image']?.toString() ?? '') : '')
            .where((url) => url.isNotEmpty)
            .toList();
      }
      return [];
    }

    return Game(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      title: json['name'] ?? json['title'] ?? 'Unknown Title',
      genre: getGenres(json['genres']),
      platform: getPlatforms(json['platforms']),
      metacritic: getHighestMetacritic(
        json['metacritic'] as int?,
        json['metacritic_platforms'] as List<dynamic>?,
      ),
      rawgRating: (json['rating'] as num?)?.toDouble() ?? 0,
      rawgRatingCount: json['ratings_count'] as int? ?? 0,
      platformRating: (json['platformRating'] as num?)?.toDouble(),
      platformRatingCount: json['platformRatingCount'] as int? ?? 0,
      imageUrl: json['background_image'] ?? json['imageUrl'] ?? '',
      description: json['description_raw'] ?? json['description'] ?? '',
      releaseDate: json['released'] ?? json['releaseDate'] ?? 'Unknown',
      esrbRating: getEsrbRating(json['esrb_rating'] ?? json['esrbRating']),
      tags: getTags(json['tags']),
      addedCount: json['added'] ?? json['addedCount'] ?? 0,
      developers: getDevelopers(json['developers']),
      publishers: getPublishers(json['publishers']),
      stores: getStores(json['stores']),
      playtime: json['playtime'] as int?,
      website: json['website'] as String?,
      redditUrl: json['reddit_url'] as String?,
      screenshots: getScreenshots(json),
      personalRating: (json['personalRating'] as num?)?.toDouble(),
      playedOnPlatform: json['playedOnPlatform'] as String?,
      status: json['status'] ?? 'Plan to Play',
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'genre': genre,
      'platform': platform,
      'metacritic': metacritic,
      'rawgRating': rawgRating,
      'rawgRatingCount': rawgRatingCount,
      'platformRating': platformRating,
      'platformRatingCount': platformRatingCount,
      'imageUrl': imageUrl,
      'description': description,
      'releaseDate': releaseDate,
      'esrbRating': esrbRating,
      'tags': tags,
      'addedCount': addedCount,
      'developers': developers,
      'publishers': publishers,
      'stores': stores,
      'playtime': playtime,
      'website': website,
      'redditUrl': redditUrl,
      'screenshots': screenshots,
      'personalRating': personalRating,
      'playedOnPlatform': playedOnPlatform,
      'status': status,
      'isFavorite': isFavorite,
    };
  }

  Game copyWith({
    int? id,
    String? slug,
    String? title,
    String? genre,
    String? platform,
    int? metacritic,
    double? rawgRating,
    int? rawgRatingCount,
    double? platformRating,
    int? platformRatingCount,
    String? imageUrl,
    String? description,
    String? releaseDate,
    String? esrbRating,
    List<String>? tags,
    int? addedCount,
    List<String>? developers,
    List<String>? publishers,
    List<Map<String, String>>? stores,
    int? playtime,
    String? website,
    String? redditUrl,
    List<String>? screenshots,
    double? personalRating,
    String? playedOnPlatform,
    String? status,
    bool? isFavorite,
  }) {
    return Game(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      genre: genre ?? this.genre,
      platform: platform ?? this.platform,
      metacritic: metacritic ?? this.metacritic,
      rawgRating: rawgRating ?? this.rawgRating,
      rawgRatingCount: rawgRatingCount ?? this.rawgRatingCount,
      platformRating: platformRating ?? this.platformRating,
      platformRatingCount: platformRatingCount ?? this.platformRatingCount,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      releaseDate: releaseDate ?? this.releaseDate,
      esrbRating: esrbRating ?? this.esrbRating,
      tags: tags ?? this.tags,
      addedCount: addedCount ?? this.addedCount,
      developers: developers ?? this.developers,
      publishers: publishers ?? this.publishers,
      stores: stores ?? this.stores,
      playtime: playtime ?? this.playtime,
      website: website ?? this.website,
      redditUrl: redditUrl ?? this.redditUrl,
      screenshots: screenshots ?? this.screenshots,
      personalRating: personalRating ?? this.personalRating,
      playedOnPlatform: playedOnPlatform ?? this.playedOnPlatform,
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
