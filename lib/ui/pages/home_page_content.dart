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
                return _buildUnifiedNewsCard(context, sampleNews[itemIndex]);
              },
              childCount: sampleNews.length * 2 - 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUnifiedNewsCard(BuildContext context, Map<String, dynamic> news) {
    return GestureDetector(
      onTap: () => _showNewsDetail(context, news),
      child: Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).cardColor,
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundImage: NetworkImage(news['imageUrl']),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(news['title'], maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(news['date'], style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNewsDetail(BuildContext context, Map<String, dynamic> news) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(news['title'], style: Theme.of(context).textTheme.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(news['description'], style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(news['source'], style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const Spacer(),
                Text(news['date'], style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Read More', style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}