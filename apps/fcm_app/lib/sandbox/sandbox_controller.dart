import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import 'notification_send_exception.dart';
import 'notification_sender.dart';
import 'sandbox_send_state.dart';

/// Holds what the Sandbox form contains and what became of the last send.
///
/// It asks for a token through a callback rather than holding a `PushInbox`, so
/// the Sandbox knows nothing about the receiving side, and it holds no
/// `TextEditingController` — that is view state, and keeping it out is what lets
/// these rules be tested without pumping a widget.
class SandboxController extends ChangeNotifier {
  SandboxController({required this._sender, required this._token}) {
    // Opening on a preset means the page is sendable on arrival, and it makes
    // the gallery's purpose obvious without a tap.
    _load(notificationGallery.first.draft);
  }

  static const _validator = NotificationDraftValidator();

  final NotificationSender _sender;
  final String? Function() _token;

  String _title = '';
  String _body = '';
  List<MapEntry<String, String>> _entries = const [];
  List<DraftProblem> _problems = const [];
  SandboxSendState _state = const SandboxIdle();
  int _scenarioRevision = 0;

  /// The notification title as currently typed.
  String get title => _title;

  /// The notification body as currently typed.
  String get body => _body;

  /// The data rows, still a list so a key typed twice is visible.
  List<MapEntry<String, String>> get entries => List.unmodifiable(_entries);

  /// What is wrong with the form right now. Empty when it can be sent.
  List<DraftProblem> get problems => _problems;

  /// Where the last send got to.
  SandboxSendState get state => _state;

  /// Bumped every time a scenario is loaded, so the view can rebuild its text
  /// fields from the new values without fighting the user's cursor.
  int get scenarioRevision => _scenarioRevision;

  /// The form as a draft, with duplicate keys collapsed — only ever read once
  /// [problems] is empty, which is where duplicates are caught.
  NotificationDraft get draft => NotificationDraft(
    title: _title,
    body: _body,
    data: Map.fromEntries(_entries),
  );

  /// Why Send cannot be pressed, or null when it can.
  String? get sendBlockedReason {
    if (_token() == null) {
      return 'No registration token yet, so there is nowhere to send.';
    }
    if (_state is SandboxSending) {
      return 'Sending…';
    }
    if (_problems.isNotEmpty) {
      return 'Fix the problems above first.';
    }

    return null;
  }

  /// Whether Send can be pressed right now.
  bool get canSend => sendBlockedReason == null;

  /// Replaces the whole form with a preset.
  void applyScenario(NotificationScenario scenario) {
    _scenarioRevision++;
    _load(scenario.draft);
  }

  /// Applies an edit from the form. Anything omitted is left alone.
  void edit({
    String? title,
    String? body,
    List<MapEntry<String, String>>? entries,
  }) {
    _title = title ?? _title;
    _body = body ?? _body;
    _entries = entries ?? _entries;
    // An edit invalidates the previous result: a stale "✓ Sent" next to changed
    // fields would claim something untrue.
    _state = const SandboxIdle();
    _revalidate();
    notifyListeners();
  }

  /// Sends the current draft to this device.
  Future<void> send() async {
    final token = _token();
    if (token == null) {
      _state = const SandboxFailed(
        'No registration token yet — push is unavailable on this device.',
      );
      notifyListeners();

      return;
    }

    _revalidate();
    if (_problems.isNotEmpty) {
      notifyListeners();

      return;
    }

    _state = const SandboxSending();
    notifyListeners();

    try {
      final response = await _sender.send(
        SendNotificationRequest(token: token, draft: draft),
      );
      _state = SandboxSent(response);
    } on NotificationSendException catch (error) {
      _state = SandboxFailed(error.message);
    }
    notifyListeners();
  }

  void _load(NotificationDraft draft) {
    _title = draft.title;
    _body = draft.body;
    _entries = draft.data.entries.toList();
    _state = const SandboxIdle();
    _revalidate();
    notifyListeners();
  }

  void _revalidate() {
    _problems = _validator.validateEntries(
      title: _title,
      body: _body,
      data: _entries,
    );
  }
}
