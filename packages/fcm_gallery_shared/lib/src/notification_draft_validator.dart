import 'package:core/core.dart';

import 'draft_problem.dart';
import 'notification_draft.dart';

/// Checks a draft before it is sent.
///
/// Deliberately shared: the editor uses it to render inline errors and to
/// disable its send button, and the function runs it again on the request it
/// receives. The app is therefore not the only line of defence, and there is
/// only one place to change a rule.
class NotificationDraftValidator {
  const NotificationDraftValidator();

  /// Data keys the sender writes itself, which a draft may not overwrite.
  ///
  /// Built from `core`'s own set so the four keys `PushMessageParser` requires
  /// stay defined in exactly one place, plus `event`, which
  /// `NotificationMessageBuilder` adds.
  static const reservedDataKeys = {...PushMessageParser.reservedKeys, 'event'};

  /// Every problem with [draft], in a stable order. Empty means sendable.
  List<DraftProblem> validate(NotificationDraft draft) => [
    if (draft.delivery.asNotification) ..._visibleTextProblems(draft),
    ..._dataProblems(draft),
  ];

  /// A silent push shows nothing, so blank text is only a problem when FCM is
  /// being asked to display it.
  List<DraftProblem> _visibleTextProblems(NotificationDraft draft) => [
    if (draft.title.trim().isEmpty)
      const DraftProblem('title', 'must not be blank'),
    if (draft.body.trim().isEmpty)
      const DraftProblem('body', 'must not be blank'),
  ];

  List<DraftProblem> _dataProblems(NotificationDraft draft) {
    final problems = <DraftProblem>[];
    for (final key in draft.data.keys) {
      if (key.trim().isEmpty) {
        problems.add(const DraftProblem('data', 'a key must not be blank'));
      } else if (reservedDataKeys.contains(key)) {
        problems.add(
          DraftProblem('data', '"$key" is written by the sender, pick another'),
        );
      }
    }

    return problems;
  }
}
