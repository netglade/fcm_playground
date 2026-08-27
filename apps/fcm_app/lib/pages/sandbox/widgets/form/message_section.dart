import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/sandbox/forms/forms.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/android_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/apns_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/fcm_options_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/form_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/notification_section.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/string_map_rows.dart';
import 'package:fcm_app/pages/sandbox/widgets/form/webpush_section.dart';
import 'package:flutter/material.dart';

/// The whole payload form: FCM's `message` and every block beneath it.
///
/// Its badge is the one that matters most, because each form folds its subforms'
/// validity into its own `isValid`: an invalid field four levels down still marks
/// this header, so an error cannot hide behind a collapsed section while Send sits
/// disabled for a reason nothing on screen explains.
class MessageSection extends StatelessWidget {
  const MessageSection({required this.form, super.key});

  /// Read, never listened to: `SandboxCubit` republishes every model in the
  /// tree, which is what rebuilds this.
  final FcmMessageForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'message',
      subtitle: t.form_section.message,
      isValid: form.isValid,
      // The only section that starts open, so arriving shows the payload's shape
      // rather than a wall of fields or one tile hiding all of it.
      initiallyExpanded: true,
      children: [
        StringMapRows(
          label: 'data',
          value: form.data.value ?? const {},
          onChanged: form.data.updateValue,
        ),
        NotificationSection(form: form.notification),
        AndroidSection(form: form.android),
        ApnsSection(form: form.apns),
        WebpushSection(form: form.webpush),
        FcmOptionsSection(form: form.fcmOptions),
      ],
    );
  }
}
