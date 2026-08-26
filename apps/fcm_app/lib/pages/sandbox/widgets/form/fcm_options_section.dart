import 'package:flutter/material.dart';

import '../../../../../i18n/translations.g.dart';
import '../../forms/fcm_options_form.dart';
import 'form_section.dart';

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
