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
          allGames.firstWhere((g) => g.title == 'Silent Hill f',
              orElse: () => sampleGames[1]),
          allGames.firstWhere((g) => g.title == 'Metaphor ReFantazio',
              orElse: () => sampleGames[5]),
          allGames.firstWhere((g) => g.title == 'Persona 3 Reload',
              orElse: () => sampleGames[0]),
        ];
        final upcomingGames = allGames
            .where((game) => (int.tryParse(game.releaseDate) ?? 0) > 2025)
            .toList();
        final topRatedGames = allGames.where((game) => game.rating > 0).toList()
          ..sort((a, b) => b.rating.compareTo(a.rating));
        final top6RatedGames = topRatedGames.take(6).toList();
        final List<Widget> defaultContent = [
          _buildSectionHeader('Trending Now'),
          _buildHorizontalGameList(trendingGames),
          _buildSectionHeader('Upcoming'),
          _buildHorizontalGameList(upcomingGames),
          _buildSectionHeader('Top Rated'),
          _buildHorizontalGameList(top6RatedGames),
        ];

        final List<Widget> searchContent = [
          if (searchResults.isNotEmpty) ...[
            _buildSectionHeader('🔍 Search Results (${searchResults.length})'),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16),
                delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                        _buildUnifiedCard(searchResults[index]),
                    childCount: searchResults.length),
              ),
            ),
          ] else ...[
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text('No games found for "$_searchQuery"',
                        style:
                        TextStyle(color: Colors.grey[400], fontSize: 16)),
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
                    prefixIcon: Icon(Icons.search_rounded,
                        color: Theme.of(context).textTheme.bodyMedium?.color),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                      icon: Icon(Icons.clear_rounded,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
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
        child: Text(title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
      ),
    );
  }

  Widget _buildHorizontalGameList(List<Game> games) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: 240,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: games.length,
          itemBuilder: (context, index) {
            return Container(
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              child: _buildUnifiedCard(games[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildUnifiedCard(Game game) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (context) => GameDetailPage(game: game))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
              image: NetworkImage(game.imageUrl), fit: BoxFit.cover),
        ),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withAlpha(204)
                    ]),
              ),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(game.title,
                      maxLines: 2,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          shadows: [Shadow(blurRadius: 2)])),
                  const SizedBox(height: 4),
                  Text(game.genre,
                      style: TextStyle(
                          color: Colors.grey[200],
                          fontSize: 12,
                          shadows: const [Shadow(blurRadius: 2)])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}