import 'notification_draft.dart';

/// A gallery preset: a named draft the Sandbox can load with one tap.
///
/// Loading a scenario replaces the form's contents; everything stays editable
/// afterwards, so a preset is a starting point rather than a fixed payload.
class NotificationScenario {
  const NotificationScenario({
    required this.id,
    required this.label,
    required this.description,
    required this.draft,
  });

  /// Stable identifier, used as a widget key and in tests.
  final String id;

  /// Shown on the chip.
  final String label;

  /// One line explaining what makes this preset different from the others.
  final String description;

  /// The draft loaded into the form.
  final NotificationDraft draft;
}

/// The presets the Sandbox offers.
///
/// They cover different axes rather than four flavours of the same thing: a
/// routing key the app would act on, the payload from the root README, two
/// unrelated extra keys, and no extra data at all.
const notificationGallery = <NotificationScenario>[
  NotificationScenario(
    id: 'chatMessage',
    label: 'Chat message',
    description: 'Carries a deep link the app would route on.',
    draft: NotificationDraft(
      title: 'Ada: are we still on for 14:00?',
      body: 'Tap to open the thread.',
      data: {'event': 'chat_message', 'deepLink': '/chats/ada'},
    ),
  ),
  NotificationScenario(
    id: 'buildFinished',
    label: 'Build finished',
    description: 'The payload the root README documents.',
    draft: NotificationDraft(
      title: 'Build finished',
      body: 'Release 1.0.0 is ready.',
      data: {'event': 'build_finished', 'buildNumber': '128'},
    ),
  ),
  NotificationScenario(
    id: 'promo',
    label: 'Promo',
    description: 'Two unrelated extra keys at once.',
    draft: NotificationDraft(
      title: '20% off this week',
      body: 'Your upgrade is discounted until Sunday.',
      data: {'event': 'promo', 'campaign': 'summer-2026'},
    ),
  ),
  NotificationScenario(
    id: 'plainText',
    label: 'Plain text',
    description: 'No extra data — exercises the empty-map path.',
    draft: NotificationDraft(
      title: 'Hello from the Sandbox',
      body: 'Nothing but a title and a body.',
    ),
  ),
];
