import 'package:flutter/material.dart';

import 'schedule_choice.dart';
import 'schedule_sheet_body.dart';

export 'schedule_choice.dart';

/// Asks for a delay, and for a spacing when there is more than one message.
///
/// One sheet for both callers — the Sandbox schedules one send, the gallery
/// schedules a batch — because the question is the same question.
Future<ScheduleChoice?> showScheduleSheet(
  BuildContext context, {
  required int initialDelaySeconds,
  bool withSpacing = false,
}) => showModalBottomSheet<ScheduleChoice>(
  context: context,
  builder: (_) => ScheduleSheetBody(
    initialDelaySeconds: initialDelaySeconds,
    withSpacing: withSpacing,
  ),
);
