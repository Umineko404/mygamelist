import 'package:flutter/material.dart';
import '../../models/creator_model.dart';
import '../../services/rawg_service.dart';
import 'creator_detail_page.dart';

/// Page showing all development team members for a game
class GameTeamPage extends StatefulWidget {
  final int gameId;
  final String gameTitle;

  const GameTeamPage({
    super.key,
    required this.gameId,
    required this.gameTitle,
  });

  @override
  State<GameTeamPage> createState() => _GameTeamPageState();
}

class _GameTeamPageState extends State<GameTeamPage> {
  final RawgService _rawgService = RawgService();
  List<Creator> _creators = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeam();
  }

  Future<void> _loadTeam() async {
    try {
      final teamData = await _rawgService.getDevelopmentTeam(widget.gameId);
      if (mounted) {
        setState(() {
          _creators = teamData.map((json) => Creator.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.gameTitle} Team'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _creators.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No team information available',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _creators.length,
              itemBuilder: (context, index) {
                final creator = _creators[index];
                return _buildCreatorCard(creator);
              },
            ),
    );
  }

  Widget _buildCreatorCard(Creator creator) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreatorDetailPage(
                creatorId: creator.id,
                creatorName: creator.name,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Creator Photo
              CircleAvatar(
                radius: 36,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: creator.image != null
                    ? NetworkImage(creator.image!)
                    : null,
                child: creator.image == null
                    ? Text(
                        creator.name.isNotEmpty
                            ? creator.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Creator Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      creator.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (creator.positions.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        creator.positionsString,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      '${creator.gamesCount} games',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    // Show a few popular games
                    if (creator.games.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Known for: ${creator.games.take(3).map((g) => g.name).join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              // Arrow Icon
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).disabledColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
