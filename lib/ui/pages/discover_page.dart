import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/game_manager.dart';
import '../../models/game_model.dart';
import '../../data/sample_data.dart';
import 'game_detail_page.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});
  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Game> _getSearchResults(List<Game> allGames) {
    if (_searchQuery.isEmpty) return [];
    return allGames
        .where((game) =>
    game.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        game.genre.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final List<Game> allGames = gameManager.games;
        final List<Game> searchResults = _getSearchResults(allGames);
        final bool isSearching = _searchQuery.isNotEmpty;
        final trendingGames = [
          allGames.firstWhere((g) => g.title == 'Metaphor ReFantazio', orElse: () => sampleGames[5]),
          allGames.firstWhere((g) => g.title == 'Persona 3 Reload', orElse: () => sampleGames[0]),
        ];
        final upcomingGames = allGames.where((game) => (int.tryParse(game.releaseDate) ?? 0) >= 2025).toList();
        final topRatedGames = allGames.where((game) => game.rating > 0).toList()..sort((a, b) => b.rating.compareTo(a.rating));
        final top6RatedGames = topRatedGames.take(6).toList();
        final List<Widget> defaultContent = [
          _buildSectionHeader('🔥 Trending Now'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildUnifiedCard(trendingGames[index], 'trending'),
                childCount: trendingGames.length,
              ),
            ),
          ),
          _buildSectionHeader('⏰ Upcoming'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildUnifiedCard(upcomingGames[index], 'upcoming'),
                childCount: upcomingGames.length,
              ),
            ),
          ),
          _buildSectionHeader('⭐ Top Rated'),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16),
              delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildUnifiedCard(top6RatedGames[index], 'top'),
                childCount: top6RatedGames.length,
              ),
            ),
          ),
        ];

        final List<Widget> searchContent = [
          if (searchResults.isNotEmpty) ...[
            _buildSectionHeader('🔍 Search Results (${searchResults.length})'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 16, mainAxisSpacing: 16),
                delegate: SliverChildBuilderDelegate((context, index) => _buildUnifiedCard(searchResults[index], 'search'), childCount: searchResults.length),
              ),
            ),
          ] else ...[
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text('No games found for "$_searchQuery"', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  ],
                ),
              ),
            )
          ]
        ];

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search games...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                    prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).textTheme.bodyMedium?.color),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear_rounded, color: Theme.of(context).textTheme.bodyMedium?.color),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                ),
              ),
            ),
            if (isSearching) ...searchContent else ...defaultContent,
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
            TextButton(
              onPressed: () => _showSeeAll(context, title),
              child: Text('See All', style: TextStyle(color: Colors.grey[400])),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnifiedCard(Game game, String sectionType) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GameDetailPage(game: game))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(image: NetworkImage(game.imageUrl), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withAlpha(204)]),
              ),
            ),
            Positioned(top: 8, left: 8, child: _buildSectionBadge(sectionType)),
            if (game.rating > 0)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 12),
                      const SizedBox(width: 2),
                      Text(game.rating.toStringAsFixed(1), style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontSize: 11)),
                    ],
                  ),
                ),
              ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title, maxLines: 2, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600, shadows: [Shadow(blurRadius: 2)])),
                  const SizedBox(height: 4),
                  Text(game.genre, style: TextStyle(color: Colors.grey[200], fontSize: 12, shadows: const [Shadow(blurRadius: 2)])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionBadge(String sectionType) {
    IconData icon;
    Color color;
    switch (sectionType) {
      case 'trending':
        icon = Icons.trending_up;
        color = const Color(0xFFF59E0B);
        break;
      case 'upcoming':
        icon = Icons.schedule;
        color = const Color(0xFF10B981);
        break;
      case 'top':
        icon = Icons.star;
        color = Theme.of(context).colorScheme.primary;
        break;
      case 'search':
        icon = Icons.search;
        color = Theme.of(context).colorScheme.secondary;
        break;
      default:
        icon = Icons.explore;
        color = Theme.of(context).colorScheme.primary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(sectionType.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showSeeAll(BuildContext context, String section) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$section - Coming Soon! 🎮'), backgroundColor: Theme.of(context).colorScheme.primary, behavior: SnackBarBehavior.floating));
  }
}