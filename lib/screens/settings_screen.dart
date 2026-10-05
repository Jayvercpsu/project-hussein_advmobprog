import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/user_service.dart';

class HusseinAdvmobprogSettingsScreen extends StatelessWidget {
  const HusseinAdvmobprogSettingsScreen({super.key});

  // Confirm logout before leaving
  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                false,
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(
                dialogContext,
                true,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    // Stop if logout gets cancelled
    if (confirmed != true) return;

    // Clear the current login session
    await HusseinAdvmobprogUserService().logout();

    if (!context.mounted) return;

    // Return user to login screen
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/sign',
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme settings
    final themeProvider =
        context.watch<HusseinAdvmobprogThemeProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: themeProvider.isDark,
            onChanged: (_) {
              // Switch between light and dark
              themeProvider.toggleTheme();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }
}