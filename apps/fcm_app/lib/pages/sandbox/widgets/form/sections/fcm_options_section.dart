import 'package:flutter/material.dart';

import '../../../forms/fcm_options_form.dart';
import '../form_section.dart';

/// Edits the platform-independent `fcm_options` block. The APNs and WebPush
/// blocks carry extra fields FCM rejects here, so they have sections of their own.
class FcmOptionsSection extends StatelessWidget {
  const FcmOptionsSection({required this.form, super.key});

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
