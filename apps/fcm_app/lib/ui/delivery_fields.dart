import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// The how-it-arrives half of the editor: visible or silent, and priority.
///
/// Mirrors `NotificationDelivery`, which is why these two controls sit together
/// rather than being scattered through the form.
class DeliveryFields extends StatelessWidget {
  const DeliveryFields({
    required this.draft,
    required this.onChanged,
    super.key,
  });

  final NotificationDraft draft;
  final ValueChanged<NotificationDraft> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Show as notification'),
        subtitle: const Text('Off sends a silent, data-only push'),
        value: draft.delivery.asNotification,
        onChanged: (value) => onChanged(
          draft.copyWith(
            delivery: draft.delivery.copyWith(asNotification: value),
          ),
        ),
      ),
      Align(
        alignment: Alignment.centerLeft,
        child: SegmentedButton<NotificationPriority>(
          segments: const [
            ButtonSegment(
              value: NotificationPriority.high,
              label: Text('high'),
            ),
            ButtonSegment(
              value: NotificationPriority.normal,
              label: Text('normal'),
            ),
          ],
          selected: {draft.delivery.priority},
          onSelectionChanged: (selection) => onChanged(
            draft.copyWith(
              delivery: draft.delivery.copyWith(priority: selection.first),
            ),
          ),
        ),
      ),
    ],
  );
}
