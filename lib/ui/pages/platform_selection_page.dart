import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../managers/game_manager.dart';

class PlatformSelectionPage extends StatefulWidget {
  const PlatformSelectionPage({super.key});

  @override
  State<PlatformSelectionPage> createState() => _PlatformSelectionPageState();
}

class _PlatformSelectionPageState extends State<PlatformSelectionPage> {
  // Common platforms with hardcoded slugs/names (could be fetched dynamically)
  final List<Map<String, dynamic>> _allPlatforms = [
    // PC Platforms
    {'name': 'PC', 'slug': 'pc', 'icon': Icons.computer},
    {'name': 'macOS', 'slug': 'macos', 'icon': Icons.laptop_mac},
    {'name': 'Linux', 'slug': 'linux', 'icon': Icons.terminal},
    
    // Current Gen Consoles
    {'name': 'PlayStation 5', 'slug': 'playstation5', 'icon': Icons.gamepad},
    {'name': 'Xbox Series X/S', 'slug': 'xbox-series-x', 'icon': Icons.videogame_asset},
    {'name': 'Nintendo Switch', 'slug': 'nintendo-switch', 'icon': Icons.sports_esports},
    
    // Previous Gen Consoles
    {'name': 'PlayStation 4', 'slug': 'playstation4', 'icon': Icons.gamepad},
    {'name': 'PlayStation 3', 'slug': 'playstation3', 'icon': Icons.gamepad},
    {'name': 'PlayStation 2', 'slug': 'playstation2', 'icon': Icons.gamepad},
    {'name': 'PlayStation', 'slug': 'playstation1', 'icon': Icons.gamepad},
    {'name': 'PS Vita', 'slug': 'ps-vita', 'icon': Icons.videogame_asset_outlined},
    {'name': 'PSP', 'slug': 'psp', 'icon': Icons.videogame_asset_outlined},
    
    {'name': 'Xbox One', 'slug': 'xbox-one', 'icon': Icons.videogame_asset},
    {'name': 'Xbox 360', 'slug': 'xbox360', 'icon': Icons.videogame_asset},
    {'name': 'Xbox', 'slug': 'xbox-old', 'icon': Icons.videogame_asset},
    
    {'name': 'Wii U', 'slug': 'wii-u', 'icon': Icons.sports_esports},
    {'name': 'Wii', 'slug': 'wii', 'icon': Icons.sports_esports},
    {'name': 'GameCube', 'slug': 'gamecube', 'icon': Icons.sports_esports},
    {'name': 'Nintendo 64', 'slug': 'nintendo-64', 'icon': Icons.sports_esports},
    {'name': 'Nintendo 3DS', 'slug': 'nintendo-3ds', 'icon': Icons.videogame_asset_outlined},
    {'name': 'Nintendo DS', 'slug': 'nintendo-ds', 'icon': Icons.videogame_asset_outlined},
    {'name': 'Game Boy Advance', 'slug': 'game-boy-advance', 'icon': Icons.videogame_asset_outlined},
    {'name': 'Game Boy Color', 'slug': 'game-boy-color', 'icon': Icons.videogame_asset_outlined},
    {'name': 'Game Boy', 'slug': 'game-boy', 'icon': Icons.videogame_asset_outlined},
    
    // Mobile
    {'name': 'iOS', 'slug': 'ios', 'icon': Icons.phone_iphone},
    {'name': 'Android', 'slug': 'android', 'icon': Icons.phone_android},
    
    // Retro/Classic
    {'name': 'Sega Dreamcast', 'slug': 'dreamcast', 'icon': Icons.gamepad},
    {'name': 'Sega Saturn', 'slug': 'sega-saturn', 'icon': Icons.gamepad},
    {'name': 'Sega Genesis', 'slug': 'sega-genesis', 'icon': Icons.gamepad},
    {'name': 'SNES', 'slug': 'snes', 'icon': Icons.sports_esports},
    {'name': 'NES', 'slug': 'nes', 'icon': Icons.sports_esports},
    {'name': 'Atari', 'slug': 'atari-2600', 'icon': Icons.sports_esports},
    
    // VR
    {'name': 'Meta Quest', 'slug': 'meta-quest', 'icon': Icons.vrpano},
    {'name': 'PlayStation VR', 'slug': 'playstation-vr', 'icon': Icons.vrpano},
    
    // Other
    {'name': 'Web Browser', 'slug': 'web', 'icon': Icons.language},
  ];

  late Set<String> _selectedSlugs;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<GameManager>().userProfile;
    _selectedSlugs = Set.from(user?.ownedPlatforms ?? []);
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await context.read<GameManager>().updateProfile(
        ownedPlatforms: _selectedSlugs.toList(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving platforms: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Platforms'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator())
              : const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: _allPlatforms.length,
        itemBuilder: (context, index) {
          final platform = _allPlatforms[index];
          final slug = platform['slug'] as String;
          final isSelected = _selectedSlugs.contains(slug);
          final theme = Theme.of(context);

          return InkWell(
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedSlugs.remove(slug);
                } else {
                  _selectedSlugs.add(slug);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                  width: 2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.primary.withAlpha(100),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    platform['icon'] as IconData,
                    size: 32,
                    color: isSelected ? Colors.white : theme.iconTheme.color,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    platform['name'] as String,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
