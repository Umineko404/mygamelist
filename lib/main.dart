import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'managers/game_manager.dart';
import 'managers/theme_manager.dart';
import 'services/auth_service.dart';
import 'ui/pages/auth_page.dart';
import 'ui/pages/home_page.dart';
import 'ui/theme.dart';

/// Application entry point.
/// Initializes Firebase and sets up state management providers.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => GameManager()),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
      ],
      child: const MyGameListApp(),
    ),
  );
}

/// Root application widget.
/// Configures theming and navigation.
class MyGameListApp extends StatelessWidget {
  const MyGameListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeManager, AuthService>(
      builder: (context, themeManager, authService, child) {
        return MaterialApp(
          title: 'MyGameList',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeManager.themeMode,
          home: authService.isAuthenticated ? const HomePage() : const AuthPage(),
        );
      },
    );
  }
}
