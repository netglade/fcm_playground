import 'package:flutter/material.dart';

import '../../../sandbox/forms/fcm_message_form.dart';
import '../form_section.dart';
import '../string_map_rows.dart';
import 'android_section.dart';
import 'apns_section.dart';
import 'fcm_options_section.dart';
import 'notification_section.dart';
import 'webpush_section.dart';

/// The whole payload form: FCM's `message` and every block beneath it.
///
/// The root the Sandbox renders. Its badge is the one that matters most, because
/// each form folds its subforms' validity into its own `isValid`: an invalid
/// field four levels down still marks this header, so an error cannot hide
/// behind a collapsed section while Send sits disabled for a reason nothing on
/// screen explains.
class MessageSection extends StatelessWidget {
  /// Renders [form]'s inputs and its five nested blocks inside a section.
  const MessageSection({required this.form, super.key});

  /// The root form this section edits. Read, never listened to: something above
  /// listens to every model in the tree and rebuilds this.
  final FcmMessageForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'message',
    subtitle: 'The FCM v1 message, minus the delivery target the server sets',
    isValid: form.isValid,
    // The only section that starts open. Every block beneath it starts closed, so
    // arriving shows the payload's shape — data plus five named blocks — rather
    // than either a wall of fields or one tile hiding all of it.
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
