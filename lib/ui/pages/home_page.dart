// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../managers/theme_manager.dart';
import '../../managers/game_manager.dart';
import 'home_page_content.dart';
import 'discover_page.dart';
import 'discussions_page.dart';
import 'profile_page.dart';
import 'auth_page.dart';
import 'settings_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  late final List<Widget> _pages;


  @override
  void initState() {
    super.initState();
    _pages = [
      const HomePageContent(),
      const DiscussionsPage(),
      const DiscoverPage(),
      const ProfilePage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      resizeToAvoidBottomInset: false,
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: _pages[_selectedIndex],
          ),
          _buildBottomNavBar(),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 10,
        left: 16,
        right: 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Theme.of(context).dividerColor,
                  child: Consumer<GameManager>(
                    builder: (context, gameManager, _) {
                      final user = gameManager.userProfile;
                      return !gameManager.isGuest && user?.avatarUrl != null
                          ? ClipOval(
                              child: CachedNetworkImage(
                                imageUrl: user!.avatarUrl!,
                                fit: BoxFit.cover,
                                width: 36,
                                height: 36,
                                placeholder: (_, __) => Container(color: Colors.grey[300]),
                                errorWidget: (_, __, ___) => Icon(
                                  Icons.person,
                                  size: 20,
                                  color: Theme.of(context).textTheme.bodyMedium?.color,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.person,
                              size: 20,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            );
                    },
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
          Image.asset(
            'assets/images/logo.png',
            height: 40,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => Text(
              'MGL',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 28, letterSpacing: 2),
            ),
          ),
          const Spacer(),
          SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: Consumer<ThemeManager>(
                builder: (context, themeManager, _) {
                  final isDark = themeManager.themeMode == ThemeMode.dark;
                  return IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () async {
                      // Small delay to allow button ripple to render before heavy theme rebuild
                      await Future.delayed(const Duration(milliseconds: 50));
                      themeManager.setThemeMode(
                        isDark ? ThemeMode.light : ThemeMode.dark,
                      );
                    },
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      size: 24,
                    ),
                    tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.05 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(color: Theme.of(context).dividerColor, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home_rounded, 'Home', 0),
              _buildNavItem(Icons.forum_rounded, 'Discussions', 1),
              _buildNavItem(Icons.explore_rounded, 'Discover', 2),
              _buildNavItem(Icons.person_rounded, 'Profile', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedIndex == index;
    final color = isSelected
        ? Theme.of(context).colorScheme.primary
        : Colors.grey;

    return InkWell(
      onTap: () => setState(() => _selectedIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withAlpha(25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Consumer<GameManager>(
      builder: (context, gameManager, _) {
        final user = gameManager.userProfile;
        final isGuest = gameManager.isGuest;
        final theme = Theme.of(context);
        
        return Drawer(
          width: 280,
          backgroundColor: theme.brightness == Brightness.dark
              ? const Color(0xFF1A1A1A)
              : Colors.white,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (User Profile or Login Prompt)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF009DDB), // Custom Blue
                        Color(0xFFFCD000), // Custom Yellow
                        Color(0xFFE71E07), // Custom Red
                      ],
                    ),
                    border: Border(
                      bottom: BorderSide(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withAlpha(25)
                            : Colors.black.withAlpha(25),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Avatar
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: !isGuest && user?.avatarUrl != null
                          ? CachedNetworkImage(
                             imageUrl: user!.avatarUrl!,
                             fit: BoxFit.cover,
                             placeholder: (context, url) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                             errorWidget: (context, url, error) => const Center(child: Icon(Icons.person, size: 30)),
                            ) 
                          : const Center(
                              child: Icon(Icons.person, color: Colors.grey, size: 30),
                            ),
                      ),
                      const SizedBox(height: 12),
                      
                      if (isGuest) ...[
                        const Text(
                          'Welcome, Guest',
                          style: TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: () {
                             Navigator.pop(context);
                             Navigator.push(
                               context, 
                               MaterialPageRoute(builder: (_) => const AuthPage()),
                             );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF1A1A1A)),
                            foregroundColor: const Color(0xFF1A1A1A),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          ),
                          child: const Text('Log In / Sign Up'),
                        ),
                      ] else ...[
                        Text(
                          user?.username ?? 'Gamer',
                          style: const TextStyle(
                            color: Color(0xFF1A1A1A),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            color: const Color(0xFF1A1A1A).withAlpha(200),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                _buildSidebarItem('Settings', Icons.settings, () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsPage()),
                  );
                }),
                
                if (!isGuest)
                  _buildSidebarItem('Log Out', Icons.logout, () async {
                    Navigator.pop(context);
                    await context.read<AuthService>().signOut();
                    if (!context.mounted) return;
                    // Go back to splash or auth
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthPage()),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebarItem(String title, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        color: Theme.of(context).brightness == Brightness.dark
            ? const Color(0xFF1A1A1A)
            : Colors.white,
        child: Row(
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyLarge),
            const Spacer(),
            Icon(
              icon,
              color: Theme.of(context).textTheme.bodyMedium?.color,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }


}
