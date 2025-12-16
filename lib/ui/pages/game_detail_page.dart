import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import '../../core/api_config.dart';
import '../../managers/game_manager.dart';
import '../../models/game_model.dart';
import '../../models/creator_model.dart';
import '../../services/rawg_service.dart';
import 'game_team_page.dart';
import 'creator_detail_page.dart';

class GameDetailPage extends StatefulWidget {
  final Game game;
  const GameDetailPage({super.key, required this.game});
  @override
  State<GameDetailPage> createState() => _GameDetailPageState();
}

class _GameDetailPageState extends State<GameDetailPage> {
  final RawgService _rawgService = RawgService();

  Game? _fullGameDetails;
  bool _isLoadingDetails = true;

  // Development Team
  List<Creator> _creators = [];
  bool _isLoadingCreators = true;

  // Games in Series
  List<Game> _gameSeries = [];
  bool _isLoadingSeries = true;

  // DLCs and Editions
  List<Game> _dlcs = [];
  bool _isLoadingDlcs = true;

  // Store Links (with actual URLs)
  List<Map<String, dynamic>> _storeLinks = [];

  // Screenshots (fetched from dedicated endpoint)
  List<String> _screenshots = [];

  @override
  void initState() {
    super.initState();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    // Fetch all data in parallel for best performance
    await Future.wait([
      _fetchFullGameDetails(),
      _fetchDevelopmentTeam(),
      _fetchGameSeries(),
      _fetchDLCs(),
      _fetchStoreLinks(),
      _fetchScreenshots(),
    ]);
  }

