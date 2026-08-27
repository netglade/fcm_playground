import 'package:fcm_app/domains/runs/runs.dart';
import 'package:fcm_app/domains/sandbox/sandbox.dart';
import 'package:fcm_app/domains/telemetry/telemetry.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_send_state.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_state.dart';
import 'package:fcm_app/pages/sandbox/forms/forms.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the Sandbox's payload [form] and what became of the last send.
///
/// Republishes every model in the form tree as its own state, so one cubit serves
/// the page while a change four levels down still reaches the screen — a nested
/// `GladeModel`'s notification does not travel up to its parent.
///
/// The token arrives through a callback, so this page reads it without tying its
/// lifetime to another page's cubit.
class SandboxCubit extends Cubit<SandboxState> {
  SandboxCubit({
    required this._sender,
    required this._token,
    required this._startRun,
    this._telemetry = const SilentPushTelemetry(),
  }) : super(const SandboxState()) {
    for (final model in _form.allModels) {
      model.addListener(_onFormChanged);
    }
    applyScenario(scenarioGallery.first);
  }

  final NotificationSender _sender;
  final String? Function() _token;
  final StartRun _startRun;
  final PushTelemetry _telemetry;
  final FcmMessageForm _form = FcmMessageForm();

  /// The message being composed, edited directly by the page's sections.
  ///
  /// Outside [SandboxState] on purpose: mutable and identity-stable, so a state
  /// holding it could never tell two payloads apart.
  FcmMessageForm get form => _form;

  /// Why Send cannot be pressed, or null when it can.
  ///
  /// Reads the global `t` — this cubit has no `BuildContext`. `send_footer.dart`
  /// still follows a locale change, because it rereads this from inside its own
  /// `context.t`-watching build.
  String? get sendBlockedReason {
    if (_isTargetBlank) {
      return t.sandbox.send_blocked.no_target;
    }
    // Only a send to *this device* needs this device's token — a topic,
    // condition or explicit token names its own audience.
    if (state.target == null && _token() == null) {
      return t.sandbox.send_blocked.no_token;
    }
    if (state.sendState is SandboxSending) {
      return t.sandbox.send_blocked.sending;
    }
    // An invalid field can hide behind a closed section, so say where to
    // look.
    if (!state.isFormValid) {
      return t.sandbox.send_blocked.invalid_field;
    }

    return null;
  }

  bool get canSend => sendBlockedReason == null;

  /// This device's registration token, or null before one exists.
  ///
  /// Exposed because the gallery's batch sends to the same token, and both pages
  /// share this cubit.
  String? get deviceToken => _token();

  void setValidateOnly(bool value) => emit(state.copyWith(validateOnly: value));

  void setTarget(SendTarget? target) => emit(state.copyWith(target: target));

  /// Replaces every field in [form] with [scenario]'s template.
  ///
  /// Replaces, not merges: `readFrom` also clears the fields the template leaves
  /// out, so switching scenarios cannot strand the previous one's notification.
  void applyScenario(Scenario scenario) {
    _form.readFrom(FcmMessage.fromJson(scenario.payloadTemplate));
    emit(
      state.copyWith(
        selectedScenario: scenario,
        // Including back to null — the previous scenario's target would
        // silently broadcast the next one.
        target: scenario.target,
        isFormValid: _form.isValid,
      ),
    );
  }

  Future<void> send() async {
    final token = _token();
    // Resolved here rather than at choice time, because this device's token can
    // change under us.
    final target = state.target ?? (token == null ? null : TokenTarget(token));
    if (target == null || !canSend) {
      return;
    }

    // Before the await: what is reported as sent must be what left, not
    // whatever the form holds when the response lands.
    final message = _form.toModel();
    emit(state.copyWith(sendState: const SandboxSending()));

    try {
      final response = await _sender.send(
        SendMessageRequest(
          target: target,
          message: message,
          validateOnly: state.validateOnly,
          // The payload does not identify its scenario, so without this the
          // matrix loses that axis.
          scenarioId: state.selectedScenario?.id,
        ),
      );
      emit(state.copyWith(sendState: SandboxSent(response)));
    } on NotificationSendException catch (error) {
      emit(state.copyWith(sendState: SandboxFailed(error.message)));
    }
  }

  /// Schedules the composed payload as a run of one, [delaySeconds] from now.
  ///
  /// Answers the run so the caller can open a countdown, or null when there was
  /// nothing to schedule or the API refused — the state says which.
  Future<ScheduledRun?> schedule(int delaySeconds) async {
    final token = _token();
    final target = state.target ?? (token == null ? null : TokenTarget(token));
    if (target == null || !canSend) {
      return null;
    }

    // Before the await, as `send` does: schedule what the form held at the
    // press.
    final request = SendMessageRequest(
      target: target,
      message: _form.toModel(),
      validateOnly: state.validateOnly,
      scenarioId: state.selectedScenario?.id,
    );
    emit(state.copyWith(sendState: const SandboxSending()));

    try {
      final run = await _startRun(
        ScheduleRunRequest(delaySeconds: delaySeconds, items: [request]),
      );
      emit(state.copyWith(sendState: SandboxScheduled(run)));

      return run;
    } on RunSchedulerException catch (error) {
      emit(state.copyWith(sendState: SandboxFailed(error.message)));

      return null;
    }
  }

  /// Records that the user says the push for [traceId] never arrived, and
  /// flushes at once — this is a foreground action they just took.
  ///
  /// Reports nothing about success: `record` never throws, and a failed `flush`
  /// keeps the event buffered for the next one.
  Future<void> reportNotReceived(String traceId) async {
    try {
      await _telemetry.record(
        TelemetryEventType.notReceived,
        traceId: traceId,
        scenarioId: state.selectedScenario?.id,
      );
      await _telemetry.flush();
    } on Object catch (error) {
      // Telemetry must never break what it observes — an escaping error here
      // is an unhandled async error on the send screen.
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

  /// Whether a target was chosen but its value is still missing — a normal
  /// state, since the kind is picked before the value is typed. The line is at
  /// `trim()`, where `readFrom` draws it.
  bool get _isTargetBlank => switch (state.target) {
    TokenTarget(:final token) => token.trim().isEmpty,
    TopicTarget(:final topic) => topic.trim().isEmpty,
    ConditionTarget(:final condition) => condition.trim().isEmpty,
    null || AllDevicesTarget() => false,
  };

  void _onFormChanged() {
    final sendState = state.sendState;

    // An edit invalidates the previous result — a stale "✓ Sent" beside a
    // changed payload claims something untrue. A send in flight is left alone,
    // or editing while waiting would re-enable Send.
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
