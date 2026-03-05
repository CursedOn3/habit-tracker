import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:share_plus/share_plus.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../services/habit_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/constants.dart';
import '../auth/login_screen.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>(
  (ref) => ThemeModeNotifier(),
);

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final box = Hive.box(AppConstants.settingsBox);
    final saved = box.get(AppConstants.themeKey, defaultValue: 'system') as String;
    state = _parseThemeMode(saved);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(AppConstants.themeKey, _themeModeToString(mode));
  }

  ThemeMode _parseThemeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      default:
        return 'system';
    }
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authStateProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Profile section
          if (user != null) ...[
            _SettingsSection(
              title: 'Account',
              children: [
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                    child: Text(
                      user.email?.substring(0, 1).toUpperCase() ?? 'U',
                      style: const TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(user.displayName ?? 'User'),
                  subtitle: Text(user.email ?? ''),
                  trailing: const Icon(Icons.verified_user_outlined,
                      color: AppTheme.successColor),
                ),
              ],
            ),
          ],

          // Appearance
          _SettingsSection(
            title: 'Appearance',
            children: [
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Theme'),
                subtitle: Text(_themeModeLabel(themeMode)),
                trailing: DropdownButton<ThemeMode>(
                  value: themeMode,
                  underline: const SizedBox.shrink(),
                  onChanged: (mode) {
                    if (mode != null) {
                      ref.read(themeModeProvider.notifier).setThemeMode(mode);
                    }
                  },
                  items: const [
                    DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text('System'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text('Light'),
                    ),
                    DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text('Dark'),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Data
          _SettingsSection(
            title: 'Data',
            children: [
              ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('Export Data as CSV'),
                subtitle: const Text('Download all your habits and completions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _exportData(context, ref),
              ),
              ListTile(
                leading: const Icon(Icons.sync_outlined),
                title: const Text('Sync with Firebase'),
                subtitle: const Text('Manually sync data to/from cloud'),
                trailing: const Icon(Icons.chevron_right),
                onTap:
                    user != null
                        ? () => ref
                            .read(habitNotifierProvider.notifier)
                            .refreshHabits()
                        : null,
              ),
            ],
          ),

          // About
          _SettingsSection(
            title: 'About',
            children: [
              ListTile(
                leading: const Icon(Icons.info_outlined),
                title: const Text('Version'),
                subtitle: Text(AppConstants.appVersion),
              ),
              ListTile(
                leading: const Icon(Icons.code_outlined),
                title: const Text('App Name'),
                subtitle: Text(AppConstants.appName),
              ),
            ],
          ),

          // Auth
          _SettingsSection(
            title: 'Account',
            children: [
              if (user != null)
                ListTile(
                  leading: const Icon(
                    Icons.logout,
                    color: AppTheme.errorColor,
                  ),
                  title: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  onTap: () async {
                    await ref.read(authNotifierProvider.notifier).signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    }
                  },
                )
              else
                ListTile(
                  leading: const Icon(Icons.login),
                  title: const Text('Sign In'),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  },
                ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      default:
        return 'System default';
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final habits = ref.read(habitNotifierProvider).habits;
      final habitService = ref.read(habitServiceProvider);
      final csv = habitService.exportToCsv(habits);
      await Share.share(csv, subject: 'HabitFlow Data Export');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Text(
            title.toUpperCase(),
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
              color: AppTheme.primaryColor,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            border: Border(
              top: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
              bottom: BorderSide(color: theme.dividerColor.withOpacity(0.3)),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}
