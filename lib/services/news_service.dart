import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';
import '../models/news_article.dart';
import 'cache_service.dart';

/// Service for fetching gaming news from RSS feeds.
/// 
/// Aggregates news from multiple gaming platforms and caches results
/// to minimize network requests. Uses CORS proxy for web platform.
class NewsService {
  final CacheService _cache = CacheService();

  static const _playstationFeedUrl = 'https://blog.playstation.com/feed/';

  /// Fetches and aggregates news from all configured RSS feeds.
  /// Returns cached data if available unless [forceRefresh] is true.
  Future<List<NewsArticle>> getPlatformNews({bool forceRefresh = false}) async {
    if (!forceRefresh) {
      final cached = _cache.get<List<NewsArticle>>('news_feed_rss_v12');
      if (cached != null) return cached;
    }

    final List<NewsArticle> allNews = [];

    await _fetchPlatformNews(
      _playstationFeedUrl,
      'PlayStation',
    ).then((news) => allNews.addAll(news)).catchError((e) {
      debugPrint('PS Error: $e');
    });

    allNews.sort((a, b) => b.publishedAt.compareTo(a.publishedAt));

    _cache.set('news_feed_rss_v12', allNews, duration: CacheService.newsCache);

    return allNews;
  }

  String _proxyUrl(String url) {
    if (kIsWeb) {
      return 'https://api.allorigins.win/raw?url=${Uri.encodeComponent(url)}';
    }
    return url;
  }

  Future<http.Response> _get(String url) {
    return http.get(
      Uri.parse(_proxyUrl(url)),
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
        'Accept': 'application/rss+xml, application/xml, text/xml, */*',
      },
    );
  }

  Future<List<NewsArticle>> _fetchPlatformNews(
    String url,
    String sourceName,
  ) async {
    try {
      final response = await _get(url);
      if (response.statusCode == 200) {
        final doc = XmlDocument.parse(response.body);
        final items = doc
            .findAllElements('item')
            .followedBy(doc.findAllElements('entry'));
        return items
            .map((node) => NewsArticle.fromXml(node, sourceName))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching $sourceName: $e');
    }
    return [];
  }
}
