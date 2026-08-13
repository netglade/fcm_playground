import 'package:flutter/material.dart';

import '../../../sandbox/forms/apns_fcm_options_form.dart';
import '../form_section.dart';

/// Edits the APNs-specific `fcm_options` block.
///
/// Separate from `FcmOptionsSection` because APNs accepts an `image` the generic
/// block does not: one shared section would offer that field on platforms that
/// reject it.
class ApnsFcmOptionsSection extends StatelessWidget {
  /// Renders [form]'s inputs inside a collapsible section.
  const ApnsFcmOptionsSection({required this.form, super.key});

  /// The block this section edits. Read, never listened to: something above
  /// listens to every model in the tree and rebuilds this.
  final ApnsFcmOptionsForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'fcm_options',
    subtitle: 'Delivery options, with the image only APNs accepts',
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
