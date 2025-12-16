import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/game_manager.dart';
import '../../models/game_model.dart';
import 'game_detail_page.dart';
import 'universal_game_list_page.dart';
import 'category_list_page.dart';
import 'best_of_year_page.dart';

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

  void _performSearch(String query) {
    setState(() {
      _searchQuery = query;
    });
    Provider.of<GameManager>(context, listen: false).searchGames(query);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final searchResults = gameManager.searchResults;
        final trending = gameManager.trendingGames;
        final newReleases = gameManager.newReleases;
        final topRated = gameManager.topRated;
        final bool isSearching = _searchQuery.isNotEmpty;
        final bool isLoading = gameManager.isLoading;

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onSubmitted: _performSearch,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: 'Search games...',
                    hintStyle: Theme.of(context).textTheme.bodyMedium,
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear_rounded,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.color,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _performSearch('');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            if (isLoading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (isSearching && searchResults.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Text('No games found for "$_searchQuery"'),
                ),
              )
            else if (isSearching)
              _buildGridList(searchResults, 'Search Results')
            else ...[
              SliverToBoxAdapter(child: _buildBrowseSection(context)),

              _buildSectionHeader(
                'New & Upcoming',
                onTap: () {
                  final now = DateTime.now();
                  final oneMonthAgo = now.subtract(const Duration(days: 30));
                  final threeMonthsAhead = now.add(const Duration(days: 90));
                  String formatDate(DateTime d) =>
                      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UniversalGameListPage(
                        title: 'New & Upcoming',
                        dates:
                            '${formatDate(oneMonthAgo)},${formatDate(threeMonthsAhead)}',
                        ordering: '-added',
                        minRatingsCount: 10,
                        parentPlatforms: '1,2,3,8', // PC, PS, Xbox, Nintendo
                      ),
                    ),
                  );
                },
              ),
              _buildHorizontalGameList(newReleases),

              _buildSectionHeader(
                'Trending Now',
                onTap: () {
                  final now = DateTime.now();
                  final sixMonthsAgo = now.subtract(const Duration(days: 180));
                  String formatDate(DateTime d) =>
                      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UniversalGameListPage(
                        title: 'Trending Now',
                        dates: '${formatDate(sixMonthsAgo)},${formatDate(now)}',
                        ordering: '-added',
                        minRatingsCount: 10,
                        parentPlatforms: '1,2,3,8',
                      ),
                    ),
                  );
                },
              ),
              _buildHorizontalGameList(trending),

              _buildSectionHeader(
                'Top Rated',
                onTap: () {
                  // Best rated games by Metacritic (critic scores)
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UniversalGameListPage(
                        title: 'Top Rated',
                        ordering: '-metacritic', // Sort by Metacritic score
                      ),
                    ),
                  );
                },
              ),
              _buildHorizontalGameList(topRated),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, {VoidCallback? onTap}) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (onTap != null)
              GestureDetector(
                onTap: onTap,
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseSection(BuildContext context) {
    final now = DateTime.now();
    String formatDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final categories = [
      {
        'icon': Icons.gamepad,
        'label': 'Platforms',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CategoryListPage(type: CategoryType.platforms),
          ),
        ),
      },
      {
        'icon': Icons.category,
        'label': 'Genres',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CategoryListPage(type: CategoryType.genres),
          ),
        ),
      },
      {
        'icon': Icons.store,
        'label': 'Stores',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const CategoryListPage(type: CategoryType.stores),
          ),
        ),
      },
      {
        'icon': Icons.calendar_today,
        'label': 'Releases',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UniversalGameListPage(
              title: 'Upcoming Releases',
              dates:
                  '${formatDate(now)},${formatDate(now.add(const Duration(days: 365)))}',
              ordering: '-released',
            ),
          ),
        ),
      },
      {
        'icon': Icons.emoji_events,
        'label': 'Best of',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const BestOfYearPage()),
        ),
      },
      {
        'icon': Icons.local_fire_department,
        'label': 'Popular',
        'action': () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const UniversalGameListPage(
              title: 'Popular Games',
              ordering: '-added',
              minRatingsCount: 10,
              parentPlatforms: '1,2,3,8',
            ),
          ),
        ),
      },
    ];

    return SizedBox(
      height: 100,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return GestureDetector(
            onTap: category['action'] as VoidCallback?,
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              width: 70,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Icon(
                      category['icon'] as IconData,
                      color: Theme.of(context).iconTheme.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category['label'] as String,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalGameList(List<Game> games) {
    if (games.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox(
          height: 200,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 220,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: games.length,
          itemBuilder: (context, index) {
            return Container(
              width: 150,
              margin: const EdgeInsets.only(right: 16),
              child: _buildUnifiedCard(games[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildGridList(List<Game> games, String title) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => _buildUnifiedCard(games[index]),
          childCount: games.length,
        ),
      ),
    );
  }

  Widget _buildUnifiedCard(Game game) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GameDetailPage(game: game)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: game.imageUrl.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(game.imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {},
                )
              : null,
          color: Colors.grey[800],
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withAlpha(220)],
                ),
              ),
            ),
            // Rating badge in top right (Metacritic or RAWG fallback)
            if (game.hasRating)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMetacriticColor(game.displayRatingValue!),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    game.displayRatingValue.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            // Title at bottom
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                game.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 2)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getMetacriticColor(int score) {
    // Metacritic-style color coding
    if (score >= 90) {
      return const Color(0xFF00AA00); // Dark green - Universal Acclaim
    }
    if (score >= 75) {
      return const Color(0xFF66CC33); // Green - Generally Favorable
    }
    if (score >= 50) return const Color(0xFFFFCC33); // Yellow - Mixed Reviews
    if (score >= 20) return const Color(0xFFFF9933); // Orange - Unfavorable
    return const Color(0xFFFF6666); // Red - Overwhelming Dislike
  }
}
