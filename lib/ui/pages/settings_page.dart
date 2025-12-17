import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../managers/theme_manager.dart';
import '../../services/auth_service.dart';
import 'auth_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Mock setting for this session
  int _defaultTabIndex = 0; // 0: Discover, 1: My List

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          _buildSectionHeader('Appearance'),
          _buildThemeSection(),
          
          _buildSectionHeader('General'),
          _buildGeneralSection(),
          
          _buildSectionHeader('Account'),
          _buildAccountSection(context),
          
          _buildSectionHeader('About'),
          _buildAboutSection(context),
          
          const SizedBox(height: 40),
          Center(
            child: Text(
              'MyGameList v1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Consumer<ThemeManager>(
      builder: (context, themeManager, child) {
        return Column(
          children: [
            RadioListTile<ThemeMode>(
              title: const Text('System Default'),
              subtitle: const Text('Use system light/dark mode settings'),
              value: ThemeMode.system,
              groupValue: themeManager.themeMode,
              onChanged: (value) => themeManager.setThemeMode(value!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Light Mode'),
              value: ThemeMode.light,
              groupValue: themeManager.themeMode,
              onChanged: (value) => themeManager.setThemeMode(value!),
            ),
            RadioListTile<ThemeMode>(
              title: const Text('Dark Mode'),
              value: ThemeMode.dark,
              groupValue: themeManager.themeMode,
              onChanged: (value) => themeManager.setThemeMode(value!),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGeneralSection() {
    return Column(
      children: [
        ListTile(
          title: const Text('Default Tab'),
          subtitle: Text(_defaultTabIndex == 0 ? 'Discover' : 'My List'),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => SimpleDialog(
                title: const Text('Select Default Tab'),
                children: [
                  SimpleDialogOption(
                    onPressed: () {
                      setState(() => _defaultTabIndex = 0);
                      Navigator.pop(context);
                    },
                    child: const Text('Discover'),
                  ),
                  SimpleDialogOption(
                    onPressed: () {
                      setState(() => _defaultTabIndex = 1);
                      Navigator.pop(context);
                    },
                    child: const Text('My List'),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final isGuest = authService.isGuest;

    if (isGuest) {
      return ListTile(
        title: const Text('Sign In / Register'),
        leading: const Icon(Icons.login),
        onTap: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AuthPage()),
          );
        },
      );
    }

    final userEmail = authService.currentUser?.email ?? '';

    return Column(
      children: [
        ListTile(
          title: const Text('Email'),
          subtitle: Text(userEmail),
          leading: const Icon(Icons.email_outlined),
        ),
        ListTile(
          title: const Text('Change Password'),
          leading: const Icon(Icons.lock_reset),
          onTap: () async {
            try {
              if (userEmail.isNotEmpty) {
                await authService.sendPasswordResetEmail(userEmail);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password reset email sent! Check your inbox.'),
                    ),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error sending email: $e')),
                );
              }
            }
          },
        ),
        ListTile(
          title: const Text(
            'Delete Account',
            style: TextStyle(color: Colors.red),
          ),
          leading: const Icon(Icons.delete_forever, color: Colors.red),
          onTap: () => _showDeleteAccountConfirmation(context, authService),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: const Text('Privacy Policy'),
          leading: const Icon(Icons.privacy_tip_outlined),
          onTap: () => _showTextDialog(context, 'Privacy Policy'),
        ),
        ListTile(
          title: const Text('Terms of Service'),
          leading: const Icon(Icons.description_outlined),
          onTap: () => _showTextDialog(context, 'Terms of Service'),
        ),
      ],
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context, AuthService authService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account?'),
        content: const Text(
          'This action cannot be undone. All your data, including your game list and reviews, will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await authService.deleteAccount();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                    (route) => false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Delete failed: $e. You may need to re-login first.')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showTextDialog(BuildContext context, String title) {
    // Simple placeholder text for demonstration
    final String content = title == 'Privacy Policy'
        ? 'This Privacy Policy describes how your personal information is collected, used, and shared when you use the MyGameList application.\n\nWe collect basic account information (email) to provide synchronization features. We use Firebase services for authentication and data storage. We do not sell your personal data to third parties.'
        : 'By using MyGameList, you agree to these Terms of Service.\n\n1. You must be at least 13 years old to use this service.\n2. You are responsible for maintaining the security of your account.\n3. Do not post illegal or abusive content in reviews.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SingleChildScrollView(
          child: Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
