import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/game_manager.dart';
import '../widgets/my_list_tab.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  ProfilePageState createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedListFilter = 'All';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _navigateToMyList(String filter) {
    setState(() {
      _selectedListFilter = filter;
    });
    _tabController.animateTo(1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'Profile'),
              Tab(text: 'My List'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildProfileStatsPage(context),
              MyListTab(
                key: ValueKey(_selectedListFilter),
                initialFilter: _selectedListFilter,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStatsPage(BuildContext context) {
    final gameManager = Provider.of<GameManager>(context);
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Center(
                child: GestureDetector(
                  onTap: () => _showEditProfile(context),
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    backgroundImage: NetworkImage(
                      'https://pbs.twimg.com/profile_images/1769695630052503553/F7EmXKP2_400x400.jpg',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'LoreHunter',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 24),
                ),
              ),
              Center(
                child: Text(
                  'Uncovering the hidden gems lost in the backlog',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 20),
              _buildProfileCard(
                context,
                'Total Games',
                gameManager.totalGames.toString(),
                Icons.videogame_asset_rounded,
                () => _navigateToMyList('All'),
              ),
              _buildProfileCard(
                context,
                'Hours Played',
                '${gameManager.totalGames * 25}h',
                Icons.timer_rounded,
                () => _showPlaytimeDetails(context, gameManager.totalGames),
              ),
              _buildProfileCard(
                context,
                'Avg Rating',
                gameManager.averageRating.toStringAsFixed(1),
                Icons.star_rounded,
                () => _showRatingBreakdown(context, gameManager.averageRating),
              ),
              _buildProfileCard(
                context,
                'Platforms',
                '5',
                Icons.devices_rounded,
                () => _showPlatforms(context),
              ),
              _buildProfileCard(
                context,
                'Favorites',
                gameManager.favoriteCount.toString(),
                Icons.favorite_rounded,
                () => _navigateToMyList('Favorites'),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 20),
                  ),
                  Text(title, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Edit profile coming soon!'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPlaytimeDetails(BuildContext context, int totalGames) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${totalGames * 25} hours total playtime!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showRatingBreakdown(BuildContext context, double avgRating) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Average rating: ${avgRating.toStringAsFixed(1)}/10'),
        backgroundColor: const Color(0xFFF59E0B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showPlatforms(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('PS5, PS4, Xbox, Switch, PC'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
