import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nback_pro/src/core/theme/app_theme.dart';
import 'package:nback_pro/src/presentation/widgets/responsive_weekly_streak_row.dart';

void main() {
  testWidgets('ResponsiveWeeklyStreakRow shows 7 cells', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(0),
        home: Scaffold(
          body: ResponsiveWeeklyStreakRow(
            last7Days: List.filled(7, false),
          ),
        ),
      ),
    );
    expect(find.byType(ResponsiveWeeklyStreakRow), findsOneWidget);
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('ResponsiveWeeklyStreakRow shows correct number of completed indicators', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(0),
        home: Scaffold(
          body: ResponsiveWeeklyStreakRow(
            last7Days: [true, false, true, false, true, false, true],
          ),
        ),
      ),
    );
    expect(find.byIcon(Icons.check), findsNWidgets(4));
  });

  testWidgets('ResponsiveWeeklyStreakRow shows Today label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.getTheme(0),
        home: Scaffold(
          body: ResponsiveWeeklyStreakRow(
            last7Days: List.filled(7, false),
          ),
        ),
      ),
    );
    expect(find.text('Today'), findsOneWidget);
  });
}
