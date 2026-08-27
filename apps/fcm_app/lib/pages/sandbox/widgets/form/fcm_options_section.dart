import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/forms/forms.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/form_section.dart';
import 'package:flutter/material.dart';

/// Edits the platform-independent `fcm_options` block. The APNs and WebPush
/// blocks carry extra fields FCM rejects here, so they have sections of their own.
class FcmOptionsSection extends StatelessWidget {
  const FcmOptionsSection({required this.form, super.key});

  final FcmOptionsForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'fcm_options',
      subtitle: t.form_section.fcm_options,
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
}
