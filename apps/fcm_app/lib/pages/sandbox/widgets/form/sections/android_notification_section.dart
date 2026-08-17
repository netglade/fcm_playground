import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../../sandbox/forms/android_notification_form.dart';
import '../enum_field.dart';
import '../form_section.dart';
import '../string_list_rows.dart';
import '../tristate_field.dart';
import 'light_settings_section.dart';

/// Edits `android.notification` — 27 fields, the largest section in the form.
///
/// Its fields are held as **data** and iterated, one loop per control family,
/// rather than spelled out as 27 widgets. That is not a style preference: this
/// directory is inside DCM's 50-line-per-function limit, and both obvious
/// escapes are fatal rules here — a `Widget _buildFoo()` helper trips
/// `avoid-returning-widgets`, and a second widget class in the file trips
/// `prefer-single-widget-per-file`.
class AndroidNotificationSection extends StatelessWidget {
  /// Renders [form]'s inputs, and its nested LED block, inside a section.
  const AndroidNotificationSection({required this.form, super.key});

  /// The block this section edits. Read, never listened to: something above
  /// listens to every model in the tree and rebuilds this.
  final AndroidNotificationForm form;

  @override
  Widget build(BuildContext context) => FormSection(
    title: 'notification',
    subtitle: "Everything Android's tray understands, beyond the shared block",
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

/// This block's text inputs, labelled as FCM spells them.
///
/// Typed over `GladeInput<Object?>` because `controller` and
/// `textFormFieldInputValidator` are declared on `GladeInput` itself and take no
/// part in its type argument, so one list carries every input edited as text.
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

/// This block's optional booleans, each of which needs three states.
///
/// FCM distinguishes `false` from absent, so these are checkboxes that can also
/// be unset — never a plain two-state one, which would silently send fields
/// nobody chose.
List<(String, GladeInput<bool?>)> _flags(AndroidNotificationForm form) => [
  ('sticky', form.sticky),
  ('local_only', form.localOnly),
  ('default_sound', form.defaultSound),
  ('default_vibrate_timings', form.defaultVibrateTimings),
  ('default_light_settings', form.defaultLightSettings),
  ('bypass_proxy_notification', form.bypassProxyNotification),
];

/// This block's string lists, each edited as one row per item.
///
/// The row count is not known ahead of time, so these are uncontrolled in
/// glade's sense: the editor takes the whole list and hands a whole list back.
List<(String, GladeInput<List<String>?>)> _lists(
  AndroidNotificationForm form,
) => [
  ('body_loc_args', form.bodyLocArgs),
  ('title_loc_args', form.titleLocArgs),
  ('vibrate_timings', form.vibrateTimings),
];
