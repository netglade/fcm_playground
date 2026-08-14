import 'package:flutter/material.dart';

/// The step a scenario needs a human to perform.
///
/// `SelectableText` in a monospace face, because most of these are adb commands
/// and a command that cannot be copied is a command that will be mistyped —
/// `set-standby-bucket` in particular.
class ManualStepsBlock extends StatelessWidget {
  /// Shows [steps] as copyable text.
  const ManualStepsBlock({required this.steps, super.key});

  /// The instruction, verbatim from the scenario.
  final String steps;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          steps,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
        ),
      ),
    );
  }
}
