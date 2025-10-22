import 'package:flutter/material.dart';
import '../../data/sample_data.dart';

class HomePageContent extends StatelessWidget {
  const HomePageContent({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) {
                if (index.isOdd) {
                  return Divider(
                    height: 0,
                    thickness: 1,
                    color: Colors.grey.withAlpha(128),
                  );
                }
                final itemIndex = index ~/ 2;
                return NewsCard(news: sampleNews[itemIndex]);
              },
              childCount: sampleNews.length * 2 - 1,
            ),
          ),
        ),
      ],
    );
  }
}

class NewsCard extends StatelessWidget {
  final Map<String, dynamic> news;

  const NewsCard({
    super.key,
    required this.news,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Theme.of(context).cardColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 35,
            backgroundImage: NetworkImage(news['imageUrl']),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  news['title'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _getCategoryIcon(),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              news['source'],
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.circle,
                              size: 4, color: Colors.grey.withAlpha(128)),
                          const SizedBox(width: 8),
                          Text(
                            news['date'],
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  news['description'],
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            children: [
              Icon(
                Icons.bookmark_border,
                color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
                size: 22,
              ),
              const SizedBox(height: 12),
              Icon(
                Icons.share_outlined,
                color: Theme.of(context).iconTheme.color?.withValues(alpha:0.6),
                size: 22,
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _getCategoryIcon() {
    return Icon(Icons.article, size: 16, color: Colors.grey[600]);
  }
}