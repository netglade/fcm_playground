import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../telemetry/push_telemetry.dart';
import '../telemetry/silent_push_telemetry.dart';
import 'forms/fcm_message_form.dart';
import 'notification_send_exception.dart';
import 'notification_sender.dart';
import 'sandbox_send_state.dart';
import 'sandbox_state.dart';

/// Holds the Sandbox's payload [form] and what became of the last send.
///
/// The form is the payload: there is no text to parse and nothing to keep in
/// sync, so a field can only ever hold something the typed model accepts and
/// "is this sendable?" is the form's own [FcmMessageForm.isValid]. It asks for a
/// token through a callback rather than holding a `PushRepository`, so the
/// Sandbox knows nothing about the receiving side — and with one cubit per page
/// that matters more, not less: a callback is how this page reads the token
/// without reaching into another page's cubit and tying the two lifetimes
/// together.
///
/// It republishes every model in the form tree as a state of its own, so the
/// page above needs one cubit while a change four levels down still reaches the
/// screen. That indirection is necessary because the form controls are stateless
/// readers of `input.value` and a nested `GladeModel`'s notification does not
/// travel up to its parent.
///
/// Constructed by the widget that owns it, never fetched from a service locator:
/// a cubit in a locator outlives its page and carries the last page's state into
/// the next one. Nothing in here reads a locator, so a test can hand it plain
/// fakes.
class SandboxCubit extends Cubit<SandboxState> {
  /// Creates a cubit wired to a sender and a way to read the current
  /// registration token.
  ///
  /// [telemetry] defaults to silence, the same way every push hook does: a test
  /// about the payload form must not have to open a Drift database to get a
  /// cubit.
  SandboxCubit({
    required this._sender,
    required this._token,
    this._telemetry = const SilentPushTelemetry(),
  }) : super(const SandboxState()) {
    for (final model in _form.allModels) {
      model.addListener(_onFormChanged);
    }
    // Opening on a preset means the page is sendable on arrival, and it makes
    // the gallery's purpose obvious without a tap.
    applyScenario(scenarioGallery.first);
  }

  final NotificationSender _sender;
  final String? Function() _token;
  final PushTelemetry _telemetry;
  final FcmMessageForm _form = FcmMessageForm();

  /// The message being composed, edited directly by the page's sections.
  ///
  /// Outside [SandboxState] on purpose: it is mutable and identity-stable, so a
  /// state holding it could never tell two payloads apart.
  FcmMessageForm get form => _form;

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
    if (state.target == null && _token() == null) {
      return 'No registration token yet, so there is nowhere to send.';
    }
    if (state.sendState is SandboxSending) {
      return 'Sending…';
    }
    // An invalid field can sit behind a closed section, so this has to point at
    // where to look rather than just state that something is wrong.
    if (!state.isFormValid) {
      return 'A field is invalid. The sections marked with an error icon say '
          'which.';
    }

    return null;
  }

  /// Whether Send can be pressed right now.
  bool get canSend => sendBlockedReason == null;

  /// Sets whether a send should only validate the request.
  void setValidateOnly(bool value) => emit(state.copyWith(validateOnly: value));

  /// Chooses an audience, or null to go back to this device.
  void setTarget(SendTarget? target) => emit(state.copyWith(target: target));

  /// Replaces every field in [form] with [scenario]'s template.
  ///
  /// Replaces rather than merges: `readFrom` writes all of the template's
  /// fields *and* clears the ones it leaves out, so switching scenarios cannot
  /// leave the previous one's notification behind.
  void applyScenario(Scenario scenario) {
    _form.readFrom(FcmMessage.fromJson(scenario.payloadTemplate));
    emit(
      state.copyWith(
        selectedScenario: scenario,
        // Unconditionally, including back to null: a target the previous
        // scenario chose would silently broadcast the next one.
        target: scenario.target,
        isFormValid: _form.isValid,
      ),
    );
  }

  /// Sends the form's message to the chosen target, or to this device when none
  /// was chosen, using the current validate-only flag.
  Future<void> send() async {
    final token = _token();
    // Resolved here rather than at choice time, because this device's token can
    // change under us. A token is needed only to stand in for "this device" —
    // a chosen topic or condition names its own audience.
    final target = state.target ?? (token == null ? null : TokenTarget(token));
    // Refuses exactly what Send is disabled for, so calling this directly
    // cannot post a target the page would not let the user send.
    if (target == null || !canSend) {
      return;
    }

    // Read before the await: what gets reported as sent must be what left, not
    // whatever the form holds by the time the response lands.
    final message = _form.toModel();
    emit(state.copyWith(sendState: const SandboxSending()));

    try {
      final response = await _sender.send(
        SendMessageRequest(
          target: target,
          message: message,
          validateOnly: state.validateOnly,
          // Named so telemetry can group by scenario. The payload alone does not
          // identify which scenario produced it, so if the sender does not say,
          // nothing downstream can — and the matrix loses its scenario axis.
          scenarioId: state.selectedScenario?.id,
        ),
      );
      emit(state.copyWith(sendState: SandboxSent(response)));
    } on NotificationSendException catch (error) {
      emit(state.copyWith(sendState: SandboxFailed(error.message)));
    }
  }

  /// Records that the user says the push for [traceId] never arrived, and sends
  /// it straight away.
  ///
  /// Recorded *and* flushed, unlike the background arrival hook: this is a
  /// foreground action the user just took, and they are entitled to assume it has
  /// been reported rather than left in a buffer until the next push.
  ///
  /// It reports nothing about whether it worked, deliberately. `record` never
  /// throws, and a `flush` that cannot reach the API keeps the event buffered for
  /// the next one — so the honest answer to "did this reach the server?" is "not
  /// yet, and it will", which is not something to alarm the user with.
  Future<void> reportNotReceived(String traceId) async {
    try {
      await _telemetry.record(
        TelemetryEventType.notReceived,
        traceId: traceId,
        // The scenario that produced the send. Any change to the selection
        // rewrites the form, which clears the result the button hangs off, so the
        // selection cannot have moved on while this button exists.
        scenarioId: state.selectedScenario?.id,
      );
      await _telemetry.flush();
    } on Object catch (error) {
      // Telemetry must never break what it observes, and here that is the page
      // itself: an escaping error from a button's callback is an unhandled
      // asynchronous error on the send screen.
      debugPrint('telemetry: not_received for $traceId was not sent: $error');
    }
  }

  @override
  Future<void> close() {
    for (final model in _form.allModels) {
      model.removeListener(_onFormChanged);
    }

    return super.close();
  }

  /// Whether a target was chosen but its value is still missing.
  bool get _isTargetBlank => switch (state.target) {
    TokenTarget(:final token) => token.trim().isEmpty,
    TopicTarget(:final topic) => topic.trim().isEmpty,
    ConditionTarget(:final condition) => condition.trim().isEmpty,
    // Null is this device, and all-devices carries nothing to fill in.
    null || AllDevicesTarget() => false,
  };

  void _onFormChanged() {
    final sendState = state.sendState;

    // An edit invalidates the previous result: a stale "✓ Sent" beside a changed
    // payload would claim something untrue. A send in flight is left alone, or
    // an edit made while waiting would re-enable Send and allow a second one.
    emit(
      state.copyWith(
        isFormValid: _form.isValid,
        sendState: sendState is SandboxSending
            ? sendState
            : const SandboxIdle(),
      ),
    );
  }
}
