import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/game_manager.dart';
import '../../models/game_model.dart';
import '../pages/game_detail_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MyListTab extends StatefulWidget {
  final String initialFilter;
  const MyListTab({super.key, this.initialFilter = 'All'});

  @override
  MyListTabState createState() => MyListTabState();
}

class MyListTabState extends State<MyListTab> {
  late String _selectedFilter;
  String _sortOption = 'name_asc';

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildSortOption('Name (A-Z)', 'name_asc'),
            _buildSortOption('Name (Z-A)', 'name_desc'),
            _buildSortOption('Your Rating', 'rating_desc'),
            _buildSortOption('Release Date', 'release_desc'),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSortOption(String label, String value) {
    final isSelected = _sortOption == value;
    return ListTile(
      title: Text(
        label,
        style: TextStyle(
          color: isSelected ? Theme.of(context).colorScheme.primary : null,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: isSelected
          ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: () {
        setState(() => _sortOption = value);
        Navigator.pop(context);
      },
    );
  }

  List<Game> _sortGames(List<Game> games) {
    var list = List<Game>.from(games);
    switch (_sortOption) {
      case 'name_asc':
        list.sort((a, b) => a.title.compareTo(b.title));
        break;
      case 'name_desc':
        list.sort((a, b) => b.title.compareTo(a.title));
        break;
      case 'rating_desc':
        list.sort((a, b) => (b.personalRating ?? 0).compareTo(a.personalRating ?? 0));
        break;
      case 'release_desc':
        list.sort((a, b) => (b.releaseDate).compareTo(a.releaseDate));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        List<Game> filteredGames;
        switch (_selectedFilter) {
          case 'Playing':
            filteredGames = gameManager.playingGames;
            break;
          case 'Completed':
            filteredGames = gameManager.completedGames;
            break;
          case 'Plan to Play':
            filteredGames = gameManager.plannedGames;
            break;
          case 'Favorites':
            filteredGames = gameManager.favoriteGames;
            break;
          case 'On Hold':
            filteredGames = gameManager.onHoldGames;
            break;
          case 'Dropped':
            filteredGames = gameManager.droppedGames;
            break;
          default:
            filteredGames = gameManager.games;
        }
        
        // Apply Sort
        filteredGames = _sortGames(filteredGames);

        return Column(
          children: [
            SizedBox(
              height: 60,
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 8),
                    child: IconButton(
                      icon: const Icon(Icons.sort_rounded),
                      onPressed: _showSortOptions,
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).cardColor,
                        padding: const EdgeInsets.all(12),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.only(right: 20, top: 10, bottom: 10),
                      children: [
                        _buildFilterChip('All', gameManager.totalGames),
                        _buildFilterChip('Playing', gameManager.playingCount),
                        _buildFilterChip('Completed', gameManager.completedCount),
                        _buildFilterChip('Plan to Play', gameManager.plannedCount),
                        _buildFilterChip('On Hold', gameManager.onHoldGames.length),
                        _buildFilterChip('Dropped', gameManager.droppedGames.length),
                        _buildFilterChip('Favorites', gameManager.favoriteCount),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filteredGames.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.videogame_asset_off_rounded,
                            size: 64,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No games in this category',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: filteredGames.length,
                      itemBuilder: (context, index) =>
                          _buildAdvancedGameCard(context, filteredGames[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFilterChip(String label, int count) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => _selectedFilter = label);
          }
        },
        labelStyle: TextStyle(
          color: isSelected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected
                ? Colors.transparent
                : Theme.of(context).dividerColor,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedGameCard(BuildContext context, Game game) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GameDetailPage(game: game)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Section
            SizedBox(
              height: 140, // Generous banner height
              child: CachedNetworkImage(
                imageUrl: game.imageUrl,
                fit: BoxFit.cover,
                memCacheHeight: 400, // Optimize memory (decode smaller)
                fadeInDuration: Duration.zero, // Prevent fade animation on rebuilds
                placeholder: (context, url) => Container(color: Colors.grey[800]),
                errorWidget: (context, url, error) => const Icon(Icons.videogame_asset, color: Colors.grey),
              ),
            ),
            
            // Details Section (Below image)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      game.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (game.personalRating != null && game.personalRating! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 16, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            game.personalRating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                     Text(
                        'Unrated',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Playing':
        return const Color(0xFF10B981);
      case 'Completed':
        return Colors.blue;
      case 'Plan to Play':
        return const Color(0xFFF59E0B);
      case 'Favorites':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getMetacriticColor(int score) {
    if (score >= 90) {
      return const Color(0xFF00AA00); // Dark green - Universal Acclaim
    }
    if (score >= 75) {
      return const Color(0xFF66CC33); // Green - Generally Favorable
    }
    if (score >= 50) {
      return const Color(0xFFFFCC33); // Yellow - Mixed Reviews
    }
    if (score >= 20) {
      return const Color(0xFFFF9933); // Orange - Unfavorable
    }
    return const Color(0xFFFF6666); // Red - Overwhelming Dislike
  }
}
