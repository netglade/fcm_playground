import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/sandbox_cubit.dart';
import '../cubit/sandbox_state.dart';

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
      final kind = _kindOf(state.target);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            // Unkeyed: this one *does* follow `initialValue` across rebuilds —
            // `_DropdownButtonFormFieldState.didUpdateWidget` calls `setValue`
            // when it changes — so a target set from a scenario reselects it.
            initialValue: kind,
            decoration: const InputDecoration(labelText: 'Send to'),
            items: [
              for (final offered in _kinds)
                DropdownMenuItem(value: offered, child: Text(offered)),
            ],
            onChanged: (chosen) =>
                context.read<SandboxCubit>().setTarget(_emptyFor(chosen)),
          ),
          if (_takesText(kind))
            TextField(
              controller: _value,
              decoration: InputDecoration(labelText: kind.toLowerCase()),
              onChanged: (text) => context.read<SandboxCubit>().setTarget(
                _withValue(kind, text),
              ),
            ),
          if (kind == _allDevices) _allDevicesNote,
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

const String _thisDevice = 'This device';
const String _token = 'Token';
const String _topic = 'Topic';
const String _condition = 'Condition';
const String _allDevices = 'All devices';

/// This device first: it is both the default and the only one that works without
/// setup.
const List<String> _kinds = [
  _thisDevice,
  _token,
  _topic,
  _condition,
  _allDevices,
];

const Widget _allDevicesNote = Padding(
  padding: EdgeInsets.only(top: 8),
  child: Text(
    'Sending to every device needs a token registry the API does not have yet, '
    'so this will be refused.',
  ),
);

String _kindOf(SendTarget? target) => switch (target) {
  null => _thisDevice,
  TokenTarget() => _token,
  TopicTarget() => _topic,
  ConditionTarget() => _condition,
  AllDevicesTarget() => _allDevices,
};

/// What [target] carries, or empty for the kinds that carry nothing.
String _valueOf(SendTarget? target) => switch (target) {
  TokenTarget(:final token) => token,
  TopicTarget(:final topic) => topic,
  ConditionTarget(:final condition) => condition,
  null || AllDevicesTarget() => '',
};

bool _takesText(String kind) =>
    kind == _token || kind == _topic || kind == _condition;

/// The target for a freshly chosen [kind], deliberately blank rather than
/// pre-filled: the cubit blocks Send while it is, which is better than guessing an
/// audience on the user's behalf.
SendTarget? _emptyFor(String? kind) => switch (kind) {
  _token => const TokenTarget(''),
  _topic => const TopicTarget(''),
  _condition => const ConditionTarget(''),
  _allDevices => const AllDevicesTarget(),
  _ => null,
};

SendTarget _withValue(String kind, String text) => switch (kind) {
  _token => TokenTarget(text),
  _topic => TopicTarget(text),
  _ => ConditionTarget(text),
};
