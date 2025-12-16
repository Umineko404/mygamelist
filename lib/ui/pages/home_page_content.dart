import 'package:flutter/material.dart';
import '../../models/news_article.dart';
import '../../services/news_service.dart';
import 'news_detail_page.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  final NewsService _newsService = NewsService();
  final ScrollController _scrollController = ScrollController();

  List<NewsArticle> _allArticles = [];
  int _visibleCount = 10;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNews();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  void _loadMore() {
    if (_visibleCount < _allArticles.length) {
      setState(() {
        _visibleCount += 10;
      });
    }
  }

  Future<void> _loadNews() async {
    try {
      final articles = await _newsService.getPlatformNews();
      if (mounted) {
        setState(() {
          _allArticles = articles;
          _visibleCount = 10;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Failed to load news source";
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    try {
      final articles = await _newsService.getPlatformNews(forceRefresh: true);
      if (mounted) {
        setState(() {
          _allArticles = articles;
          _visibleCount = 10;
          _isLoading = false;
          _errorMessage = null; // Clear error on success
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null && _allArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rss_feed, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Unable to load news feed',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextButton(onPressed: _refresh, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_allArticles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rss_feed, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No news available',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final displayCount = _visibleCount.clamp(0, _allArticles.length);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                if (index.isOdd) {
                  return Divider(
                    height: 0,
                    thickness: 1,
                    color: Colors.grey.withAlpha(128),
                  );
                }
                final itemIndex = index ~/ 2;
                return NewsCard(article: _allArticles[itemIndex]);
              }, childCount: displayCount * 2 - 1),
            ),
          ),
          if (displayCount < _allArticles.length)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}

class NewsCard extends StatelessWidget {
  final NewsArticle article;

  const NewsCard({super.key, required this.article});

  Future<void> _openArticle(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => NewsDetailPage(article: article)),
    );
  }

  Widget _buildFallbackImage(BuildContext context) {
    IconData icon;
    Color color;

    switch (article.source) {
      case 'PlayStation':
        icon = Icons.gamepad;
        color = Colors.indigo;
        break;
      default:
        icon = Icons.article;
        color = Colors.grey;
    }

    return Container(
      width: 80,
      height: 80,
      color: color.withAlpha(30),
      child: Center(child: Icon(icon, color: color.withAlpha(150), size: 32)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openArticle(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).cardColor,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Article image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: article.imageUrl != null && article.imageUrl!.isNotEmpty
                  ? Image.network(
                      article.imageUrl!,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildFallbackImage(context),
                    )
                  : _buildFallbackImage(context),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildSourceBadge(context),
                      const SizedBox(width: 8),
                      Text(
                        article.formattedDate,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (article.summary != null)
                    Text(
                      article.summary!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceBadge(BuildContext context) {
    Color color;
    switch (article.source) {
      case 'PlayStation':
        color = Colors.indigo[600]!;
        break;
      default:
        color = Colors.grey[700]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        article.source,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
