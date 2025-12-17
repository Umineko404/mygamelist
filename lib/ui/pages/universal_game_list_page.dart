import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/game_model.dart';
import '../../services/rawg_service.dart';
import '../../managers/game_manager.dart';
import 'game_detail_page.dart';

class UniversalGameListPage extends StatefulWidget {
  final String title;
  final String? ordering;
  final String? dates;
  final String? genres;
  final String? platforms;
  final String? stores;
  final String? tags;
  final String? developers;
  final String? publishers;
  final int? minRatingsCount;
  final String? parentPlatforms;

  const UniversalGameListPage({
    super.key,
    required this.title,
    this.ordering,
    this.dates,
    this.genres,
    this.platforms,
    this.stores,
    this.tags,
    this.developers,
    this.publishers,
    this.minRatingsCount,
    this.parentPlatforms,
  });

  @override
  State<UniversalGameListPage> createState() => _UniversalGameListPageState();
}

class _UniversalGameListPageState extends State<UniversalGameListPage> {
  final RawgService _rawgService = RawgService();
  final ScrollController _scrollController = ScrollController();

  List<Game> _games = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _currentPage = 1;
  bool _hasMore = true;

  // Filter state
  late String _selectedOrdering;
  String? _selectedDatePreset;
  bool _filterByMyPlatforms = false;

  static const _orderingOptions = {
    '-added': 'Popularity',
    '-released': 'Release Date',
    '-metacritic': 'Metacritic',
    'name': 'Name (A-Z)',
    '-name': 'Name (Z-A)',
  };

  static const _datePresets = {
    'all': 'All Time',
    'thisYear': 'This Year',
    'lastYear': 'Last Year',
    'upcoming': 'Upcoming',
    'last30': 'Last 30 Days',
  };

  // Map slugs to RAWG Platform IDs
  String? _getFormattedPlatformIds(List<String> userPlatforms) {
    if (userPlatforms.isEmpty) return null;
    
    final Map<String, int> slugToId = {
      'pc': 4,
      'playstation5': 187,
      'playstation4': 18,
      'xbox-series-x': 186,
      'xbox-one': 1,
      'nintendo-switch': 7,
      'ios': 3,
      'android': 21,
      'macos': 5,
      'linux': 6,
    };

    final ids = userPlatforms
        .map((p) => slugToId[p])
        .where((id) => id != null)
        .join(',');
    
    return ids.isEmpty ? null : ids;
  }

