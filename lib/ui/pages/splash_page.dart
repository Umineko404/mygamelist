import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'home_page.dart';
import 'auth_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Artificial delay for branding/animation
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authService = context.read<AuthService>();
    // If user is already logged in (firebase auth persists), go to Home
    // If not, go to AuthPage (which will handle Guest option)
    if (authService.currentUser != null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
       Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sleek dark start
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo
            Image.asset(
              'assets/images/logo.png',
              width: 280,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Column(
                children: [
                   const Icon(Icons.gamepad_rounded, size: 80, color: Colors.white),
                   const SizedBox(height: 16),
                   Text(
                    'MyGameList',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
