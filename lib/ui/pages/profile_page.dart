  import 'dart:io';
  import 'package:flutter/material.dart';
  import 'package:provider/provider.dart';
  import 'package:image_picker/image_picker.dart';
  import 'package:cached_network_image/cached_network_image.dart';

  import '../../managers/game_manager.dart';
  import '../../services/auth_service.dart';
  import '../widgets/my_list_tab.dart';
  import 'platform_selection_page.dart';
  import 'auth_page.dart';

  class ProfilePage extends StatefulWidget {
    const ProfilePage({super.key});

    @override
    ProfilePageState createState() => ProfilePageState();
  }

  class ProfilePageState extends State<ProfilePage>
      with SingleTickerProviderStateMixin {
    late TabController _tabController;
    String _selectedListFilter = 'All';
    final _imagePicker = ImagePicker();

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
      if (filter == 'Favorites') {
        // Switch to the 'My List' tab and set filter? 
        // MyListTab doesn't strictly have a 'Favorites' filter property exposed this way
        // but we can pass it via key/initialFilter as done before.
      }
      setState(() {
        _selectedListFilter = filter;
      });
      _tabController.animateTo(1);
    }

    void _showAvatarOptions() {
      showModalBottomSheet(
        context: context,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Enter Image Link'),
                onTap: () {
                  Navigator.pop(context);
                  _showUrlAvatarDialog();
                },
              ),
            ],
          ),
        ),
      );
    }

    Future<void> _pickImageFromGallery() async {
      try {
        final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
        if (image != null && mounted) {
          await context.read<GameManager>().updateProfile(avatarUrl: image.path);
        }
      } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error updating avatar: $e')),
          );
        }
      }
    }

    void _showUrlAvatarDialog() {
      final urlController = TextEditingController();
      String? previewUrl;

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Enter Image Link'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: urlController,
                    decoration: const InputDecoration(
                      labelText: 'Image URL',
                      hintText: 'https://example.com/image.png',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => previewUrl = value.trim());
                    },
                  ),
                  const SizedBox(height: 16),
                  if (previewUrl != null && previewUrl!.isNotEmpty)
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Theme.of(context).dividerColor),
                      ),
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: previewUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                          errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error, color: Colors.red)),
                        ),
                      ),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (previewUrl != null && previewUrl!.isNotEmpty) {
                       context.read<GameManager>().updateProfile(avatarUrl: previewUrl);
                       Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        ),
      );
    }

    @override
    Widget build(BuildContext context) {
      final isGuest = context.select<GameManager, bool>((gm) => gm.isGuest);

      if (isGuest) {
        return _buildGuestView(context);
      }

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

    Widget _buildGuestView(BuildContext context) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off_rounded, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 24),
              Text(
                'Profile Not Available',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Sign in to track your games, view stats, and manage your profile.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                   Navigator.push(
                     context,
                     MaterialPageRoute(builder: (_) => const AuthPage()),
                   );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text('Log In / Sign Up'),
              ),
            ],
          ),
        ),
      );
    }

    Widget _buildProfileStatsPage(BuildContext context) {
      return Consumer<GameManager>(
        builder: (context, gameManager, _) {
          final user = gameManager.userProfile;
          final ownedPlatformsCount = user?.ownedPlatforms.length ?? 0;

          return CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Center(
                      child: GestureDetector(
                        onTap: _showAvatarOptions,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              // Check if local file or network
                              backgroundImage: user?.avatarUrl != null
                                ? (user!.avatarUrl!.startsWith('http') 
                                    ? CachedNetworkImageProvider(user.avatarUrl!)
                                    : FileImage(File(user.avatarUrl!)) as ImageProvider)
                                : null,
                              child: user?.avatarUrl == null 
                                ? const Icon(Icons.person, size: 50, color: Colors.white)
                                : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                                ),
                                child: const Icon(Icons.edit, size: 16, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Text(
                        user?.username ?? 'Gamer',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 24),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: () => _showEditBioDialog(context, gameManager),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  user?.bio ?? 'Add a bio',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: user?.bio == null 
                                        ? Theme.of(context).textTheme.bodySmall?.color 
                                        : null,
                                    fontStyle: user?.bio == null ? FontStyle.italic : null,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.edit,
                                size: 16,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ],
                          ),
                        ),
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
                    // Removed simple "Hours Played" mock, replaced with Average Rating or real stats
                    _buildProfileCard(
                      context,
                      'Avg Rating',
                      gameManager.averageRating.toStringAsFixed(1),
                      Icons.star_rounded,
                      null, // No visual breakdown page yet
                    ),
                    _buildProfileCard(
                      context,
                      'Owned Platforms',
                      ownedPlatformsCount.toString(),
                      Icons.devices_rounded,
                      () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const PlatformSelectionPage()),
                      ),
                    ),
                    _buildProfileCard(
                      context,
                      'Favorites',
                      gameManager.favoriteCount.toString(),
                      Icons.favorite_rounded,
                      () => _navigateToMyList('Favorites'),
                    ),
                    
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await context.read<AuthService>().signOut();
                        // Navigation handled by GameManager listener -> HomePage check or explicit push
                         if (context.mounted) {
                           Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthPage()),
                           );
                         }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ]),
                ),
              ),
            ],
          );
        },
      );
    }

    Widget _buildProfileCard(
      BuildContext context,
      String title,
      String value,
      IconData icon,
      VoidCallback? onTap,
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
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 20),
                    ),
                    Text(title, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
              if (onTap != null)
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

    void _showEditBioDialog(BuildContext context, GameManager gameManager) {
      final user = gameManager.userProfile;
      final bioController = TextEditingController(text: user?.bio ?? '');

      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Edit Bio', style: Theme.of(context).textTheme.titleLarge),
            content: TextField(
              controller: bioController,
              maxLines: 3,
              maxLength: 150,
              decoration: InputDecoration(
                hintText: 'Tell us about yourself...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newBio = bioController.text.trim();
                  try {
                    await gameManager.firebaseService.updateUserProfile(
                      gameManager.authService.currentUser!.uid,
                      {'bio': newBio.isEmpty ? null : newBio},
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Bio updated successfully'),
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
    }
  }