  Future<void> _fetchFullGameDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://api.rawg.io/api/games/${widget.game.id}?key=${ApiConfig.rawgApiKey}',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (mounted) {
          setState(() {
            _fullGameDetails = Game.fromJson(data);
            _isLoadingDetails = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching game details: $e');
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  Future<void> _fetchDevelopmentTeam() async {
    try {
      final teamData = await _rawgService.getDevelopmentTeam(widget.game.id);
      if (mounted) {
        setState(() {
          _creators = teamData.map((json) => Creator.fromJson(json)).toList();
          _isLoadingCreators = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingCreators = false);
    }
  }

  Future<void> _fetchGameSeries() async {
    try {
      final series = await _rawgService.getGameSeries(widget.game.id);
      if (mounted) {
        setState(() {
          _gameSeries = series;
          _isLoadingSeries = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingSeries = false);
    }
  }

  Future<void> _fetchDLCs() async {
    try {
      final dlcs = await _rawgService.getDLCsAndAdditions(widget.game.id);
      if (mounted) {
        setState(() {
          _dlcs = dlcs;
          _isLoadingDlcs = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingDlcs = false);
    }
  }

  Future<void> _fetchStoreLinks() async {
    try {
      final stores = await _rawgService.getGameStores(widget.game.id);
      if (mounted) {
        setState(() => _storeLinks = stores);
      }
    } catch (e) {
      debugPrint('Error fetching stores: $e');
    }
  }

  Future<void> _fetchScreenshots() async {
    try {
      final screenshots = await _rawgService.getGameScreenshots(widget.game.id);
      if (mounted) {
        setState(() => _screenshots = screenshots);
      }
    } catch (e) {
      debugPrint('Error fetching screenshots: $e');
    }
  }

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameManager>(
      builder: (context, gameManager, child) {
        final libraryGame = gameManager.getGameById(widget.game.id);
        // Use full details if available, otherwise fallback to library game or passed game
        // If full details are loaded, merged them with library status/rating if applicable
        final baseGame = libraryGame ?? widget.game;
        final currentGame = _fullGameDetails != null
            ? _fullGameDetails!.copyWith(
                status: baseGame.status,
                isFavorite: baseGame.isFavorite,
                platformRating: baseGame.platformRating,
                // Keep minimal fields if API fails
              )
            : baseGame;

        final isInLibrary = libraryGame != null;
        final isPlanToPlay = currentGame.status == 'Plan to Play';

        return Scaffold(
          appBar: AppBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            title: Text(
              'MGL',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontSize: 28, letterSpacing: 2),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                onPressed: () {
                  if (isInLibrary) {
                    gameManager.toggleFavorite(currentGame.id);
                  } else {
                    gameManager.addGame(currentGame.copyWith(isFavorite: true));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Added to library and favorites!'),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }
                },
                icon: Icon(
                  currentGame.isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: currentGame.isFavorite
                      ? Colors.red
                      : Theme.of(context).textTheme.bodyLarge?.color,
                ),
                iconSize: 28,
              ),
              IconButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Share feature coming soon!'),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
                icon: Icon(
                  Icons.share_rounded,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
                iconSize: 28,
              ),
            ],
          ),
          body: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  // Loading Indicator
                  if (_isLoadingDetails)
                    SliverToBoxAdapter(
                      child: LinearProgressIndicator(
                        backgroundColor: Theme.of(
                          context,
                        ).scaffoldBackgroundColor,
                        color: Theme.of(context).colorScheme.primary,
                        minHeight: 2,
                      ),
                    ),

                  // Hero Image
                  SliverToBoxAdapter(
                    child: Stack(
                      children: [
                        Image.network(
                          currentGame.imageUrl,
                          fit: BoxFit.cover,
                          height: 300,
                          width: double.infinity,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                height: 300,
                                color: Colors.grey[900],
                                child: const Center(
                                  child: Icon(Icons.broken_image, size: 60),
                                ),
                              ),
                        ),
                        Container(
                          height: 300,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0, 0.7, 1.0],
                              colors: [
                                Colors.transparent,
                                Theme.of(
                                  context,
                                ).scaffoldBackgroundColor.withAlpha(204),
                                Theme.of(context).scaffoldBackgroundColor,
                              ],
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
                          // Title + Genre
                          Text(
                            currentGame.title,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            currentGame.genre,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 16,
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.color,
                                ),
                          ),
                          const SizedBox(height: 20),

                          // Rating + Status Row
                          if (isInLibrary || !isPlanToPlay)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).cardColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      if (currentGame.hasRating) ...[
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _getMetacriticColor(
                                              currentGame.displayRatingValue!,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              6,
                                            ),
                                          ),
                                          child: Text(
                                            currentGame.displayRatingValue
                                                .toString(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ] else
                                        Text(
                                          'Not Rated',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(fontSize: 14),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      currentGame.status,
                                    ).withAlpha(51),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    currentGame.status,
                                    style: TextStyle(
                                      color: _getStatusColor(
                                        currentGame.status,
                                      ),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          const SizedBox(height: 24),

                          // Quick Info Grid (2x2)
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 1.5,
                            children: [
                              _buildInfoCard(
                                'Platform',
                                currentGame.platform,
                                Icons.devices_rounded,
                              ),
                              _buildInfoCard(
                                isPlanToPlay ? 'Releases' : 'Released',
                                currentGame.releaseDate,
                                Icons.calendar_today_rounded,
                              ),
                              if (currentGame.playtime != null)
                                _buildInfoCard(
                                  'Playtime',
                                  '${currentGame.playtime}h avg',
                                  Icons.timer_outlined,
                                ),
                              if (currentGame.esrbRating.isNotEmpty)
                                _buildInfoCard(
                                  'ESRB',
                                  currentGame.esrbRating.toUpperCase(),
                                  Icons.shield_outlined,
                                ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // About Section
                          _buildSectionHeader('About'),
                          const SizedBox(height: 12),
                          Text(
                            currentGame.description.isNotEmpty
                                ? currentGame.description
                                : 'No description available for this game.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontSize: 15,
                                  height: 1.6,
                                  color: currentGame.description.isEmpty
                                      ? Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color
                                      : null,
                                ),
                          ),

                          // Development Team (Individual Creators)
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader('Development Team'),
                              if (_creators.isNotEmpty)
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => GameTeamPage(
                                          gameId: currentGame.id,
                                          gameTitle: currentGame.title,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Text('${_creators.length} creators'),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _isLoadingCreators
                              ? const Center(child: CircularProgressIndicator())
                              : _creators.isEmpty
                              ? _buildCard(
                                  child: Column(
                                    children: [
                                      if (currentGame.developers.isNotEmpty)
                                        _buildListItem(
                                          Icons.code_rounded,
                                          'Developer',
                                          currentGame.developers.join(', '),
                                        ),
                                      if (currentGame.developers.isNotEmpty &&
                                          currentGame.publishers.isNotEmpty)
                                        const Divider(height: 24),
                                      if (currentGame.publishers.isNotEmpty)
                                        _buildListItem(
                                          Icons.business_rounded,
                                          'Publisher',
                                          currentGame.publishers.join(', '),
                                        ),
                                      if (currentGame.developers.isEmpty &&
                                          currentGame.publishers.isEmpty)
                                        Text(
                                          'No team information available',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                    ],
                                  ),
                                )
                              : SizedBox(
                                  height: 140,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _creators.take(6).length,
                                    itemBuilder: (context, index) {
                                      final creator = _creators[index];
                                      return Padding(
                                        padding: EdgeInsets.only(
                                          right: index < 5 ? 12 : 0,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    CreatorDetailPage(
                                                      creatorId: creator.id,
                                                      creatorName: creator.name,
                                                    ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 100,
                                            decoration: BoxDecoration(
                                              color: Theme.of(
                                                context,
                                              ).cardColor,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 32,
                                                  backgroundColor:
                                                      Theme.of(context)
                                                          .colorScheme
                                                          .primaryContainer,
                                                  backgroundImage:
                                                      creator.image != null
                                                      ? NetworkImage(
                                                          creator.image!,
                                                        )
                                                      : null,
                                                  child: creator.image == null
                                                      ? Text(
                                                          creator
                                                                  .name
                                                                  .isNotEmpty
                                                              ? creator.name[0]
                                                                    .toUpperCase()
                                                              : '?',
                                                          style:
                                                              const TextStyle(
                                                                fontSize: 24,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              ),
                                                        )
                                                      : null,
                                                ),
                                                const SizedBox(height: 8),
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                      ),
                                                  child: Text(
                                                    creator.name,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    textAlign: TextAlign.center,
                                                  ),
                                                ),
                                                if (creator
                                                    .positions
                                                    .isNotEmpty)
                                                  Text(
                                                    creator.positions.first,
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      color: Theme.of(
                                                        context,
                                                      ).colorScheme.primary,
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                          // Tags (Filtered and Prioritized)
                          if (currentGame.tags.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildSectionHeader('Tags'),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _getRelevantTags(currentGame.tags)
                                  .map(
                                    (tag) => Chip(
                                      label: Text(
                                        tag
                                            .replaceAll('-', ' ')
                                            .split(' ')
                                            .map(
                                              (word) => word.isEmpty
                                                  ? ''
                                                  : word[0].toUpperCase() +
                                                        word.substring(1),
                                            )
                                            .join(' '),
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: Theme.of(
                                        context,
                                      ).cardColor,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 4,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],

                          // Where to Buy (with real store links)
                          const SizedBox(height: 32),
                          _buildSectionHeader('Where to Buy'),
                          const SizedBox(height: 12),
                          _storeLinks.isEmpty && currentGame.stores.isEmpty
                              ? Text(
                                  'No store information available',
                                  style: Theme.of(context).textTheme.bodySmall,
                                )
                              : Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: (_storeLinks.isNotEmpty
                                      ? _storeLinks.map((store) {
                                          final storeName =
                                              store['store']?['name'] ??
                                              'Store';
                                          final storeUrl = store['url'] ?? '';
                                          return OutlinedButton.icon(
                                            icon: Icon(
                                              _getStoreIcon(storeName),
                                              size: 18,
                                            ),
                                            label: Text(storeName),
                                            onPressed: storeUrl.isNotEmpty
                                                ? () => _launchURL(storeUrl)
                                                : null,
                                            style: OutlinedButton.styleFrom(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                    vertical: 12,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }).toList()
                                      : currentGame.stores
                                            .map(
                                              (store) => OutlinedButton.icon(
                                                icon: Icon(
                                                  _getStoreIcon(
                                                    store['name'] ?? '',
                                                  ),
                                                  size: 18,
                                                ),
                                                label: Text(
                                                  store['name'] ?? '',
                                                ),
                                                onPressed: () => _launchURL(
                                                  store['url'] ?? '',
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 16,
                                                        vertical: 12,
                                                      ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          12,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList()),
                                ),

                          // Screenshots (from dedicated endpoint)
                          if (_screenshots.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildSectionHeader('Screenshots'),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 180,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _screenshots.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: EdgeInsets.only(
                                    right: index < _screenshots.length - 1
                                        ? 12
                                        : 0,
                                  ),
                                  child: GestureDetector(
                                    onTap: () => _showFullscreenImage(
                                      context,
                                      _screenshots[index],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        _screenshots[index],
                                        width: 280,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                Container(
                                                  width: 280,
                                                  color: Colors.grey[800],
                                                  child: const Icon(
                                                    Icons.broken_image,
                                                    size: 40,
                                                  ),
                                                ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],

                          // DLCs & Editions
                          if (!_isLoadingDlcs && _dlcs.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildSectionHeader('DLCs & Editions'),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 160,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _dlcs.length,
                                itemBuilder: (context, index) {
                                  final dlc = _dlcs[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index < _dlcs.length - 1 ? 12 : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GameDetailPage(game: dlc),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 120,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                  dlc.imageUrl,
                                                  width: 120,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: Colors.grey[800],
                                                        child: const Icon(
                                                          Icons.extension,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(
                                                dlc.title,
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
                          ],

                          // External Links
                          if (currentGame.website != null ||
                              currentGame.redditUrl != null) ...[
                            const SizedBox(height: 32),
                            _buildSectionHeader('Community & Links'),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                if (currentGame.website != null)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.language_rounded),
                                      label: const Text('Website'),
                                      onPressed: () =>
                                          _launchURL(currentGame.website!),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (currentGame.website != null &&
                                    currentGame.redditUrl != null)
                                  const SizedBox(width: 12),
                                if (currentGame.redditUrl != null)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      icon: const Icon(Icons.forum_rounded),
                                      label: const Text('Reddit'),
                                      onPressed: () =>
                                          _launchURL(currentGame.redditUrl!),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ],

                          // Games in the Series
                          if (!_isLoadingSeries && _gameSeries.isNotEmpty) ...[
                            const SizedBox(height: 32),
                            _buildSectionHeader('Games in the Series'),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 200,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: _gameSeries.length,
                                itemBuilder: (context, index) {
                                  final game = _gameSeries[index];
                                  return Padding(
                                    padding: EdgeInsets.only(
                                      right: index < _gameSeries.length - 1
                                          ? 12
                                          : 0,
                                    ),
                                    child: GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                GameDetailPage(game: game),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 140,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
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
                                                  game.imageUrl,
                                                  width: 140,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => Container(
                                                        color: Colors.grey[800],
                                                        child: const Icon(
                                                          Icons.broken_image,
                                                        ),
                                                      ),
                                                ),
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.all(8),
                                              child: Text(
                                                game.title,
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
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
                          ],

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: FloatingActionButton.extended(
                  onPressed: () => _showAddGameDialog(
                    context,
                    gameManager,
                    currentGame,
                    isInLibrary,
                  ),
                  icon: Icon(
                    isInLibrary ? Icons.edit_rounded : Icons.add_rounded,
                  ),
                  label: Text(isInLibrary ? 'Update Game' : 'Add to Library'),
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

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(25)),
      ),
      child: child,
    );
  }

  Widget _buildListItem(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getStoreIcon(String storeName) {
    final name = storeName.toLowerCase();
    if (name.contains('steam')) {
      return Icons.computer;
    }
    if (name.contains('playstation') || name.contains('ps')) {
      return Icons.videogame_asset;
    }
    if (name.contains('xbox')) {
      return Icons.sports_esports;
    }
    if (name.contains('nintendo') || name.contains('switch')) {
      return Icons.sports_esports_outlined;
    }
    if (name.contains('epic')) {
      return Icons.games;
    }
    if (name.contains('gog')) {
      return Icons.storefront;
    }
    return Icons.shopping_bag;
  }

  Widget _buildInfoCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor.withAlpha(25)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Theme.of(context).textTheme.bodyMedium?.color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAddGameDialog(
    BuildContext context,
    GameManager gameManager,
    Game game,
    bool isInLibrary,
  ) {
    double tempRating = game.platformRating ?? 0;
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isInLibrary ? 'Update ${game.title}' : 'Add to Library',
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Rating: ${tempRating.toStringAsFixed(1)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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
                  Text(
                    'Status:',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Wrap(
                    spacing: 10,
                    children:
                        [
                          'Playing',
                          'Completed',
                          'Plan to Play',
                          'Dropped',
                          'On Hold',
                        ].map((status) {
                          return ChoiceChip(
                            label: Text(status),
                            selected: tempStatus == status,
                            selectedColor: _getStatusColor(
                              status,
                            ).withAlpha(204),
                            labelStyle: TextStyle(
                              color: (tempStatus == status
                                  ? Colors.white
                                  : Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.color),
                            ),
                            onSelected: (selected) {
                              setState(() {
                                if (selected) {
                                  tempStatus = status;
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isInLibrary) {
                          gameManager.updateGameDetails(
                            id: game.id,
                            status: tempStatus,
                            platformRating: tempRating,
                          );
                        } else {
                          gameManager.addGame(
                            game.copyWith(platformRating: tempRating),
                            status: tempStatus,
                          );
                        }
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '${game.title} ${isInLibrary ? 'updated' : 'added'}!',
                            ),
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(
                          context,
                        ).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        isInLibrary ? 'Save Changes' : 'Add to Library',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

  Color _getMetacriticColor(int score) {
    if (score >= 90) return const Color(0xFF00AA00);
    if (score >= 75) return const Color(0xFF66CC33);
    if (score >= 50) return const Color(0xFFFFCC33);
    if (score >= 20) return const Color(0xFFFF9933);
    return const Color(0xFFFF6666);
  }

  // Filter tags to show more relevant ones, excluding generic tags
  List<String> _getRelevantTags(List<String> tags) {
    const genericTags = [
      'singleplayer',
      'multiplayer',
      'co-op',
      '2d',
      '3d',
      'controller',
      'full-controller-support',
    ];
    final filtered = tags
        .where((tag) => !genericTags.contains(tag.toLowerCase()))
        .toList();
    return filtered.take(20).toList(); // Show up to 20 relevant tags
  }

  // Show fullscreen image dialog
  void _showFullscreenImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: Icon(Icons.broken_image, size: 80),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
