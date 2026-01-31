import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'logic/providers/router_provider.dart';
import 'logic/providers/settings_provider.dart';

class NBackApp extends ConsumerWidget {
  const NBackApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final themeId = settingsAsync.valueOrNull?.selectedThemeId ?? 0;
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'N-Back Pro',
      theme: AppTheme.getTheme(themeId),
      routerConfig: router,
    );
  }
}
