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
  SendTarget? _target;
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

  /// Who to send to, or null for this device.
  ///
  /// Null rather than a resolved [TokenTarget], because the device's token can
  /// change under us — it is read at send time, not when the choice is made.
  SendTarget? get target => _target;

  /// Why Send cannot be pressed, or null when it can.
  String? get sendBlockedReason {
    // A kind is chosen before its value is typed, so a half-filled target is a
    // normal state of the form rather than a mistake — but sending it would
    // deliver to the wrong audience or fail at the API, and `readFrom` draws
    // the line at `trim()`, so this draws it in the same place.
    if (_isTargetBlank) {
      return 'Fill in the delivery target, or switch back to this device.';
    }
    // Only a send to *this device* needs this device's token. A topic, a
    // condition or an explicit token names its own audience, so requiring a
    // registration token for those would block the whole targeting feature on a
    // device that has not registered — including every scenario in group J.
    if (_target == null && _token() == null) {
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

  /// Chooses an audience, or null to go back to this device.
  void setTarget(SendTarget? target) {
    _target = target;
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
    // Unconditionally, including back to null: a target the previous scenario
    // chose would silently broadcast the next one.
    _target = scenario.target;
    notifyListeners();
  }

  /// Sends the form's message to the chosen [target], or to this device when
  /// none was chosen, using the current [validateOnly] flag.
  Future<void> send() async {
    final token = _token();
    // Resolved here rather than at choice time, because this device's token can
    // change under us. A token is needed only to stand in for "this device" —
    // a chosen topic or condition names its own audience.
    final target = _target ?? (token == null ? null : TokenTarget(token));
    // Refuses exactly what Send is disabled for, so calling this directly
    // cannot post a target the page would not let the user send.
    if (target == null || !canSend) {
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
          target: target,
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

  /// Whether a target was chosen but its value is still missing.
  bool get _isTargetBlank => switch (_target) {
    TokenTarget(:final token) => token.trim().isEmpty,
    TopicTarget(:final topic) => topic.trim().isEmpty,
    ConditionTarget(:final condition) => condition.trim().isEmpty,
    // Null is this device, and all-devices carries nothing to fill in.
    null || AllDevicesTarget() => false,
  };

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
