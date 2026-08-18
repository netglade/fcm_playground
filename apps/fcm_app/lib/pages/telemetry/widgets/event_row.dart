import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// One of `TraceCard`'s nine rows: the type, whether it arrived, and if so when.
///
/// Extracted into its own file rather than kept private alongside `TraceCard`: DCM's
/// `prefer-single-widget-per-file` counts a private widget class too, so a second
/// `Widget` subclass in that file — public or not — still trips the rule.
class EventRow extends StatelessWidget {
  const EventRow({required this.type, required this.event, super.key});

  final TelemetryEventType type;

  final TelemetryEvent? event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final arrived = event;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 20, child: Text(arrived == null ? '—' : '✓')),
          SizedBox(width: 120, child: Text(type.wireName)),
          Expanded(
            child: Text(
              arrived == null ? '' : _describe(arrived, type),
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

/// The time, the detail, and the one caveat the record carries.
///
/// `sent` and `send_failed` are both annotated because both are stamped from the one
/// clock reading taken before the API calls FCM, not from FCM's answer — see the
/// spec's Scope. Leaving that unsaid would let either column read as a response time
/// it is not.
String _describe(TelemetryEvent event, TelemetryEventType type) {
  final at = event.at.toIso8601String();
  final detail = event.detail == null ? '' : ' · ${event.detail}';
  final caveat = _isPreRequestStamp(type) ? ' · (request received)' : '';

  return '$at$detail$caveat';
}

/// Whether [type]'s `at` is the one clock reading taken before the API calls FCM,
/// rather than a time FCM itself reported.
bool _isPreRequestStamp(TelemetryEventType type) =>
    type == TelemetryEventType.sent || type == TelemetryEventType.sendFailed;
