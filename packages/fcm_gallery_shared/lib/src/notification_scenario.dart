import 'notification_delivery.dart';
import 'notification_draft.dart';
import 'notification_event.dart';
import 'notification_priority.dart';

/// A ready-made starting point for the sandbox editor.
///
/// A scenario is only a set of defaults: applying one replaces the form
/// contents, and everything stays editable afterwards. Nothing downstream
/// knows scenarios exist — the wire only ever carries a `NotificationDraft`.
class NotificationScenario {
  const NotificationScenario({
    required this.id,
    required this.label,
    required this.description,
    required this.draft,
  });

  /// Stable identifier, used as a widget key and in tests.
  final String id;

  /// Short name for the gallery chip.
  final String label;

  /// One line explaining what this scenario demonstrates.
  final String description;

  /// The values the editor starts from.
  final NotificationDraft draft;

  @override
  String toString() => 'NotificationScenario($id)';
}

/// The scenarios the sandbox offers.
///
/// Chosen to cover the axes that behave differently — visible versus silent,
/// high versus normal priority, with and without extra data keys — rather than
/// four variations on the same message. `notification_scenario_test.dart`
/// asserts the tour is complete.
const notificationGallery = <NotificationScenario>[
  NotificationScenario(
    id: 'chat-message',
    label: 'Chat message',
    description: 'High priority, visible, and carries a deep link.',
    draft: NotificationDraft(
      event: NotificationEvent.chatMessage,
      title: 'Ada replied',
      body: 'See you at the seminar.',
      data: {'deepLink': '/chats/7'},
    ),
  ),
  NotificationScenario(
    id: 'build-finished',
    label: 'Build finished',
    description: 'The payload shape documented in the root README.',
    draft: NotificationDraft(
      event: NotificationEvent.buildFinished,
      title: 'Build finished',
      body: 'Release 1.0.0 is ready.',
      data: {'deepLink': '/builds/42'},
      delivery: NotificationDelivery(priority: NotificationPriority.normal),
    ),
  ),
  NotificationScenario(
    id: 'promo',
    label: 'Promo',
    description: 'Normal priority — not everything deserves to be urgent.',
    draft: NotificationDraft(
      event: NotificationEvent.promo,
      title: 'Half price this week',
      body: 'Every seminar, until Sunday.',
      data: {'campaign': 'summer-2026'},
      delivery: NotificationDelivery(priority: NotificationPriority.normal),
    ),
  ),
  NotificationScenario(
    id: 'silent-sync',
    label: 'Silent sync',
    description: 'Data only: nothing is shown, the app is woken instead.',
    draft: NotificationDraft(
      event: NotificationEvent.silentSync,
      title: 'Sync requested',
      body: 'The device should refresh its cache.',
      delivery: NotificationDelivery(asNotification: false),
    ),
  ),
];
