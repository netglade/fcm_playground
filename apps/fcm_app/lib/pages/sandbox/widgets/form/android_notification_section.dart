import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../../i18n/translations.g.dart';
import '../../forms/android_notification_form.dart';
import 'enum_field.dart';
import 'form_section.dart';
import 'string_list_rows.dart';
import 'tristate_field.dart';
import 'light_settings_section.dart';

/// Edits `android.notification` — 27 fields, the largest section in the form.
///
/// Its fields are held as data and iterated, one loop per control family, because
/// DCM's 50-line-per-function limit applies here and both escapes are fatal rules:
/// a `Widget _buildFoo()` helper trips `avoid-returning-widgets`, and a second
/// widget class in the file trips `prefer-single-widget-per-file`.
class AndroidNotificationSection extends StatelessWidget {
  const AndroidNotificationSection({required this.form, super.key});

  final AndroidNotificationForm form;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return FormSection(
      title: 'notification',
      subtitle: t.form_section.android_notification,
      isValid: form.isValid,
      children: [
        for (final (label, input) in _texts(form))
          TextFormField(
            controller: input.controller,
            validator: input.textFormFieldInputValidator,
            decoration: InputDecoration(labelText: label),
          ),
        TextFormField(
          controller: form.notificationCount.controller,
          validator: form.notificationCount.textFormFieldInputValidator,
          decoration: const InputDecoration(labelText: 'notification_count'),
          keyboardType: TextInputType.number,
        ),
        for (final (label, input) in _flags(form))
          TristateField(label: label, input: input),
        for (final (label, input) in _lists(form))
          StringListRows(
            label: label,
            value: input.value ?? const [],
            onChanged: input.updateValue,
          ),
        EnumField<AndroidNotificationPriority>(
          label: 'notification_priority',
          input: form.notificationPriority,
          values: AndroidNotificationPriority.values,
          labelOf: (value) => value.wireName,
        ),
        EnumField<NotificationVisibility>(
          label: 'visibility',
          input: form.visibility,
          values: NotificationVisibility.values,
          labelOf: (value) => value.wireName,
        ),
        EnumField<NotificationProxy>(
          label: 'proxy',
          input: form.proxy,
          values: NotificationProxy.values,
          labelOf: (value) => value.wireName,
        ),
        LightSettingsSection(form: form.lightSettings),
      ],
    );
  }
}

/// Typed over `GladeInput<Object?>`: the two members a text field binds are
/// declared on `GladeInput` itself, so one list carries every input edited as
/// text.
List<(String, GladeInput<Object?>)> _texts(AndroidNotificationForm form) => [
  ('title', form.title),
  ('body', form.body),
  ('icon', form.icon),
  ('color', form.color),
  ('sound', form.sound),
  ('tag', form.tag),
  ('click_action', form.clickAction),
  ('body_loc_key', form.bodyLocKey),
  ('title_loc_key', form.titleLocKey),
  ('channel_id', form.channelId),
  ('ticker', form.ticker),
  ('event_time', form.eventTime),
  ('image', form.image),
];

/// FCM distinguishes `false` from absent, so these are checkboxes that can also
/// be unset.
List<(String, GladeInput<bool?>)> _flags(AndroidNotificationForm form) => [
  ('sticky', form.sticky),
  ('local_only', form.localOnly),
  ('default_sound', form.defaultSound),
  ('default_vibrate_timings', form.defaultVibrateTimings),
  ('default_light_settings', form.defaultLightSettings),
  ('bypass_proxy_notification', form.bypassProxyNotification),
];

/// The row count is not known ahead of time, so these are uncontrolled in glade's
/// sense: the editor takes the whole list and hands a whole list back.
List<(String, GladeInput<List<String>?>)> _lists(
  AndroidNotificationForm form,
) => [
  ('body_loc_args', form.bodyLocArgs),
  ('title_loc_args', form.titleLocArgs),
  ('vibrate_timings', form.vibrateTimings),
];
