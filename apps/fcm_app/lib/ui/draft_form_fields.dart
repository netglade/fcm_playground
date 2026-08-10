import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// The what-it-says half of the editor: event, title, body.
///
/// Seeded from [draft] once. `SandboxView` keys this widget on the controller's
/// scenario generation, so applying a scenario rebuilds it with new values
/// while typing does not disturb the cursor.
class DraftFormFields extends StatelessWidget {
  const DraftFormFields({
    required this.draft,
    required this.problems,
    required this.onChanged,
    super.key,
  });

  final NotificationDraft draft;
  final List<DraftProblem> problems;
  final ValueChanged<NotificationDraft> onChanged;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      InputDecorator(
        decoration: const InputDecoration(labelText: 'Event'),
        child: DropdownButton<NotificationEvent>(
          value: draft.event,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          items: [
            for (final event in NotificationEvent.values)
              DropdownMenuItem(value: event, child: Text(event.wireName)),
          ],
          onChanged: (event) =>
              event == null ? null : onChanged(draft.copyWith(event: event)),
        ),
      ),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: draft.title,
        decoration: InputDecoration(
          labelText: 'Title',
          errorText: _reasonFor('title'),
        ),
        onChanged: (value) => onChanged(draft.copyWith(title: value)),
      ),
      const SizedBox(height: 8),
      TextFormField(
        initialValue: draft.body,
        minLines: 2,
        maxLines: 4,
        decoration: InputDecoration(
          labelText: 'Body',
          errorText: _reasonFor('body'),
        ),
        onChanged: (value) => onChanged(draft.copyWith(body: value)),
      ),
    ],
  );

  String? _reasonFor(String field) => problems
      .where((problem) => problem.field == field)
      .map((problem) => problem.reason)
      .firstOrNull;
}
