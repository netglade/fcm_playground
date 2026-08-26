import 'package:flutter/material.dart';

import '../../../../../i18n/translations.g.dart';
import '../../../forms/apns_fcm_options_form.dart';
import '../form_section.dart';

/// Edits the APNs-specific `fcm_options` block.
///
/// Separate from `FcmOptionsSection` because APNs accepts an `image` the generic
/// block does not: one shared section would offer that field on platforms that
/// reject it.
class ApnsFcmOptionsSection extends StatelessWidget {
  const ApnsFcmOptionsSection({required this.form, super.key});

  final ApnsFcmOptionsForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'fcm_options',
      subtitle: t.form_section.apns_fcm_options,
      isValid: form.isValid,
      children: [
        TextFormField(
          controller: form.image.controller,
          validator: form.image.textFormFieldInputValidator,
          decoration: const InputDecoration(labelText: 'image'),
        ),
        TextFormField(
          controller: form.analyticsLabel.controller,
          validator: form.analyticsLabel.textFormFieldInputValidator,
          decoration: const InputDecoration(labelText: 'analytics_label'),
        ),
      ],
    );
  }
}
