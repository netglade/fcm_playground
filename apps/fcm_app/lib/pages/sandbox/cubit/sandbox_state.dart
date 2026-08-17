import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'sandbox_send_state.dart';

/// Sentinel for "this field was not passed", so that passing null to
/// [SandboxState.copyWith] clears a nullable field instead of keeping it.
const Object _unchanged = Object();

/// Everything the Sandbox page reads apart from the payload itself.
///
/// Scalars only. `FcmMessageForm` is deliberately **not** here: it is mutable
/// and identity-stable, so every state built from the previous one would carry
/// the very same form instance and nothing about the payload could ever
/// distinguish two states. The form is exposed as `SandboxCubit.form` and the
/// sections bind to it directly.
///
/// [isFormValid] is a stored field rather than a getter reading the live form,
/// because a getter tells a `BlocBuilder` nothing: a field four levels down
/// turning invalid has to arrive as a *new state* or Send never notices.
///
/// **Deliberately not value-equal.** `SandboxCubit` republishes every model in
/// the form tree as a state of its own, and most edits change none of these
/// scalars — ticking `direct_boot_ok` leaves the send idle and the form valid.
/// `Cubit.emit` drops a state equal to the current one, so value equality here
/// would swallow exactly those notifications, and the form controls are
/// `StatelessWidget`s reading `input.value` that nothing else redraws: the
/// checkbox the user just tapped would not move. Identity equality reproduces
/// the `ChangeNotifier` this replaced — every [copyWith] is a new object, so
/// every edit reaches the screen.
class SandboxState {
  /// Creates a state. The defaults are the page before a scenario is applied:
  /// nothing selected, this device, nothing sent, and an empty form that has
  /// not been read yet.
  const SandboxState({
    this.validateOnly = false,
    this.selectedScenario,
    this.target,
    this.sendState = const SandboxIdle(),
    this.isFormValid = false,
  });

  /// Whether a send should only validate the request rather than deliver it.
  final bool validateOnly;

  /// The scenario last applied to the form, so the page can show which preset
  /// the current payload started from.
  final Scenario? selectedScenario;

  /// Who to send to, or null for this device.
  ///
  /// Null rather than a resolved [TokenTarget], because the device's token can
  /// change under us — it is read at send time, not when the choice is made.
  final SendTarget? target;

  /// Where the last send got to.
  final SandboxSendState sendState;

  /// Whether every input in the form tree is valid, as of the last change.
  final bool isFormValid;

  /// This state with the given fields replaced.
  ///
  /// [selectedScenario] and [target] are typed `Object?` against a sentinel so
  /// that passing null *clears* them. `applyScenario` needs that for the
  /// target: one left behind by the previous scenario would silently broadcast
  /// the next one.
  SandboxState copyWith({
    bool? validateOnly,
    Object? selectedScenario = _unchanged,
    Object? target = _unchanged,
    SandboxSendState? sendState,
    bool? isFormValid,
  }) => SandboxState(
    validateOnly: validateOnly ?? this.validateOnly,
    selectedScenario: identical(selectedScenario, _unchanged)
        ? this.selectedScenario
        : selectedScenario as Scenario?,
    target: identical(target, _unchanged) ? this.target : target as SendTarget?,
    sendState: sendState ?? this.sendState,
    isFormValid: isFormValid ?? this.isFormValid,
  );
}
