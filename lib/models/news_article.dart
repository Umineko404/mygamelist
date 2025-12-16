import 'package:xml/xml.dart';
import 'package:intl/intl.dart';

/// Represents a gaming news article parsed from RSS feeds.
/// 
/// Supports parsing from various RSS/Atom feed formats with fallback
/// for different content and image extraction methods.
class NewsArticle {
  final String title;
  final String link;
  final String? summary;
  final String? htmlContent;
  final String? content;
  final String? imageUrl;
  final String source;
  final DateTime publishedAt;

  NewsArticle({
    required this.title,
    required this.link,
    this.summary,
    this.htmlContent,
    this.content,
    this.imageUrl,
    required this.source,
    required this.publishedAt,
  });

  static String _stripHtml(String htmlString) {
    return htmlString.replaceAll(RegExp(r'<[^>]*>'), '');
  }

  static DateTime _parseDate(String? dateStr) {
    if (dateStr == null) return DateTime.now();
    try {
      return DateFormat('EEE, d MMM yyyy HH:mm:ss Z').parse(dateStr);
    } catch (e) {
      try {
        return DateTime.parse(dateStr);
      } catch (_) {
        return DateTime.now();
      }
    }
  }

  factory NewsArticle.fromXml(XmlElement item, String sourceFn) {
    String? getText(String tag) {
      return item.findElements(tag).firstOrNull?.innerText;
    }

    final title = getText('title') ?? 'No Title';
    final link =
        getText('link') ??
        item.findElements('link').firstOrNull?.getAttribute('href') ??
        '';
    final pubDateStr =
        getText('pubDate') ?? getText('updated') ?? getText('date');
    final publishedAt = _parseDate(pubDateStr);

    String? img;

    final enclosure = item.findElements('enclosure').firstOrNull;
    if (enclosure != null) {
      img = enclosure.getAttribute('url');
    }

    if (img == null) {
      for (var child in item.children) {
        if (child is XmlElement) {
          if (child.name.local == 'content' && child.name.prefix == 'media') {
            img = child.getAttribute('url');
            if (img != null) break;
          }
        }
      }
    }

    String? description = getText('description');
    String? contentEncoded;

    for (var child in item.children) {
      if (child is XmlElement) {
        if (child.name.local == 'encoded' && child.name.prefix == 'content') {
          contentEncoded = child.innerText;
          break;
        }
      }
    }

    if (img == null) {
      if (contentEncoded != null) {
        final match = RegExp(
          r'<img[^>]+src="([^">]+)"',
        ).firstMatch(contentEncoded);
        if (match != null) img = match.group(1);
      }
    }
    if (img == null && description != null) {
      final match = RegExp(r'<img[^>]+src="([^">]+)"').firstMatch(description);
      if (match != null) img = match.group(1);
    }

    String rawHtml = contentEncoded ?? description ?? '';
    String rawText = rawHtml.isEmpty ? title : rawHtml;
    String cleanText = _stripHtml(rawText).trim();

    String summaryText = cleanText;
    if (summaryText.length > 200) {
      summaryText = '${summaryText.substring(0, 200)}...';
    }

    String contentText = cleanText;
    if (contentText.length > 1000) {
      contentText = '${contentText.substring(0, 1000)}...';
    }

    return NewsArticle(
      title: title,
      link: link,
      summary: summaryText,
      htmlContent: rawHtml.isNotEmpty ? rawHtml : null,
      content: contentText,
      imageUrl: img,
      source: sourceFn,
      publishedAt: publishedAt,
    );
  }

  String get formattedDate {
    final now = DateTime.now();
    final diff = now.difference(publishedAt);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else {
      return '${publishedAt.month}/${publishedAt.day}/${publishedAt.year}';
    }
  }
}
