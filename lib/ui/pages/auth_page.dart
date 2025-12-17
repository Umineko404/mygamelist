import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/auth_service.dart';
import 'home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final authService = context.read<AuthService>();
    final isLogin = _tabController.index == 0;
    
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    // Email validation
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      _showError('Please enter a valid email address.');
      return;
    }

    if (!isLogin) {
      if (username.isEmpty) {
        _showError('Username is required.');
        return;
      }
      if (password.length < 6) {
        _showError('Password must be at least 6 characters.');
        return;
      }
      if (password != confirmPassword) {
        _showError('Passwords do not match.');
        return;
      }
    }

    try {
      if (isLogin) {
        await authService.signIn(email, password);
      } else {
        await authService.signUp(email, password, username);
      }
      
      if (!mounted) return;
      // Navigate to Home on success
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      // Basic error parsing
      String msg = e.toString();
      if (msg.contains('invalid-email')) {
        msg = 'Invalid email address.';
      } else if (msg.contains('user-not-found')) {
        msg = 'User not found.';
      } else if (msg.contains('wrong-password')) {
        msg = 'Incorrect password.';
      } else if (msg.contains('email-already-in-use')) {
        msg = 'Email already in use.';
      } else if (msg.contains('weak-password')) {
        msg = 'Password is too weak.';
      }
      
      _showError(msg);
    }
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Logo
              // Logo
              Image.asset(
                'assets/images/logo.png',
                width: 250, 
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Column(
                  children: [
                    const Icon(Icons.gamepad_rounded, size: 60, color: Colors.white),
                    const SizedBox(height: 16),
                    Text(
                      'MyGameList',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Tab Bar
              Container(
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: theme.colorScheme.primary,
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: theme.textTheme.bodyMedium?.color,
                  dividerColor: Colors.transparent,
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: const [
                    Tab(text: 'Log In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form
              AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) {
                  final isSignUp = _tabController.index == 1;
                  return Column(
                    children: [
                      if (isSignUp) ...[
                        TextField(
                          controller: _usernameController,
                          decoration: _inputDecoration('Username', Icons.person_outline),
                        ),
                        const SizedBox(height: 16),
                      ],
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _inputDecoration('Email', Icons.email_outlined),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: _inputDecoration('Password', Icons.lock_outline),
                      ),
                      if (isSignUp) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: true,
                          decoration: _inputDecoration('Confirm Password', Icons.lock_outline),
                        ),
                      ],
                    ],
                  );
                },
              ),
              
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ],
              
              const SizedBox(height: 32),
              
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _tabController.index == 0 ? 'Log In' : 'Create Account',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                ),
              ),
              
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: Divider(color: theme.dividerColor)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('OR', style: TextStyle(color: theme.textTheme.bodyMedium?.color)),
                ),
                Expanded(child: Divider(color: theme.dividerColor)),
              ]),
              const SizedBox(height: 24),
              
              // Guest Button
              TextButton(
                onPressed: _continueAsGuest,
                child: Text(
                  'Continue as Guest',
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).dividerColor),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }
}
