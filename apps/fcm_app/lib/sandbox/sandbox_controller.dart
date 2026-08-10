import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import 'notification_sender.dart';

/// Holds what the sandbox is about to send, and what happened last time.
///
/// Reads the registration token through a callback rather than holding a
/// `PushInbox`, so the sandbox depends on the one fact it needs instead of on
/// the whole inbox.
class SandboxController extends ChangeNotifier {
  // The named parameters must stay public (`sender`, `readToken`) while the
  // fields stay private, so an initializing formal — which requires both to
  // share one name — cannot express this constructor.
  SandboxController({
    required NotificationSender sender,
    required String? Function() readToken,
  }) : _sender = sender, // ignore: prefer_initializing_formals
       _readToken = readToken, // ignore: prefer_initializing_formals
       _draft = notificationGallery.first.draft;

  final NotificationSender _sender;
  final String? Function() _readToken;
  final _validator = const NotificationDraftValidator();

  NotificationDraft _draft;
  List<DraftProblem> _problems = const [];
  SendNotificationResponse? _lastResponse;
  String? _lastError;
  bool _sending = false;
  int _scenarioGeneration = 0;

  /// What will be sent.
  NotificationDraft get draft => _draft;

  /// Why [draft] cannot be sent, empty when it can.
  List<DraftProblem> get problems => List.unmodifiable(_problems);

  /// The last successful send, or `null` if there has not been one.
  SendNotificationResponse? get lastResponse => _lastResponse;

  /// Why the last send failed, or `null` if it did not.
  String? get lastError => _lastError;

  /// Whether a send is in flight.
  bool get isSending => _sending;

  /// This device's registration token, or `null` while there is none.
  String? get token => _readToken();

  /// Whether [send] would do anything.
  bool get canSend => !_sending && token != null && _problems.isEmpty;

  /// Increments only when a scenario is applied.
  ///
  /// The editor keys its text inputs on this, so applying a scenario reseeds
  /// them and typing does not.
  int get scenarioGeneration => _scenarioGeneration;

  /// Replaces the draft with [scenario]'s starting point.
  void applyScenario(NotificationScenario scenario) {
    _scenarioGeneration++;
    _setDraft(scenario.draft);
  }

  /// Records an edit from the form.
  void editDraft(NotificationDraft draft) => _setDraft(draft);

  /// Sends [draft] to this device, recording either the response or the error.
  ///
  /// Never throws: a failed send is a thing to display, not a crash.
  Future<void> send() async {
    final token = _readToken();
    if (!canSend || token == null) {
      return;
    }

    _sending = true;
    _lastError = null;
    notifyListeners();
    try {
      _lastResponse = await _sender.send(
        SendNotificationRequest(token: token, draft: _draft),
      );
    } catch (error) {
      _lastResponse = null;
      _lastError = '$error';
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  void _setDraft(NotificationDraft draft) {
    _draft = draft;
    _problems = _validator.validate(draft);
    notifyListeners();
  }
}
