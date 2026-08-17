import 'package:fcm_app/pages/sandbox/cubit/sandbox_send_state.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final first = scenarioGallery.first;
  final second = scenarioGallery[1];

  // The two booleans hold *different* values: a copyWith that read one of them from
  // the other would round-trip perfectly against a base where both were true.
  final base = SandboxState(
    validateOnly: true,
    selectedScenario: first,
    target: const TopicTarget('news'),
    sendState: const SandboxFailed('nope'),
    isFormValid: false,
  );

  void expectOnly(
    SandboxState changed, {
    bool? validateOnly,
    Object? selectedScenario = 'same',
    Object? target = 'same',
    SandboxSendState? sendState,
    bool? isFormValid,
  }) {
    expect(changed.validateOnly, validateOnly ?? base.validateOnly);
    expect(
      changed.selectedScenario,
      selectedScenario == 'same' ? base.selectedScenario : selectedScenario,
    );
    expect(changed.target, target == 'same' ? base.target : target);
    expect(changed.sendState, sendState ?? base.sendState);
    expect(changed.isFormValid, isFormValid ?? base.isFormValid);
  }

  group('SandboxState', () {
    test('defaults to the page before a scenario is applied', () {
      const state = SandboxState();

      expect(state.validateOnly, isFalse);
      expect(state.selectedScenario, isNull);
      expect(state.target, isNull);
      expect(state.sendState, isA<SandboxIdle>());
      expect(state.isFormValid, isFalse);
    });

    test('copyWith with nothing given changes nothing', () {
      expectOnly(base.copyWith());
    });

    test('copyWith changes validateOnly and only validateOnly', () {
      // Read from isFormValid instead and this would come back false while
      // every other field still matched.
      expectOnly(base.copyWith(validateOnly: false), validateOnly: false);
    });

    test('copyWith changes isFormValid and only isFormValid', () {
      expectOnly(base.copyWith(isFormValid: true), isFormValid: true);
    });

    test('copyWith changes selectedScenario and only selectedScenario', () {
      expectOnly(
        base.copyWith(selectedScenario: second),
        selectedScenario: second,
      );
    });

    test('copyWith changes target and only target', () {
      expectOnly(
        base.copyWith(target: const ConditionTarget('x')),
        target: const ConditionTarget('x'),
      );
    });

    test('copyWith changes sendState and only sendState', () {
      expectOnly(
        base.copyWith(sendState: const SandboxSending()),
        sendState: const SandboxSending(),
      );
    });

    test('copyWith clears the target, because applying a scenario must', () {
      // Null has to mean "clear" rather than "leave alone", or a target the previous
      // scenario chose would silently broadcast the next one.
      expectOnly(base.copyWith(target: null), target: null);
    });

    test('copyWith clears the selected scenario', () {
      expectOnly(base.copyWith(selectedScenario: null), selectedScenario: null);
    });

    test('copyWith always returns a state Cubit.emit will publish', () {
      // Load-bearing: the cubit republishes every form change as a state, and an
      // edit usually leaves all five scalars alone. `Cubit.emit` drops a state equal
      // to the current one, so value equality here would stop those edits reaching
      // the form controls.
      final copy = base.copyWith();

      expect(copy, isNot(same(base)));
      expect(copy == base, isFalse);
    });
  });
}
