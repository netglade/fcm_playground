import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import 'forms/fcm_message_form.dart';
import 'notification_send_exception.dart';
import 'notification_sender.dart';
import 'sandbox_send_state.dart';

/// Holds the Sandbox's payload [form] and what became of the last send.
///
/// The form is the payload: there is no text to parse and nothing to keep in
/// sync, so a field can only ever hold something the typed model accepts and
/// "is this sendable?" is the form's own [FcmMessageForm.isValid]. It asks for a
/// token through a callback rather than holding a `PushInbox`, so the Sandbox
/// knows nothing about the receiving side.
///
/// It republishes every model in the form tree as its own notifications, so the
/// page above needs one listenable while a change four levels down still
/// reaches the screen. That indirection is necessary because the form controls
/// are stateless readers of `input.value` and a nested `GladeModel`'s
/// notification does not travel up to its parent.
class SandboxController extends ChangeNotifier {
  /// Creates a controller wired to a sender and a way to read the current
  /// registration token.
  SandboxController({required this._sender, required this._token}) {
    for (final model in _form.allModels) {
      model.addListener(_onFormChanged);
    }
    // Opening on a preset means the page is sendable on arrival, and it makes
    // the gallery's purpose obvious without a tap.
    applyScenario(scenarioGallery.first);
  }

  final NotificationSender _sender;
  final String? Function() _token;
  final FcmMessageForm _form = FcmMessageForm();

  bool _validateOnly = false;
  Scenario? _selectedScenario;
  SandboxSendState _state = const SandboxIdle();

  /// The message being composed, edited directly by the page's sections.
  FcmMessageForm get form => _form;

  /// Whether a send should only validate the request rather than deliver it.
  bool get validateOnly => _validateOnly;

  /// The scenario last applied to the form, so the page can show which preset
  /// the current payload started from.
  Scenario? get selectedScenario => _selectedScenario;

  /// Where the last send got to.
  SandboxSendState get state => _state;

  /// Why Send cannot be pressed, or null when it can.
  String? get sendBlockedReason {
    if (_token() == null) {
      return 'No registration token yet, so there is nowhere to send.';
    }
    if (_state is SandboxSending) {
      return 'Sending…';
    }
    // An invalid field can sit behind a closed section, so this has to point at
    // where to look rather than just state that something is wrong.
    if (_form.isNotValid) {
      return 'A field is invalid. The sections marked with an error icon say '
          'which.';
    }

    return null;
  }

  /// Whether Send can be pressed right now.
  bool get canSend => sendBlockedReason == null;

  /// Sets whether a send should only validate the request.
  void setValidateOnly(bool value) {
    _validateOnly = value;
    notifyListeners();
  }

  /// Replaces every field in [form] with [scenario]'s template.
  ///
  /// Replaces rather than merges: `readFrom` writes all of the template's
  /// fields *and* clears the ones it leaves out, so switching scenarios cannot
  /// leave the previous one's notification behind.
  void applyScenario(Scenario scenario) {
    _selectedScenario = scenario;
    _form.readFrom(FcmMessage.fromJson(scenario.payloadTemplate));
    notifyListeners();
  }

  /// Sends the form's message to this device, using the current [validateOnly]
  /// flag.
  Future<void> send() async {
    final token = _token();
    if (token == null || _form.isNotValid || _state is SandboxSending) {
      return;
    }

    // Read before the await: what gets reported as sent must be what left, not
    // whatever the form holds by the time the response lands.
    final message = _form.toModel();
    _state = const SandboxSending();
    notifyListeners();

    try {
      final response = await _sender.send(
        SendMessageRequest(
          token: token,
          message: message,
          validateOnly: _validateOnly,
        ),
      );
      _state = SandboxSent(response);
    } on NotificationSendException catch (error) {
      _state = SandboxFailed(error.message);
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final model in _form.allModels) {
      model.removeListener(_onFormChanged);
    }
    super.dispose();
  }

  void _onFormChanged() {
    // An edit invalidates the previous result: a stale "✓ Sent" beside a changed
    // payload would claim something untrue. A send in flight is left alone, or
    // an edit made while waiting would re-enable Send and allow a second one.
    if (_state is! SandboxSending) {
      _state = const SandboxIdle();
    }
    notifyListeners();
  }
}
