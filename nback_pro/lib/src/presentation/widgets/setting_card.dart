import 'package:flutter/material.dart';

import '../../core/utils/responsive_layout.dart';

/// Reusable setting card: title, subtitle, optional trailing/child/onTap.
/// Matches Advanced Settings screen style (elevation 0, rounded border).
class SettingCard extends StatelessWidget {
  const SettingCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.child,
    this.onTap,
    this.isDestructive = false,
  });

  final String title;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final Widget? child;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: isDestructive ? theme.colorScheme.error : null,
    );
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
      height: 1.3,
    );

    Widget content = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: ResponsiveLayout.horizontalPadding(context),
        vertical: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Text(
                  title,
                  style: titleStyle,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: subtitleStyle,
          ),
          if (child != null) ...[
            const SizedBox(height: 14),
            child!,
          ],
        ],
      ),
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: content,
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: content,
    );
  }
}
