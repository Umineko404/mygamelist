import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../managers/game_manager.dart';
import '../../services/auth_service.dart';
import '../../services/profile_image_service.dart';
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
    final authService = Provider.of<AuthService>(context);
    final profileImageService = Provider.of<ProfileImageService>(context);
    final displayName = authService.displayName ?? 'User';
    final email = authService.userEmail ?? '';
    final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Center(
                child: GestureDetector(
                  onTap: () =>
                      _showEditProfileImage(context, profileImageService),
                  child: StreamBuilder<String?>(
                    stream: profileImageService.profileImageStream(),
                    builder: (context, snapshot) {
                      final imageData = snapshot.data;
                      return Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            backgroundImage:
                                imageData != null && imageData.isNotEmpty
                                    ? MemoryImage(base64Decode(imageData))
                                    : null,
                            child: imageData == null || imageData.isEmpty
                                ? Text(
                                    initial,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      Theme.of(context).scaffoldBackgroundColor,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  displayName,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontSize: 24),
                ),
              ),
              Center(
                child: Text(
                  email,
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

  void _showEditProfileImage(
      BuildContext context, ProfileImageService profileImageService) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Profile Picture',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.photo_library_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text('Choose from Gallery'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(
                        context, profileImageService, ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.primary.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: const Text('Take a Photo'),
                  onTap: () async {
                    Navigator.pop(context);
                    await _pickImage(
                        context, profileImageService, ImageSource.camera);
                  },
                ),
                FutureBuilder<String?>(
                  future: profileImageService.getProfileImageUrl(),
                  builder: (context, snapshot) {
                    if (snapshot.data != null && snapshot.data!.isNotEmpty) {
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.red.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            color: Colors.red,
                          ),
                        ),
                        title: const Text(
                          'Remove Photo',
                          style: TextStyle(color: Colors.red),
                        ),
                        onTap: () async {
                          Navigator.pop(context);
                          await profileImageService.removeProfileImage();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile picture removed'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    ProfileImageService profileImageService,
    ImageSource source,
  ) async {
    try {
      final success = await profileImageService.pickAndUploadImage(source);
      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Profile picture updated!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No image selected'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile picture: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
