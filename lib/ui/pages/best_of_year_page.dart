import 'package:flutter/material.dart';
import '../../services/rawg_service.dart';
import 'universal_game_list_page.dart';

/// Page showing years as cards - click to see best games of that year
/// Styled to match CategoryListPage exactly
class BestOfYearPage extends StatefulWidget {
  const BestOfYearPage({super.key});

  @override
  State<BestOfYearPage> createState() => _BestOfYearPageState();
}

class _BestOfYearPageState extends State<BestOfYearPage> {
  final RawgService _rawgService = RawgService();
  final Map<int, String?> _yearImages = {};

  @override
  void initState() {
    super.initState();
    _loadYearImages();
  }

  Future<void> _loadYearImages() async {
    final currentYear = DateTime.now().year;
    // Load images for recent years (last 10 years)
    final futures = <Future>[];
    for (int year = currentYear; year >= currentYear - 9; year--) {
      futures.add(_loadImageForYear(year));
    }
    await Future.wait(futures);
  }

  Future<void> _loadImageForYear(int year) async {
    final image = await _rawgService.getBestGameImageForYear(year);
    if (mounted) {
      setState(() => _yearImages[year] = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    // Show years from current year back to 2000
    final years = List.generate(currentYear - 1999, (i) => currentYear - i);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Best of Year'),
        backgroundColor: Theme.of(context).cardColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).textTheme.titleLarge?.color,
        ),
        titleTextStyle: Theme.of(context).textTheme.titleLarge,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: years.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final year = years[index];
          return _buildYearCard(year);
        },
      ),
    );
  }

  Widget _buildYearCard(int year) {
    final imageUrl = _yearImages[year];

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UniversalGameListPage(
              title: 'Best of $year',
              dates: '$year-01-01,$year-12-31',
              ordering: '-metacritic',
              minRatingsCount: 20,
            ),
          ),
        );
      },
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(12),
          image: imageUrl != null
              ? DecorationImage(
                  image: NetworkImage(imageUrl),
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
                  year.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Top Games',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
