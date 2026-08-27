import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/forms/forms.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/form_section.dart';
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

/// Edits FCM's cross-platform `notification` block.
class NotificationSection extends StatelessWidget {
  const NotificationSection({required this.form, super.key});

  final FcmNotificationForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'notification',
      subtitle: t.form_section.notification,
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
}

/// See `AndroidNotificationSection` for why these are typed over
/// `GladeInput<Object?>`.
List<(String, GladeInput<Object?>)> _texts(FcmNotificationForm form) => [
  ('title', form.title),
  ('body', form.body),
  ('image', form.image),
];
