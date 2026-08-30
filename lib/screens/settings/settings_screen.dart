import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final auth = context.watch<AppAuthProvider>();
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _profileCard(context, cs, auth),
          const SizedBox(height: 24),
          _sectionLabel('Appearance'),
          const SizedBox(height: 10),
          _settingsTile(
            context,
            title: 'Dark Mode',
            subtitle: theme.isDark ? 'Dark theme active' : 'Light theme active',
            leading: Icon(
              theme.isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: cs.primary,
            ),
            trailing: Switch.adaptive(
              value: theme.isDark,
              onChanged: (_) => theme.toggle(),
            ),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Account'),
          const SizedBox(height: 10),
          if (auth.isSignedIn) ...[
            _settingsTile(
              context,
              title: 'Signed in as',
              subtitle: auth.email,
              leading: Icon(Icons.person_rounded, color: cs.primary),
            ),
            _settingsTile(
              context,
              title: 'Sign Out',
              subtitle: 'Sign out of your account',
              leading: Icon(Icons.logout_rounded, color: Colors.redAccent),
              onTap: () => _confirmSignOut(context, auth),
            ),
          ] else
            _settingsTile(
              context,
              title: 'Sign In',
              subtitle: 'Sign in to sync your data across devices',
              leading: Icon(Icons.person_rounded, color: cs.primary),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              ),
            ),
          const SizedBox(height: 24),
          _sectionLabel('About'),
          const SizedBox(height: 10),
          _settingsTile(
            context,
            title: 'All in One',
            subtitle: 'Version 1.0.0 • Student Utility App',
            leading: Icon(Icons.info_outline_rounded, color: cs.primary),
          ),
          _settingsTile(
            context,
            title: 'Features',
            subtitle: 'Notes, Todo, Expense, Attendance, Utilities, QR & more',
            leading: Icon(Icons.apps_rounded, color: cs.primary),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, AppAuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await auth.signOut();
            },
            child: const Text('Sign Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _profileCard(
    BuildContext context,
    ColorScheme cs,
    AppAuthProvider auth,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cs.primary, cs.primary.withBlue(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(
              Icons.person_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  auth.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  auth.isSignedIn ? auth.email : 'Sign in to sync data',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
      color: Colors.grey,
    ),
  );

  Widget _settingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Widget leading,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1F2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: leading,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
        ),
        trailing:
            trailing ??
            (onTap != null
                ? Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.grey[400],
                  )
                : null),
        onTap: onTap,
      ),
    );
  }
}
