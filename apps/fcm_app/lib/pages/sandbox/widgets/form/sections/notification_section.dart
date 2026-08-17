import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../sandbox/forms/fcm_notification_form.dart';
import '../form_section.dart';

/// Edits FCM's cross-platform `notification` block.
///
/// Three plain strings, rendered from a list of label/input pairs rather than
/// spelled out one widget at a time. That is the pattern every section in this
/// directory follows, because `android.notification` has 27 fields and DCM's
/// 50-line limit applies here — and it has the side benefit that a field cannot
/// be bound to the wrong label by a copy-paste slip.
class NotificationSection extends StatelessWidget {
  /// Renders [form]'s inputs inside a collapsible section.
  const NotificationSection({required this.form, super.key});

  /// The block this section edits. Read, never listened to: something above
  /// listens to every model in the tree and rebuilds this.
  final FcmNotificationForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'notification',
    subtitle: 'Shown on every platform unless a platform block overrides it',
    isValid: form.isValid,
    children: [
      for (final (label, input) in _texts(form))
        TextFormField(
          controller: input.controller,
          validator: input.textFormFieldInputValidator,
          decoration: InputDecoration(labelText: label),
        ),
    ],
  );
}

/// This block's text inputs, labelled as FCM spells them.
///
/// Typed over `GladeInput<Object?>` rather than the concrete input classes: the
/// two members a text field binds — `controller` and
/// `textFormFieldInputValidator` — are declared on `GladeInput` itself and take
/// no part in its type argument, so one list can carry strings, numbers and
/// anything else edited as text.
List<(String, GladeInput<Object?>)> _texts(FcmNotificationForm form) => [
  ('title', form.title),
  ('body', form.body),
  ('image', form.image),
];
