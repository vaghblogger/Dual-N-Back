import 'package:flutter_test/flutter_test.dart';

import 'package:nback_pro/src/core/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme returns valid theme for each id', (WidgetTester tester) async {
    for (var id = 0; id < AppTheme.themeCount; id++) {
      final theme = AppTheme.getTheme(id);
      expect(theme, isNotNull);
      expect(theme.scaffoldBackgroundColor, isNotNull);
      expect(theme.colorScheme.primary, isNotNull);
    }
  });

  testWidgets('AppTheme out-of-range id returns default theme', (WidgetTester tester) async {
    final defaultTheme = AppTheme.getTheme(0);
    expect(AppTheme.getTheme(-1).scaffoldBackgroundColor, defaultTheme.scaffoldBackgroundColor);
    expect(AppTheme.getTheme(99).scaffoldBackgroundColor, defaultTheme.scaffoldBackgroundColor);
  });
}
