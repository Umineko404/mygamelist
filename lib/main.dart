import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'managers/game_manager.dart';
import 'managers/theme_manager.dart';
import 'ui/pages/home_page.dart';
import 'ui/theme.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GameManager()),
        ChangeNotifierProvider(create: (_) => ThemeManager()),
      ],
      child: const MyGameListApp(),
    ),
  );
}

class MyGameListApp extends StatelessWidget {
  const MyGameListApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return MaterialApp(
          title: 'MyGameList',
          debugShowCheckedModeBanner: false,
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: themeManager.themeMode,
          themeAnimationDuration: const Duration(milliseconds: 0),
          themeAnimationCurve: Curves.easeInOut,
          home: const HomePage(),
        );
      },
    );
  }
}