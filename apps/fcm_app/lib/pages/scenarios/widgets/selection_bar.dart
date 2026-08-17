import 'package:flutter/material.dart';

/// Turns batch selection on, and drives it once it is on.
///
/// It lives inside the page rather than in the `AppBar`: the `AppBar` belongs to
/// `AppShell` and derives its title from the destination, and threading one page's
/// actions through it would entangle all four.
class SelectionBar extends StatelessWidget {
  const SelectionBar({
    required this.selectedCount,
    required this.isSelecting,
    required this.onStart,
    required this.onCancel,
    required this.onSchedule,
    super.key,
  });

  final int selectedCount;

  final bool isSelecting;

  final VoidCallback onStart;

  final VoidCallback onCancel;

  final VoidCallback onSchedule;

  @override
  Widget build(BuildContext context) {
    if (!isSelecting) {
      return Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.checklist_outlined),
          label: const Text('Select for a batch'),
        ),
      );
    }

    return Row(
      children: [
        Expanded(child: Text('$selectedCount selected')),
        TextButton(onPressed: onCancel, child: const Text('Cancel')),
        const SizedBox(width: 8),
        FilledButton(
          // Disabled rather than hidden, so the button does not move under a
          // finger that is about to press it.
          onPressed: selectedCount == 0 ? null : onSchedule,
          child: const Text('Schedule…'),
        ),
      ],
    );
  }
}
