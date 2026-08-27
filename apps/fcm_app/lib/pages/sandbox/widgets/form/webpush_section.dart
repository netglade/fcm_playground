import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/forms/forms.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/form_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/path_rows_field.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/string_map_rows.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/webpush_fcm_options_section.dart';
import 'package:flutter/material.dart';

/// Edits `webpush` — what FCM hands to a browser's push gateway.
///
/// Its `notification` is the Web Notification API's own options object, forwarded
/// verbatim, so it is edited as dotted-path rows: an option a browser vendor ships
/// tomorrow is writable today.
class WebpushSection extends StatelessWidget {
  const WebpushSection({required this.form, super.key});

  final WebpushConfigForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'webpush',
      subtitle: t.form_section.webpush,
      isValid: form.isValid,
      children: [
        StringMapRows(
          label: 'headers',
          value: form.headers.value ?? const {},
          onChanged: form.headers.updateValue,
        ),
        StringMapRows(
          label: 'data',
          value: form.data.value ?? const {},
          onChanged: form.data.updateValue,
        ),
        PathRowsField(
          label: 'notification',
          value: form.notification.value ?? const {},
          onChanged: form.notification.updateValue,
        ),
        WebpushFcmOptionsSection(form: form.fcmOptions),
      ],
    );
  }
}
