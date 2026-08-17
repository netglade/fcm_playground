import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

import 'sandbox_send_state.dart';

/// Sentinel for "this field was not passed", so that passing null to
/// [SandboxState.copyWith] clears a nullable field instead of keeping it.
const Object _unchanged = Object();

/// Everything the Sandbox page reads apart from the payload itself.
///
/// Scalars only. `FcmMessageForm` is deliberately not here: it is mutable and
/// identity-stable, so every state built from the previous one would carry the
/// very same instance. [isFormValid] is stored rather than read from the live
/// form, because a getter tells a `BlocBuilder` nothing.
///
/// Deliberately not value-equal. `SandboxCubit` republishes every model in the
/// form tree, and most edits change none of these scalars; `Cubit.emit` drops a
/// state equal to the current one, so value equality would swallow exactly those
/// notifications and the checkbox the user just tapped would not move.
class SandboxState {
  const SandboxState({
    this.validateOnly = false,
    this.selectedScenario,
    this.target,
    this.sendState = const SandboxIdle(),
    this.isFormValid = false,
  });

  final bool validateOnly;

  final Scenario? selectedScenario;

  /// Who to send to, or null for this device — null rather than a resolved
  /// [TokenTarget], because the device's token can change under us.
  final SendTarget? target;

  final SandboxSendState sendState;

  /// Whether every input in the form tree is valid, as of the last change.
  final bool isFormValid;

  /// This state with the given fields replaced.
  ///
  /// [selectedScenario] and [target] are typed `Object?` against a sentinel so
  /// that passing null *clears* them, which `applyScenario` needs: a target left
  /// behind by the previous scenario would silently broadcast the next one.
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
