import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/responsive_layout.dart';

/// A responsive row of 7 day cells (weekly streak). Each cell expands to fill
/// available width so the layout adapts to small and large screens without overflow.
class ResponsiveWeeklyStreakRow extends StatelessWidget {
  const ResponsiveWeeklyStreakRow({
    super.key,
    required this.last7Days,
  });

  final List<bool> last7Days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now();
    final labelFontSize = ResponsiveLayout.scaledFontSize(context, 11);

    return Row(
      children: List.generate(7, (i) {
        final date = today.subtract(Duration(days: 6 - i));
        final isCompleted = i < last7Days.length && last7Days[i];
        final isToday = i == 6;
        final label = isToday ? 'Today' : DateFormat('EEE').format(date);

        return Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = constraints.maxWidth;
              final baseCircle = ResponsiveLayout.spacing(context, 36);
              final circleSize = cellWidth < baseCircle ? cellWidth : baseCircle;
              final iconSize = circleSize * (20 / 36);

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: circleSize,
                    height: circleSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCompleted
                          ? theme.colorScheme.primary.withValues(alpha: 0.3)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                      border: Border.all(
                        color: isCompleted
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.5),
                        width: isCompleted ? 2 : 1,
                      ),
                    ),
                    child: isCompleted
                        ? Icon(
                            Icons.check,
                            size: iconSize,
                            color: theme.colorScheme.primary,
                          )
                        : null,
                  ),
                  SizedBox(height: ResponsiveLayout.spacing(context, 4)),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: labelFontSize,
                        fontWeight: isToday ? FontWeight.bold : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    );
  }
}
