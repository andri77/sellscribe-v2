import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../config/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          _buildSectionHeader(context, 'Profile'),
          Card(
            child: Column(
              children: [
                Semantics(
                  label: 'edit-profile-tile',
                  button: true,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryColor,
                      child: Text(
                        user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user?.fullName ?? 'User'),
                    subtitle: Text(user?.email ?? ''),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/profile'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          Card(
            child: Column(
              children: [
                Semantics(
                  label: 'theme-button',
                  child: ListTile(
                    leading: Icon(themeProvider.themeModeIcon),
                    title: const Text('Theme'),
                    subtitle: Text(themeProvider.themeModeDisplayName),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showThemeSelector(context, themeProvider),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Payment Section
          _buildSectionHeader(context, 'Payments'),
          Card(
            child: Column(
              children: [
                Semantics(
                  label: 'payment-methods-tile',
                  button: true,
                  child: ListTile(
                    leading: const Icon(Icons.credit_card),
                    title: const Text('Payment Methods'),
                    subtitle: const Text('Manage your cards'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/payment-methods'),
                  ),
                ),
                const Divider(height: 1),
                Semantics(
                  label: 'purchase-credits-tile',
                  button: true,
                  child: ListTile(
                    leading: const Icon(Icons.monetization_on),
                    title: const Text('Purchase Credits'),
                    subtitle: Text('${user?.creditsRemaining ?? 0} credits remaining'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/purchase-credits'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Account Section
          _buildSectionHeader(context, 'Account'),
          Card(
            child: Column(
              children: [
                Semantics(
                  label: 'sign-out-button',
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                    title: const Text(
                      'Sign Out',
                      style: TextStyle(color: AppTheme.errorColor),
                    ),
                    onTap: () => _showSignOutDialog(context, authProvider),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context, ThemeProvider themeProvider) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Theme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.light_mode),
              title: const Text('Light'),
              trailing: themeProvider.themeMode == AppThemeMode.light
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.light);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode),
              title: const Text('Dark'),
              trailing: themeProvider.themeMode == AppThemeMode.dark
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.dark);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_brightness),
              title: const Text('System'),
              trailing: themeProvider.themeMode == AppThemeMode.system
                  ? const Icon(Icons.check, color: AppTheme.primaryColor)
                  : null,
              onTap: () {
                themeProvider.setThemeMode(AppThemeMode.system);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          Semantics(
            label: 'confirm-sign-out-button',
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                authProvider.signOut();
                context.go('/login');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorColor,
              ),
              child: const Text('Sign Out'),
            ),
          ),
        ],
      ),
    );
  }
}
