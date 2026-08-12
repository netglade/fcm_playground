import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';

/// The raw payload editor: the message JSON that will be sent as-is, plus the
/// validate-only switch.
///
/// It owns the [TextEditingController], because that is view state and the
/// controller must stay testable without a widget pump. Loading a scenario
/// changes [SandboxController.scenarioRevision], and the parent keys this
/// widget on that revision — so a scenario replaces the field by replacing
/// this `State`, while ordinary typing never disturbs the cursor.
class SandboxForm extends StatefulWidget {
  const SandboxForm({required this.controller, super.key});

  /// The controller this form reads its initial text from and pushes edits
  /// into.
  final SandboxController controller;

  @override
  State<SandboxForm> createState() => _SandboxFormState();
}

class _SandboxFormState extends State<SandboxForm> {
  late final TextEditingController _payload;

  @override
  void initState() {
    super.initState();
    _payload = TextEditingController(text: widget.controller.payloadText);
  }

  @override
  void dispose() {
    _payload.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      TextField(
        controller: _payload,
        onChanged: widget.controller.editPayload,
        minLines: 8,
        maxLines: 20,
        style: const TextStyle(fontFamily: 'monospace'),
        decoration: InputDecoration(
          labelText: 'Message JSON',
          alignLabelWithHint: true,
          errorText: widget.controller.parseError,
        ),
      ),
      const SizedBox(height: 8),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Validate only'),
        value: widget.controller.validateOnly,
        onChanged: widget.controller.setValidateOnly,
      ),
    ],
  );
}
