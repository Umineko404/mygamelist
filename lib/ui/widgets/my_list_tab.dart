import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/game_manager.dart';
import '../../models/game_model.dart';
import '../pages/game_detail_page.dart';

class MyListTab extends StatefulWidget {
  final String initialFilter;
  const MyListTab({super.key, this.initialFilter = 'All'});

  @override
  MyListTabState createState() => MyListTabState();
}

class MyListTabState extends State<MyListTab> {
  late String _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
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
          default:
            filteredGames = gameManager.games;
        }
        return Column(
          children: [
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _buildFilterChip('All', gameManager.totalGames),
                  _buildFilterChip('Playing', gameManager.playingCount),
                  _buildFilterChip('Completed', gameManager.completedCount),
                  _buildFilterChip('Plan to Play', gameManager.plannedCount),
                  _buildFilterChip('Favorites', gameManager.favoriteCount),
                ],
              ),
            ),
            Expanded(
              child: filteredGames.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videogame_asset_off_rounded, size: 64, color: Colors.grey[600]),
                    const SizedBox(height: 16),
                    Text('No games in this category', style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: filteredGames.length,
                itemBuilder: (context, index) => _buildAdvancedGameCard(context, filteredGames[index]),
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
          color: isSelected ? Theme.of(context).colorScheme.onPrimary : Theme.of(context).textTheme.bodyMedium?.color,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
        selectedColor: Theme.of(context).colorScheme.primary,
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: isSelected ? Colors.transparent : Theme.of(context).dividerColor),
        ),
      ),
    );
  }

  Widget _buildAdvancedGameCard(BuildContext context, Game game) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => GameDetailPage(game: game))),
      child: Container(
        height: 120,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(
            image: NetworkImage(game.imageUrl),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(
              Colors.black.withAlpha(128),
              BlendMode.darken,
            ),
          ),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    game.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(blurRadius: 4)],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${game.genre} • ${game.platform}',
                    style: TextStyle(
                      color: Colors.white.withAlpha(204),
                      fontSize: 13,
                      shadows: const [Shadow(blurRadius: 2)],
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(game.status),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  game.status,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            if (game.rating > 0)
              Positioned(
                bottom: 12,
                right: 12,
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      game.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
}