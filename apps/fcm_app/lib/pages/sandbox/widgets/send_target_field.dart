import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/cubit/cubit.dart';
import 'package:fcm_app/pages/sandbox/widgets/all_devices_note.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Chooses who a send goes to: one dropdown and one text field, because the kinds
/// are mutually exclusive and a form that lets two be filled at once invites the
/// "only one delivery target is allowed" error [SendTarget.readFrom] rejects.
///
/// Stateful, and it owns the text field's controller, because the target is also
/// set from outside — applying a scenario writes one while this page stays mounted
/// in the shell's `IndexedStack`. A [TextFormField] seeded with `initialValue`
/// would keep showing whatever was typed before, so the box would name one
/// audience while the send went to another.
class SendTargetField extends StatefulWidget {
  const SendTargetField({super.key});

  @override
  State<SendTargetField> createState() => _SendTargetFieldState();
}

class _SendTargetFieldState extends State<SendTargetField> {
  final TextEditingController _value = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value.text = _valueOf(context.read<SandboxCubit>().state.target);
  }

  @override
  void dispose() {
    _value.dispose();
    super.dispose();
  }

  /// A consumer rather than a builder, because a target set from elsewhere has to
  /// reach the text box as well as the dropdown, and writing into a
  /// [TextEditingController] is a side effect. The listener runs before the
  /// builder, so the box and the dropdown never disagree within a frame.
  @override
  Widget build(
    BuildContext context,
  ) => BlocConsumer<SandboxCubit, SandboxState>(
    listener: (_, state) => _readTarget(state),
    builder: (context, state) {
      final t = context.t;
      final kind = _kindOf(t, state.target);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            // Unkeyed: this one *does* follow `initialValue` across rebuilds —
            // `_DropdownButtonFormFieldState.didUpdateWidget` calls `setValue`
            // when it changes — so a target set from a scenario reselects it.
            initialValue: kind,
            decoration: InputDecoration(labelText: t.send_target.label),
            items: [
              for (final offered in _kinds(t))
                DropdownMenuItem(value: offered, child: Text(offered)),
            ],
            onChanged: (chosen) =>
                context.read<SandboxCubit>().setTarget(_emptyFor(t, chosen)),
          ),
          if (_takesText(t, kind))
            TextField(
              controller: _value,
              decoration: InputDecoration(labelText: kind.toLowerCase()),
              onChanged: (text) => context.read<SandboxCubit>().setTarget(
                _withValue(t, kind, text),
              ),
            ),
          if (kind == t.send_target.all_devices) const AllDevicesNote(),
        ],
      );
    },
  );

  void _readTarget(SandboxState state) {
    final value = _valueOf(state.target);
    // Assigning unconditionally would fight the keystroke that caused this
    // notification, so only a target set from elsewhere is taken.
    if (value != _value.text) {
      _value.text = value;
    }
  }
}

/// The dropdown's choices, in the order offered — this device first, because it
/// is both the default and the only one that works without setup.
///
/// A `List<String>` built fresh from [t] rather than a top-level `const`: a
/// localized string cannot be `const`, and the choices have to follow whichever
/// language is current.
List<String> _kinds(Translations t) => [
  t.send_target.this_device,
  t.send_target.token,
  t.send_target.topic,
  t.send_target.condition,
  t.send_target.all_devices,
];

String _kindOf(Translations t, SendTarget? target) => switch (target) {
  null => t.send_target.this_device,
  TokenTarget() => t.send_target.token,
  TopicTarget() => t.send_target.topic,
  ConditionTarget() => t.send_target.condition,
  AllDevicesTarget() => t.send_target.all_devices,
};

/// What [target] carries, or empty for the kinds that carry nothing.
String _valueOf(SendTarget? target) => switch (target) {
  TokenTarget(:final token) => token,
  TopicTarget(:final topic) => topic,
  ConditionTarget(:final condition) => condition,
  null || AllDevicesTarget() => '',
};

bool _takesText(Translations t, String kind) =>
    kind == t.send_target.token ||
    kind == t.send_target.topic ||
    kind == t.send_target.condition;

/// The target for a freshly chosen [kind], deliberately blank rather than
/// pre-filled: the cubit blocks Send while it is, which is better than guessing an
/// audience on the user's behalf.
///
/// [kind] is compared against the current translations rather than a `const`
/// pattern, so the comparison has to be a `when` guard rather than a constant
/// case: a localized label is not a compile-time constant.
SendTarget? _emptyFor(Translations t, String? kind) => switch (kind) {
  final value when value == t.send_target.token => const TokenTarget(''),
  final value when value == t.send_target.topic => const TopicTarget(''),
  final value when value == t.send_target.condition => const ConditionTarget(
    '',
  ),
  final value when value == t.send_target.all_devices =>
    const AllDevicesTarget(),
  _ => null,
};

SendTarget _withValue(Translations t, String kind, String text) =>
    switch (kind) {
      final value when value == t.send_target.token => TokenTarget(text),
      final value when value == t.send_target.topic => TopicTarget(text),
      _ => ConditionTarget(text),
    };
