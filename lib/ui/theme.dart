import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theme definitions.
/// 
/// Provides consistent light and dark themes with custom color schemes,
/// typography using Inter font, and component styling.

/// Light theme configuration.
final ThemeData lightTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.blue,
  scaffoldBackgroundColor: Colors.grey[100],
  cardColor: Colors.white,
  dividerColor: Colors.grey[300],
  textTheme: GoogleFonts.interTextTheme(
    TextTheme(
      bodyLarge: TextStyle(color: Colors.grey[800]),
      bodyMedium: TextStyle(color: Colors.grey[600]),
      titleLarge: TextStyle(color: Colors.grey[900], fontWeight: FontWeight.bold),
      titleMedium: TextStyle(
        color: Colors.grey[800],
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
  colorScheme: ColorScheme.light(
    primary: Colors.blue,
    secondary: Colors.teal,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Colors.black87,
    error: Colors.red,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Colors.grey[100],
    elevation: 0,
    iconTheme: const IconThemeData(color: Colors.black54),
    titleTextStyle: GoogleFonts.inter(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
);

/// Dark theme configuration.
final ThemeData darkTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Colors.blue[300],
  scaffoldBackgroundColor: const Color(0xFF121212),
  cardColor: const Color(0xFF1E1E1E),
  dividerColor: Colors.grey[800],
  textTheme: GoogleFonts.interTextTheme(
    const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white70),
      titleLarge: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      titleMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
    ),
  ),
  colorScheme: ColorScheme.dark(
    primary: Colors.blue[300]!,
    secondary: Colors.tealAccent[200]!,
    surface: const Color(0xFF1E1E1E),
    onPrimary: Colors.black,
    onSecondary: Colors.black,
    onSurface: Colors.white,
    error: Colors.redAccent,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFF121212),
    elevation: 0,
    titleTextStyle: GoogleFonts.inter(
      color: Colors.white,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
);
