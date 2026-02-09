import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nback_pro/src/core/constants/app_strings.dart';
import 'package:nback_pro/src/core/theme/app_theme.dart';
import 'package:nback_pro/src/data/models/user_settings.dart';
import 'package:nback_pro/src/logic/providers/game_provider.dart';
import 'package:nback_pro/src/presentation/screens/session_summary/session_summary_screen.dart';
import '../../test_helpers.dart';

void main() {
  testWidgets('SessionSummaryScreen with data shows nLevel and scores', (tester) async {
    final container = ProviderContainer(
      overrides: [
        ...testOverrides(settings: UserSettings()),
        lastSessionSummaryProvider.overrideWith((ref) => SessionSummaryData(
            nLevel: 2,
            audioScore: 0.8,
            visualScore: 0.9,
            totalAccuracy: 0.85,
            newN: 3,
            isAutoN: true,
          )),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.getTheme(0),
          home: const SessionSummaryScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.sessionComplete), findsOneWidget);
    expect(find.text(AppStrings.sessionResults), findsOneWidget);
  });
}
