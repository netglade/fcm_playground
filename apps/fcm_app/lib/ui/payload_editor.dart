import 'package:flutter/material.dart';

import '../sandbox/sandbox_controller.dart';

/// The raw payload editor: the message JSON that will be sent as-is.
///
/// It owns the [TextEditingController], because that is view state and
/// [SandboxController] must stay testable without a widget pump. Loading a
/// scenario bumps [SandboxController.scenarioRevision], and `SandboxView`
/// keys this widget on that revision, so a scenario replaces the field by
/// replacing this `State` — while ordinary typing never disturbs the cursor.
class PayloadEditor extends StatefulWidget {
  /// Creates the editor. Its initial text comes from [controller]'s current
  /// payload; every edit is pushed straight back into it.
  const PayloadEditor({required this.controller, super.key});

  /// The controller this editor reads its initial text from and pushes
  /// edits into.
  final SandboxController controller;

  @override
  State<PayloadEditor> createState() => _PayloadEditorState();
}

class _PayloadEditorState extends State<PayloadEditor> {
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
  Widget build(BuildContext context) => TextField(
    controller: _payload,
    onChanged: widget.controller.editPayload,
    maxLines: null,
    keyboardType: TextInputType.multiline,
    style: const TextStyle(fontFamily: 'monospace'),
    decoration: const InputDecoration(
      labelText: 'Message JSON',
      alignLabelWithHint: true,
    ),
  );
}
