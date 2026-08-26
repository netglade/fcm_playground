import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domains/runs/run_scheduler_exception.dart';
import '../../../domains/runs/start_run.dart';
import '../../../domains/sandbox/notification_send_exception.dart';
import '../../../domains/sandbox/notification_sender.dart';
import '../../../domains/telemetry/silent_push_telemetry.dart';
import '../../../domains/telemetry/push_telemetry.dart';
import '../../../i18n/translations.g.dart';
import '../forms/fcm_message_form.dart';
import 'sandbox_send_state.dart';
import 'sandbox_state.dart';

/// Holds the Sandbox's payload [form] and what became of the last send.
///
/// It republishes every model in the form tree as a state of its own, so the page
/// above needs one cubit while a change four levels down still reaches the
/// screen: the form controls are stateless readers of `input.value`, and a nested
/// `GladeModel`'s notification does not travel up to its parent.
///
/// The token arrives through a callback rather than a held `PushRepository`, so
/// this page can read it without tying its lifetime to another page's cubit.
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
  /// Outside [SandboxState] on purpose: it is mutable and identity-stable, so a
  /// state holding it could never tell two payloads apart.
  FcmMessageForm get form => _form;

  /// Why Send cannot be pressed, or null when it can.
  ///
  /// Reads the global `t` rather than a `context.t` passed in: this cubit has no
  /// `BuildContext` of its own, the same reason the three `http_*` data sources
  /// read the global. `send_footer.dart` still rebuilds on a locale change
  /// because it rereads this getter from inside its own `context.t`-watching
  /// `build`, so the two stay in step even though only one of them holds a
  /// context.
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
    // An invalid field can sit behind a closed section, so this has to point at
    // where to look rather than just state that something is wrong.
    if (!state.isFormValid) {
      return t.sandbox.send_blocked.invalid_field;
    }

    return null;
  }

  bool get canSend => sendBlockedReason == null;

  /// This device's registration token, or null before one exists.
  ///
  /// Exposed because the gallery's batch needs the same token this page sends to,
  /// and both pages already share this cubit.
  String? get deviceToken => _token();

  void setValidateOnly(bool value) => emit(state.copyWith(validateOnly: value));

  void setTarget(SendTarget? target) => emit(state.copyWith(target: target));

  /// Replaces every field in [form] with [scenario]'s template.
  ///
  /// Replaces rather than merges: `readFrom` writes all of the template's fields
  /// *and* clears the ones it leaves out, so switching scenarios cannot leave the
  /// previous one's notification behind.
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

  Future<void> send() async {
    final token = _token();
    // Resolved here rather than at choice time, because this device's token can
    // change under us.
    final target = state.target ?? (token == null ? null : TokenTarget(token));
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
          // The payload alone does not identify which scenario produced it, so
          // without this the matrix loses its scenario axis.
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
  /// It answers the run so the caller can open a countdown on it, and null when
  /// there was nothing to schedule or the API refused — the state says which.
  Future<ScheduledRun?> schedule(int delaySeconds) async {
    final token = _token();
    final target = state.target ?? (token == null ? null : TokenTarget(token));
    if (target == null || !canSend) {
      return null;
    }

    // Read before the await, as `send` does: what gets scheduled must be what the
    // form held at the press, not whatever it holds when the response lands.
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
  /// flushes straight away — unlike the background arrival hook, this is a
  /// foreground action the user just took.
  ///
  /// Reports nothing about whether it worked: `record` never throws and a failed
  /// `flush` keeps the event buffered for the next one, so there is nothing to
  /// alarm the user with.
  Future<void> reportNotReceived(String traceId) async {
    try {
      await _telemetry.record(
        TelemetryEventType.notReceived,
        traceId: traceId,
        scenarioId: state.selectedScenario?.id,
      );
      await _telemetry.flush();
    } on Object catch (error) {
      // Telemetry must never break what it observes, and an escaping error from
      // a button's callback is an unhandled async error on the send screen.
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

  /// Whether a target was chosen but its value is still missing. A kind is
  /// chosen before its value is typed, so this is a normal state of the form —
  /// the line is drawn at `trim()`, where `readFrom` draws it.
  bool get _isTargetBlank => switch (state.target) {
    TokenTarget(:final token) => token.trim().isEmpty,
    TopicTarget(:final topic) => topic.trim().isEmpty,
    ConditionTarget(:final condition) => condition.trim().isEmpty,
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
