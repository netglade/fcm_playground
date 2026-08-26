import 'package:flutter/material.dart';

/// One property on a `ChannelCard`: what the app asked for, against what the
/// system reports back.
///
/// Extracted into its own file rather than kept private alongside `ChannelCard`,
/// the same reason `EventRow` is: DCM's `prefer-single-widget-per-file` counts a
/// private widget class too, and this shape — a label plus two values — is
/// exactly what every one of the six properties needs, the same way `EventRow`
/// is shared across all ten event types.
class ChannelPropertyRow extends StatelessWidget {
  const ChannelPropertyRow({
    required this.label,
    required this.requested,
    required this.reported,
    required this.mismatches,
    super.key,
  });

  final String label;

  final String requested;

  /// What the system answered, or the "not registered" text when the channel
  /// does not exist — the caller decides which, so this widget stays ignorant
  /// of that distinction and just renders whatever string it is given.
  final String reported;

  /// True when [reported] disagrees with [requested] — including when the
  /// channel is not registered at all, since that is the starkest disagreement
  /// there is.
  final bool mismatches;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reportedStyle = mismatches
        ? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)
        : theme.textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(requested)),
          Expanded(child: Text(reported, style: reportedStyle)),
        ],
      ),
    );
  }
}
