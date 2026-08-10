import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// The row of presets at the top of the sandbox.
///
/// Selection is derived from the draft's event rather than stored, so editing
/// the event dropdown moves the highlight too — there is no second source of
/// truth to keep in step.
class ScenarioGallery extends StatelessWidget {
  const ScenarioGallery({
    required this.selectedEvent,
    required this.onSelected,
    super.key,
  });

  final NotificationEvent selectedEvent;
  final ValueChanged<NotificationScenario> onSelected;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final scenario in notificationGallery)
        ChoiceChip(
          key: ValueKey(scenario.id),
          label: Text(scenario.label),
          tooltip: scenario.description,
          selected: scenario.draft.event == selectedEvent,
          onSelected: (_) => onSelected(scenario),
        ),
    ],
  );
}