  @override
  void initState() {
    super.initState();
    _selectedOrdering = widget.ordering ?? '-added';
    _scrollController.addListener(_onScroll);
    _loadGames();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore && !_isLoading) {
        _loadMoreGames();
      }
    }
  }

  String? _getDateRange(String? preset) {
    if (preset == null || preset == 'all') return widget.dates;

    final now = DateTime.now();
    String formatDate(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    switch (preset) {
      case 'thisYear':
        return '${now.year}-01-01,${now.year}-12-31';
      case 'lastYear':
        return '${now.year - 1}-01-01,${now.year - 1}-12-31';
      case 'upcoming':
        return '${formatDate(now)},${formatDate(now.add(const Duration(days: 365)))}';
      case 'last30':
        return '${formatDate(now.subtract(const Duration(days: 30)))},${formatDate(now)}';
      default:
        return widget.dates;
    }
  }

  Future<void> _loadGames() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _games = [];
    });

    try {
      String? platformsParam = widget.platforms;
      
      // Merge widget.platforms with "My Platforms" if enabled
      if (_filterByMyPlatforms) {
        final gameManager = context.read<GameManager>();
        final user = gameManager.userProfile;
        if (user != null) {
          final myIds = _getFormattedPlatformIds(user.ownedPlatforms);
          if (myIds != null) {
            platformsParam = platformsParam != null ? '$platformsParam,$myIds' : myIds;
          }
        }
      }

      final games = await _rawgService.getGames(
        page: 1,
        pageSize: 40,
        ordering: _selectedOrdering,
        dates: _getDateRange(_selectedDatePreset),
        genres: widget.genres,
        platforms: platformsParam,
        stores: widget.stores,
        tags: widget.tags,
        developers: widget.developers,
        publishers: widget.publishers,
        minRatingsCount: widget.minRatingsCount,
        parentPlatforms: widget.parentPlatforms,
      );

      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
          _hasMore = games.isNotEmpty; // Continue loading if we got any games
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load games. Please try again.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMoreGames() async {
    if (_isLoadingMore || !_hasMore) return;

    setState(() => _isLoadingMore = true);
    _currentPage++;

    try {
      String? platformsParam = widget.platforms;
      
      // Merge widget.platforms with "My Platforms" if enabled
      if (_filterByMyPlatforms) {
        final gameManager = context.read<GameManager>();
        final user = gameManager.userProfile;
        if (user != null) {
          final myIds = _getFormattedPlatformIds(user.ownedPlatforms);
          if (myIds != null) {
            platformsParam = platformsParam != null ? '$platformsParam,$myIds' : myIds;
          }
        }
      }

      final games = await _rawgService.getGames(
        page: _currentPage,
        pageSize: 40,
        ordering: _selectedOrdering,
        dates: _getDateRange(_selectedDatePreset),
        genres: widget.genres,
        platforms: platformsParam,
        stores: widget.stores,
        tags: widget.tags,
        developers: widget.developers,
        publishers: widget.publishers,
        minRatingsCount: widget.minRatingsCount,
        parentPlatforms: widget.parentPlatforms,
      );

      if (mounted) {
        setState(() {
          _games.addAll(games);
          _isLoadingMore = false;
          _hasMore = games.isNotEmpty;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
          _currentPage--;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => DraggableScrollableSheet(
          initialChildSize: 0.35,
          maxChildSize: 0.7,
          minChildSize: 0.25,
          expand: false,
          builder: (context, scrollController) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: ListView(
              controller: scrollController,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text('Filters', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                Text(
                  'Order By',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _orderingOptions.entries
                      .map(
                        (e) => ChoiceChip(
                          label: Text(e.value),
                          selected: _selectedOrdering == e.key,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedOrdering = e.key);
                              setSheetState(() {});
                              Navigator.pop(context);
                              _loadGames();
                            }
                          },
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                // Platform Filter (User Specific)
                 Consumer<GameManager>(
                  builder: (context, gameManager, _) {
                    final isGuest = gameManager.isGuest;
                    final user = gameManager.userProfile;
                    final hasPlatforms = user?.ownedPlatforms.isNotEmpty ?? false;

                    if (isGuest || !hasPlatforms) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             Text(
                              'My Platforms Only',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            Switch(
                              value: _filterByMyPlatforms,
                              onChanged: (val) {
                                setState(() => _filterByMyPlatforms = val);
                                setSheetState(() {}); // Update sheet UI
                                Navigator.pop(context);
                                _loadGames();
                              },
                            ),
                          ],
                        ),
                        if (_filterByMyPlatforms)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            child: Text(
                              'Filtering by: ${user!.ownedPlatforms.join(", ")}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                         const Divider(), 
                         const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(color: Colors.grey)),
            TextButton(onPressed: _loadGames, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_games.isEmpty) {
      return const Center(child: Text('No games found for this category.'));
    }

    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount:
          _games.length +
          (_isLoadingMore
              ? 2
              : 0), // Add 2 for loading indicator spanning 2 columns
      itemBuilder: (context, index) {
        if (index >= _games.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return _buildGameCard(_games[index]);
      },
    );
  }

  Widget _buildGameCard(Game game) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => GameDetailPage(game: game)),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    game.imageUrl.isNotEmpty
                        ? Image.network(
                            game.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.broken_image,
                                    color: Colors.grey,
                                  ),
                                ),
                          )
                        : Container(
                            color: Colors.grey[800],
                            child: const Icon(
                              Icons.gamepad,
                              color: Colors.grey,
                              size: 40,
                            ),
                          ),
                    // Rating badge (Metacritic or RAWG fallback)
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
                            color: _getMetacriticColor(
                              game.displayRatingValue!,
                            ),
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
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                game.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
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
