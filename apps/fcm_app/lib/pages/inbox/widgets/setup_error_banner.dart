import 'package:flutter/material.dart';

/// Explains, in the app itself, why no pushes will arrive.
class SetupErrorBanner extends StatelessWidget {
  const SetupErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return ColoredBox(
      color: colors.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: colors.onErrorContainer),
        ),
      ),
    );
  }
}
