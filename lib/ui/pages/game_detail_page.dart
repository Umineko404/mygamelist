import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/game_manager.dart';
import '../../models/game_model.dart';

class GameDetailPage extends StatefulWidget {
  final Game game;
  const GameDetailPage({super.key, required this.game});
  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final currentGame = gameManager.getGameByTitle(widget.game.title)!;
        final isPlanToPlay = currentGame.status == 'Plan to Play';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor, shape: BoxShape.circle),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Text('MGL', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28, letterSpacing: 2)),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () => gameManager.toggleFavorite(currentGame.title),
                icon: Icon(
                  currentGame.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                  color: currentGame.isFavorite ? Colors.red : Theme.of(context).textTheme.bodyLarge?.color,
                ),
                iconSize: 28,
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Share feature coming soon!'), backgroundColor: Theme.of(context).colorScheme.primary),
                  );
                },
                icon: Icon(Icons.share_rounded, color: Theme.of(context).textTheme.bodyLarge?.color),
                iconSize: 28,
              ),
            ],
          ),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        Image.network(currentGame.imageUrl, fit: BoxFit.cover, height: 300, width: double.infinity),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0, 0.7, 1.0],
                              colors: [Colors.transparent, Theme.of(context).scaffoldBackgroundColor.withAlpha(204), Theme.of(context).scaffoldBackgroundColor],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(currentGame.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28)),
                          const SizedBox(height: 8),
                          Text(currentGame.genre, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16)),
                          const SizedBox(height: 20),
                          if (!isPlanToPlay)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                                      const SizedBox(width: 6),
                                      Text(currentGame.rating.toStringAsFixed(1), style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 18)),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(color: _getStatusColor(currentGame.status).withAlpha(51), borderRadius: BorderRadius.circular(12)),
                                  child: Text(currentGame.status, style: TextStyle(color: _getStatusColor(currentGame.status), fontSize: 14, fontWeight: FontWeight.w600)),
                                ),
                              ],
                            ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: _buildInfoCard('Platform', currentGame.platform, Icons.devices_rounded)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildInfoCard(isPlanToPlay ? 'Releases' : 'Released', currentGame.releaseDate, Icons.calendar_today_rounded)),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text('About', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20)),
                          const SizedBox(height: 12),
                          Text(currentGame.description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.6)),
                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              if (!isPlanToPlay)
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: FloatingActionButton.extended(
                    onPressed: () => _showAddGameDialog(context, gameManager, currentGame),
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Update Game'),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600)),
          Text(label, style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  void _showAddGameDialog(BuildContext context, GameManager gameManager, Game game) {
    double tempRating = game.rating;
    String tempStatus = game.status;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update ${game.title}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24)),
                  const SizedBox(height: 20),
                  Text('Rating: ${tempRating.toStringAsFixed(1)}', style: Theme.of(context).textTheme.titleMedium),
                  Slider(
                    value: tempRating,
                    min: 0,
                    max: 10,
                    divisions: 100,
                    label: tempRating.toStringAsFixed(1),
                    activeColor: Theme.of(context).colorScheme.primary,
                    onChanged: (newValue) {
                      setState(() {
                        tempRating = newValue;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Text('Status:', style: Theme.of(context).textTheme.titleMedium),
                  Wrap(
                    spacing: 10,
                    children: ['Playing', 'Completed', 'Plan to Play'].map((status) {
                      final bool isEnabled = game.status != 'Plan to Play' || status == 'Plan to Play';
                      return ChoiceChip(
                        label: Text(status),
                        selected: tempStatus == status,
                        selectedColor: _getStatusColor(status).withAlpha(204),
                        disabledColor: Theme.of(context).cardColor.withValues(alpha: 0.5),
                        labelStyle: TextStyle(
                          color: isEnabled
                              ? (tempStatus == status ? Colors.white : Theme.of(context).textTheme.bodyMedium?.color)
                              : Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.5),
                        ),
                        onSelected: isEnabled
                            ? (selected) {
                          setState(() {
                            if (selected) {
                              tempStatus = status;
                            }
                          });
                        }
                            : null,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        gameManager.updateGameDetails(
                          title: game.title,
                          status: tempStatus,
                          rating: tempRating,
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${game.title} updated!'),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
      default:
        return Colors.grey;
    }
  }
}