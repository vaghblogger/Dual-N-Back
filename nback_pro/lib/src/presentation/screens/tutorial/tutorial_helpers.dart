import 'package:flutter/material.dart';

/// Renders [text] with segments between ** shown in bold (e.g. "See **position** and **letter**").
Widget buildStepText(BuildContext context, String text) {
  final base = Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
  final parts = text.split('**');
  final spans = <TextSpan>[];
  for (var i = 0; i < parts.length; i++) {
    spans.add(TextSpan(
      text: parts[i],
      style: i.isOdd ? base.copyWith(fontWeight: FontWeight.bold) : base,
    ));
  }
  return RichText(
    textAlign: TextAlign.center,
    text: TextSpan(style: base.copyWith(color: Theme.of(context).colorScheme.onSurface), children: spans),
  );
}
