import 'package:core/core.dart';

import 'draft_problem.dart';
import 'notification_draft.dart';

/// The single validation both the app and the server run.
///
/// The app renders the problems inline and disables Send; the server runs the
/// same rules and answers 400, so the app is not the only line of defence.
class NotificationDraftValidator {
  const NotificationDraftValidator();

  /// Validates a draft. Duplicate data keys are unreachable here — a map cannot
  /// hold one — so use [validateEntries] for editor rows.
  List<DraftProblem> validate(NotificationDraft draft) => validateEntries(
    title: draft.title,
    body: draft.body,
    data: draft.data.entries.toList(),
  );

  /// Validates the parts of a draft while the data keys are still a list, so a
  /// key the user has typed twice can be reported instead of silently losing one.
  List<DraftProblem> validateEntries({
    required String title,
    required String body,
    required List<MapEntry<String, String>> data,
  }) {
    final problems = <DraftProblem>[
      if (title.trim().isEmpty)
        const DraftProblem('title', 'must not be blank'),
      if (body.trim().isEmpty) const DraftProblem('body', 'must not be blank'),
    ];

    final seen = <String>{};
    for (final entry in data) {
      problems.addAll(_problemsForKey(entry.key, seen));
    }

    return List.unmodifiable(problems);
  }

  Iterable<DraftProblem> _problemsForKey(String key, Set<String> seen) {
    if (key.trim().isEmpty) {
      return const [DraftProblem('data', 'has a blank key')];
    }
    if (PushMessageParser.reservedKeys.contains(key)) {
      return [
        DraftProblem('data.$key', 'collides with a reserved payload key'),
      ];
    }
    if (!seen.add(key)) {
      return [DraftProblem('data.$key', 'is duplicated')];
    }

    return const [];
  }
}
