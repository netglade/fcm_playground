import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';

/// Warning shown under the delivery-target dropdown once "All devices" is
/// picked.
///
/// Public, and in its own file, so [SendTargetField] can construct it:
/// `prefer-single-widget-per-file` is fatal here, and keeping this note
/// private inside `send_target_field.dart` would have meant two widgets in
/// one file.
class AllDevicesNote extends StatelessWidget {
  const AllDevicesNote({super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Text(context.t.send_target.all_devices_warning),
  );
}
