import 'package:flutter/material.dart';

import '../../../forms/webpush_fcm_options_form.dart';
import '../form_section.dart';

/// Edits the WebPush-specific `fcm_options` block.
///
/// Separate from `FcmOptionsSection` because WebPush accepts the `link` a click
/// opens, which neither the generic nor the APNs block has.
class WebpushFcmOptionsSection extends StatelessWidget {
  const WebpushFcmOptionsSection({required this.form, super.key});

  final WebpushFcmOptionsForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'fcm_options',
    subtitle: 'Delivery options, with the link a click opens',
    isValid: form.isValid,
    children: [
      TextFormField(
        controller: form.link.controller,
        validator: form.link.textFormFieldInputValidator,
        decoration: const InputDecoration(labelText: 'link'),
      ),
      TextFormField(
        controller: form.analyticsLabel.controller,
        validator: form.analyticsLabel.textFormFieldInputValidator,
        decoration: const InputDecoration(labelText: 'analytics_label'),
      ),
    ],
  );
}
