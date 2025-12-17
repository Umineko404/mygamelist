import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/user_data_service.dart';

/// Page for selecting gaming platforms the user owns.
class PlatformSelectionPage extends StatefulWidget {
  const PlatformSelectionPage({super.key});

  @override
  State<PlatformSelectionPage> createState() => _PlatformSelectionPageState();
}

class _PlatformSelectionPageState extends State<PlatformSelectionPage> {
  final List<GamingPlatform> _allPlatforms = [
    GamingPlatform(id: 'pc', name: 'PC', icon: Icons.computer),
    GamingPlatform(id: 'playstation5', name: 'PlayStation 5', icon: Icons.videogame_asset),
    GamingPlatform(id: 'playstation4', name: 'PlayStation 4', icon: Icons.gamepad),
    GamingPlatform(id: 'xbox_series', name: 'Xbox Series X|S', icon: Icons.games),
    GamingPlatform(id: 'xbox_one', name: 'Xbox One', icon: Icons.games_outlined),
    GamingPlatform(id: 'nintendo_switch', name: 'Nintendo Switch', icon: Icons.sports_esports),
    GamingPlatform(id: 'mobile_ios', name: 'iOS / iPhone', icon: Icons.phone_iphone),
    GamingPlatform(id: 'mobile_android', name: 'Android', icon: Icons.android),
    GamingPlatform(id: 'steam_deck', name: 'Steam Deck', icon: Icons.tablet_mac),
    GamingPlatform(id: 'vr', name: 'VR Headset', icon: Icons.vrpano),
  ];

  Set<String> _selectedPlatforms = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadUserPlatforms();
  }

  Future<void> _loadUserPlatforms() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userDataService = Provider.of<UserDataService>(context, listen: false);

    if (authService.isAuthenticated && authService.userId != null) {
      try {
        final platforms = await userDataService.getUserPlatforms(authService.userId!);
        setState(() {
          _selectedPlatforms = platforms.toSet();
          _isLoading = false;
        });
      } catch (e) {
        setState(() => _isLoading = false);
      }
    } else {
      setState(() => _isLoading = false);
    }
  }

  void _togglePlatform(String platformId) {
    setState(() {
      if (_selectedPlatforms.contains(platformId)) {
        _selectedPlatforms.remove(platformId);
      } else {
        _selectedPlatforms.add(platformId);
      }
    });
  }

  Future<void> _savePlatforms() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userDataService = Provider.of<UserDataService>(context, listen: false);

    if (!authService.isAuthenticated || authService.userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please sign in to save your platforms.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await userDataService.saveUserPlatforms(
        authService.userId!,
        _selectedPlatforms.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Platforms saved successfully!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, _selectedPlatforms.toList());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving platforms: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Gaming Platforms'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Select the gaming platforms you own',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.4,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                    itemCount: _allPlatforms.length,
                    itemBuilder: (context, index) {
                      final platform = _allPlatforms[index];
                      final isSelected = _selectedPlatforms.contains(platform.id);

                      return GestureDetector(
                        onTap: () => _togglePlatform(platform.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? colorScheme.primaryContainer
                                : colorScheme.surfaceContainerHighest.withAlpha(128),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? colorScheme.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                platform.icon,
                                size: 36,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                platform.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: isSelected
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: colorScheme.primary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : _savePlatforms,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              'Save (${_selectedPlatforms.length} selected)',
                            ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class GamingPlatform {
  final String id;
  final String name;
  final IconData icon;

  GamingPlatform({
    required this.id,
    required this.name,
    required this.icon,
  });
}
