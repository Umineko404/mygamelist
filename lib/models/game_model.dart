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
    // Helper to convert Firebase map-with-numeric-keys back to List
    List<dynamic> ensureList(dynamic value) {
      if (value == null) return [];
      if (value is List) return value;
      if (value is Map) {
        // Firebase converts lists to maps with numeric string keys
        return value.values.toList();
      }
      return [];
    }

    String getGenres(dynamic genres) {
      if (genres == null) return 'Unknown';
      // If it's already a string (from our saved data), return it
      if (genres is String) return genres;
      final list = ensureList(genres);
      if (list.isEmpty) return 'Unknown';
      // Check if it's RAWG format (objects with 'name') or our format (strings)
      if (list.first is Map) {
        return list.take(3).map((g) => g['name']?.toString() ?? '').join(', ');
      }
      return list.take(3).map((g) => g.toString()).join(', ');
    }

    String getPlatforms(dynamic platforms) {
      if (platforms == null) return 'Unknown';
      // If it's already a string (from our saved data), return it
      if (platforms is String) return platforms;
      final list = ensureList(platforms);
      if (list.isEmpty) return 'Unknown';
      // Check if it's RAWG format or our format
      if (list.first is Map && list.first['platform'] != null) {
        return list
            .take(3)
            .map((p) => p['platform']['name']?.toString() ?? '')
            .join(', ');
      }
      return list.take(3).map((p) => p.toString()).join(', ');
    }

    String getEsrbRating(dynamic esrb) {
      if (esrb == null) return '';
      if (esrb is String) return esrb;
      if (esrb is Map) return esrb['slug']?.toString() ?? '';
      return '';
    }

    List<String> getTags(dynamic tags) {
      final list = ensureList(tags);
      if (list.isEmpty) return [];
      // Check if it's RAWG format (objects with 'slug') or our format (strings)
      return list.map((t) {
        if (t is Map) return t['slug']?.toString() ?? '';
        return t.toString();
      }).where((s) => s.isNotEmpty).toList().cast<String>();
    }

    int? getHighestMetacritic(int? directMetacritic, dynamic platforms) {
      int? highest = directMetacritic;
      final list = ensureList(platforms);

      if (list.isNotEmpty) {
        for (var platform in list) {
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

    List<String> getDevelopers(dynamic devs) {
      final list = ensureList(devs);
      if (list.isEmpty) return [];
      return list.map((d) {
        if (d is Map) return d['name']?.toString() ?? '';
        return d.toString();
      }).where((s) => s.isNotEmpty).toList().cast<String>();
    }

    List<String> getPublishers(dynamic pubs) {
      final list = ensureList(pubs);
      if (list.isEmpty) return [];
      return list.map((p) {
        if (p is Map) return p['name']?.toString() ?? '';
        return p.toString();
      }).where((s) => s.isNotEmpty).toList().cast<String>();
    }

    List<Map<String, String>> getStores(dynamic stores) {
      final list = ensureList(stores);
      if (list.isEmpty) return [];
      return list.map((s) {
        if (s is Map) {
          // Check if it's RAWG format or our format
          if (s['store'] != null) {
            final storeName = s['store']?['name']?.toString() ?? '';
            final storeUrl = s['url']?.toString() ?? '';
            if (storeName.isNotEmpty) {
              return {'name': storeName, 'url': storeUrl};
            }
          } else {
            // Our saved format
            final name = s['name']?.toString() ?? '';
            final url = s['url']?.toString() ?? '';
            if (name.isNotEmpty) {
              return {'name': name, 'url': url};
            }
          }
        }
        return null;
      }).whereType<Map<String, String>>().toList();
    }

    List<String> getScreenshots(Map<String, dynamic> json) {
      // First try our saved format
      final screenshots = ensureList(json['screenshots']);
      if (screenshots.isNotEmpty) {
        return screenshots.map((s) {
          if (s is Map) return s['image']?.toString() ?? '';
          return s.toString();
        }).where((url) => url.isNotEmpty).take(8).toList().cast<String>();
      }
      // Then try RAWG format
      final shortScreenshots = ensureList(json['short_screenshots']);
      if (shortScreenshots.isNotEmpty) {
        return shortScreenshots
            .skip(1)
            .take(6)
            .map((s) {
              if (s is Map) return s['image']?.toString() ?? '';
              return s.toString();
            })
            .where((url) => url.isNotEmpty)
            .toList()
            .cast<String>();
      }
      return [];
    }

    return Game(
      id: json['id'] ?? 0,
      slug: json['slug'] ?? '',
      title: json['name'] ?? json['title'] ?? 'Unknown Title',
      genre: json['genre'] is String ? json['genre'] : getGenres(json['genres']),
      platform: json['platform'] is String ? json['platform'] : getPlatforms(json['platforms']),
      metacritic: getHighestMetacritic(
        json['metacritic'] as int?,
        json['metacritic_platforms'],
      ),
      rawgRating: (json['rating'] ?? json['rawgRating'] as num?)?.toDouble() ?? 0,
      rawgRatingCount: json['ratings_count'] ?? json['rawgRatingCount'] as int? ?? 0,
      platformRating: (json['platformRating'] as num?)?.toDouble(),
      platformRatingCount: json['platformRatingCount'] as int? ?? 0,
      imageUrl: json['background_image'] ?? json['imageUrl'] ?? '',
      description: json['description_raw'] ?? json['description'] ?? '',
      releaseDate: json['released'] ?? json['releaseDate'] ?? 'Unknown',
      esrbRating: json['esrbRating'] is String ? json['esrbRating'] : getEsrbRating(json['esrb_rating']),
      tags: getTags(json['tags']),
      addedCount: json['added'] ?? json['addedCount'] ?? 0,
      developers: getDevelopers(json['developers']),
      publishers: getPublishers(json['publishers']),
      stores: getStores(json['stores']),
      playtime: json['playtime'] as int?,
      website: json['website'] as String?,
      redditUrl: json['reddit_url'] as String?,
      screenshots: getScreenshots(json),
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
      status: status ?? this.status,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
