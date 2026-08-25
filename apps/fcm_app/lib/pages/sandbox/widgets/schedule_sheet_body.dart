import 'package:flutter/material.dart';

import '../../../i18n/translations.g.dart';
import 'preset_chips.dart';
import 'schedule_choice.dart';

const _delayPresets = [10, 20, 30, 60];
const _spacingPresets = [0, 2, 5, 10];

/// The sheet's contents: a delay, and — when [withSpacing] — a spacing too.
///
/// Public, and in its own file, so [showScheduleSheet]'s `builder` (declared in a
/// different file) can construct it: `prefer-match-file-name` is fatal here and
/// fires on private classes too, so keeping this sheet private the way the first
/// draft did would have meant naming its file for the wrong declaration.
class ScheduleSheetBody extends StatefulWidget {
  const ScheduleSheetBody({
    required this.initialDelaySeconds,
    required this.withSpacing,
    super.key,
  });

  final int initialDelaySeconds;

  final bool withSpacing;

  @override
  State<ScheduleSheetBody> createState() => _ScheduleSheetBodyState();
}

class _ScheduleSheetBodyState extends State<ScheduleSheetBody> {
  late int _delay = widget.initialDelaySeconds > 0
      ? widget.initialDelaySeconds
      : defaultDelaySeconds;
  int _spacing = 0;

  @override
  Widget build(BuildContext context) {
    final t = context.t;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.schedule_sheet.delay,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            PresetChips(
              values: _delayPresets,
              selected: _delay,
              onSelected: (value) => setState(() => _delay = value),
            ),
            if (widget.withSpacing) ...[
              const SizedBox(height: 12),
              Text(
                t.schedule_sheet.spacing,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(t.schedule_sheet.spacing_help),
              PresetChips(
                values: _spacingPresets,
                selected: _spacing,
                onSelected: (value) => setState(() => _spacing = value),
              ),
            ],
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(
                  ScheduleChoice(
                    delaySeconds: _delay,
                    spacingSeconds: _spacing,
                  ),
                ),
                // Its own key, distinct from `common.schedule_ellipsis`: this
                // button acts rather than opening a sheet, so it takes no
                // ellipsis.
                child: Text(t.schedule_sheet.confirm),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
