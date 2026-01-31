import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../logic/providers/settings_provider.dart';

class ThemeSelectionScreen extends ConsumerWidget {
  const ThemeSelectionScreen({this.fromSettings = false, super.key});

  final bool fromSettings;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.selectTheme)),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => const Center(child: Text('Error loading settings')),
        data: (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.9,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: AppTheme.themeCount,
                  itemBuilder: (context, index) {
                    final theme = AppTheme.getTheme(index);
                    return _ThemeCard(
                      themeId: index,
                      theme: theme,
                      onTap: () async {
                        await ref.read(settingsProvider.notifier).updateTheme(index);
                        if (!context.mounted) return;
                        if (fromSettings) {
                          Navigator.of(context).pop();
                        } else {
                          context.go('/login');
                        }
                      },
                    );
                  },
                ),
              ),
              if (!fromSettings) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text(AppStrings.next),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.themeId,
    required this.theme,
    required this.onTap,
  });

  final int themeId;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = theme.scaffoldBackgroundColor;
    final surface = theme.cardColor;
    final primary = theme.colorScheme.primary;
    final text = theme.colorScheme.onSurface;

    return Card(
      color: surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: bg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Theme ${themeId + 1}',
                style: TextStyle(color: text, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
