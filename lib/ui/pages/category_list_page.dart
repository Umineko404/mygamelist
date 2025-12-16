import 'package:flutter/material.dart';
import '../../services/rawg_service.dart';
import 'universal_game_list_page.dart';

enum CategoryType { genres, platforms, stores, tags, developers, publishers }

class CategoryListPage extends StatefulWidget {
  final CategoryType type;

  const CategoryListPage({super.key, required this.type});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final RawgService _rawgService = RawgService();
  List<Map<String, dynamic>> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  String get _title {
    switch (widget.type) {
      case CategoryType.genres:
        return 'Browse Genres';
      case CategoryType.platforms:
        return 'Browse Platforms';
      case CategoryType.stores:
        return 'Browse Stores';
      case CategoryType.tags:
        return 'Browse Tags';
      case CategoryType.developers:
        return 'Browse Developers';
      case CategoryType.publishers:
        return 'Browse Publishers';
    }
  }

  Future<void> _loadCategories() async {
    try {
      List<Map<String, dynamic>> categories;
      switch (widget.type) {
        case CategoryType.genres:
          categories = await _rawgService.getGenres();
          break;
        case CategoryType.platforms:
          categories = await _rawgService.getPlatforms();
          break;
        case CategoryType.stores:
          categories = await _rawgService.getStores();
          break;
        case CategoryType.tags:
          categories = await _rawgService.getTags();
          break;
        case CategoryType.developers:
          categories = await _rawgService.getDevelopers();
          break;
        case CategoryType.publishers:
          categories = await _rawgService.getPublishers();
          break;
      }

      if (mounted) {
        setState(() {
          _categories = categories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load categories.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_title),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
      ),
      body: _buildBody(),
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
            TextButton(
              onPressed: () {
                setState(() {
                  _isLoading = true;
                  _errorMessage = null;
                });
                _loadCategories();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _categories.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final category = _categories[index];
        return _buildCategoryCard(category);
      },
    );
  }

  Widget _buildCategoryCard(Map<String, dynamic> category) {
    return GestureDetector(
      onTap: () => _navigateToGameList(category),
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          image: category['image_background'] != null
              ? DecorationImage(
                  image: NetworkImage(category['image_background']),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withAlpha(150),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  category['name'] ?? 'Unknown',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
              if (category['games_count'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${category['games_count']} games',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToGameList(Map<String, dynamic> category) {
    final id = category['id'].toString();
    final name = category['name'] ?? 'Games';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) {
          switch (widget.type) {
            case CategoryType.genres:
              return UniversalGameListPage(title: name, genres: id);
            case CategoryType.platforms:
              return UniversalGameListPage(title: name, platforms: id);
            case CategoryType.stores:
              return UniversalGameListPage(title: name, stores: id);
            case CategoryType.tags:
              return UniversalGameListPage(title: name, tags: id);
            case CategoryType.developers:
              return UniversalGameListPage(title: name, developers: id);
            case CategoryType.publishers:
              return UniversalGameListPage(title: name, publishers: id);
          }
        },
      ),
    );
  }
}
