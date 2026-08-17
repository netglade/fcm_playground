import 'package:flutter/material.dart';

import '../../../sandbox/forms/fcm_options_form.dart';
import '../form_section.dart';

/// Edits the platform-independent `fcm_options` block.
///
/// One field, so no loop earns its keep here. The APNs and WebPush blocks carry
/// extra fields FCM rejects on the generic one, so they have sections of their
/// own rather than a shared parameterised widget — which `prefer-single-widget-
/// per-file` would forbid anyway.
class FcmOptionsSection extends StatelessWidget {
  /// Renders [form]'s single input inside a collapsible section.
  const FcmOptionsSection({required this.form, super.key});

  /// The block this section edits. Read, never listened to: something above
  /// listens to every model in the tree and rebuilds this.
  final FcmOptionsForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'fcm_options',
    subtitle: 'Delivery options FCM applies on every platform',
    isValid: form.isValid,
    children: [
      TextFormField(
        controller: form.analyticsLabel.controller,
        validator: form.analyticsLabel.textFormFieldInputValidator,
        decoration: const InputDecoration(labelText: 'analytics_label'),
      ),
    ],
  );
}
