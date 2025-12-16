import 'package:flutter/material.dart';
import '../../models/creator_model.dart';
import '../../models/game_model.dart';
import '../../services/rawg_service.dart';
import 'game_detail_page.dart';

/// Detailed page for an individual creator/staff member
class CreatorDetailPage extends StatefulWidget {
  final int creatorId;
  final String creatorName;

  const CreatorDetailPage({
    super.key,
    required this.creatorId,
    required this.creatorName,
  });

  @override
  State<CreatorDetailPage> createState() => _CreatorDetailPageState();
}

class _CreatorDetailPageState extends State<CreatorDetailPage> {
  final RawgService _rawgService = RawgService();
  Creator? _creator;
  List<Map<String, dynamic>> _creatorGames = [];
  bool _isLoading = true;
  bool _isLoadingGames = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCreatorDetails();
    _loadCreatorGames();
  }

  Future<void> _loadCreatorDetails() async {
    try {
      final data = await _rawgService.getCreatorDetails(widget.creatorId);
      if (data != null && mounted) {
        setState(() {
          _creator = Creator.fromJson(data);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Creator not found';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load creator details';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadCreatorGames() async {
    try {
      final games = await _rawgService.getGamesByCreator(widget.creatorId);
      if (mounted) {
        setState(() {
          _creatorGames = games;
          _isLoadingGames = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingGames = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorState()
          : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final creator = _creator!;

    return CustomScrollView(
      slivers: [
        // App Bar with Hero Image
        SliverAppBar(
          expandedHeight: 280,
          pinned: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                if (creator.imageBackground != null)
                  Image.network(
                    creator.imageBackground!,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                    ),
                  )
                else
                  Container(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                  ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Theme.of(
                          context,
                        ).scaffoldBackgroundColor.withAlpha(200),
                        Theme.of(context).scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                ),
                // Creator Photo and Name
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primaryContainer,
                        backgroundImage: creator.image != null
                            ? NetworkImage(creator.image!)
                            : null,
                        child: creator.image == null
                            ? Text(
                                creator.name.isNotEmpty
                                    ? creator.name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              creator.name,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (creator.positions.isNotEmpty)
                              Text(
                                creator.positionsString,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                    ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // About Section
                if (creator.description != null &&
                    creator.description!.isNotEmpty) ...[
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _stripHtmlTags(creator.description!),
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(height: 1.6),
                  ),
                  const SizedBox(height: 24),
                ],

                // Known For Games Section (using fetched games)
                const SizedBox(height: 24),
                Text(
                  'Known For',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _isLoadingGames
                    ? const Center(child: CircularProgressIndicator())
                    : _creatorGames.isEmpty
                    ? Text(
                        'No games found',
                        style: Theme.of(context).textTheme.bodySmall,
                      )
                    : SizedBox(
                        height: 180,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _creatorGames.length,
                          itemBuilder: (context, index) {
                            final gameData = _creatorGames[index];
                            return Padding(
                              padding: EdgeInsets.only(
                                right: index < _creatorGames.length - 1
                                    ? 12
                                    : 0,
                              ),
                              child: GestureDetector(
                                onTap: () {
                                  final game = Game.fromJson(gameData);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          GameDetailPage(game: game),
                                    ),
                                  );
                                },
                                child: Container(
                                  width: 130,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    color: Theme.of(context).cardColor,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: ClipRRect(
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(12),
                                              ),
                                          child: Image.network(
                                            gameData['background_image'] ?? '',
                                            width: 130,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Container(
                                                      color: Colors.grey[800],
                                                      child: const Icon(
                                                        Icons.videogame_asset,
                                                      ),
                                                    ),
                                          ),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Text(
                                          gameData['name'] ?? 'Unknown',
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _stripHtmlTags(String htmlText) {
    return htmlText
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&nbsp;', ' ');
  }
}
