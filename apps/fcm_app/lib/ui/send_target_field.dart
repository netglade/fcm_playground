import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';

/// Chooses who a send goes to.
///
/// One dropdown and one text field rather than four separate inputs: the kinds
/// are mutually exclusive, and a form that lets two be filled at once invites
/// exactly the "only one delivery target is allowed" error that
/// [SendTarget.readFrom] exists to reject. *This device* and *All devices* need
/// nothing typed, so the field is hidden for them rather than disabled — a box
/// you cannot use is worse than no box.
///
/// Stateful, and it owns the text field's controller, because the target is
/// also set from outside: applying a scenario writes one, and the page stays
/// mounted in the shell's `IndexedStack` while the gallery does it. A
/// [TextFormField] seeded with `initialValue` would keep showing whatever was
/// typed before, so the box would name one audience while the send went to
/// another.
class SendTargetField extends StatefulWidget {
  /// Reads and sets [controller]'s target.
  const SendTargetField({required this.controller, super.key});

  /// The controller whose target this chooses.
  final SandboxController controller;

  @override
  State<SendTargetField> createState() => _SendTargetFieldState();
}

class _SendTargetFieldState extends State<SendTargetField> {
  final TextEditingController _value = TextEditingController();

  @override
  void initState() {
    super.initState();
    _value.text = _valueOf(widget.controller.target);
    widget.controller.addListener(_readTarget);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_readTarget);
    _value.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kind = _kindOf(widget.controller.target);

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
          onChanged: (chosen) => widget.controller.setTarget(_emptyFor(chosen)),
        ),
        if (_takesText(kind))
          TextField(
            controller: _value,
            decoration: InputDecoration(labelText: kind.toLowerCase()),
            onChanged: (text) =>
                widget.controller.setTarget(_withValue(kind, text)),
          ),
        if (kind == _allDevices) _allDevicesNote,
      ],
    );
  }

  void _readTarget() => setState(() {
    final value = _valueOf(widget.controller.target);
    // Assigning unconditionally would fight the keystroke that caused this
    // notification, so only a target set from elsewhere is taken.
    if (value != _value.text) {
      _value.text = value;
    }
  });
}

const String _thisDevice = 'This device';
const String _token = 'Token';
const String _topic = 'Topic';
const String _condition = 'Condition';
const String _allDevices = 'All devices';

/// Every audience the dropdown offers, this device first because it is both the
/// default and the only one that works without setup.
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

/// Which kind [target] is, as the dropdown spells it.
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

/// Whether [kind] needs something typed.
bool _takesText(String kind) =>
    kind == _token || kind == _topic || kind == _condition;

/// The target for a freshly chosen [kind], before anything is typed.
///
/// Deliberately blank rather than pre-filled: the controller blocks Send while
/// it is, which is better than guessing an audience on the user's behalf.
SendTarget? _emptyFor(String? kind) => switch (kind) {
  _token => const TokenTarget(''),
  _topic => const TopicTarget(''),
  _condition => const ConditionTarget(''),
  _allDevices => const AllDevicesTarget(),
  _ => null,
};

/// [kind]'s target carrying [text].
SendTarget _withValue(String kind, String text) => switch (kind) {
  _token => TokenTarget(text),
  _topic => TopicTarget(text),
  _ => ConditionTarget(text),
};
