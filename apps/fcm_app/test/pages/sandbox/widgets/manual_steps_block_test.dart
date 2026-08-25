import 'package:fcm_app/pages/sandbox/widgets/manual_steps_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/pump_app.dart';

void main() {
  testWidgets('shows the steps as selectable text, so a command can be copied', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const ManualStepsBlock(steps: 'adb shell dumpsys deviceidle force-idle'),
    );

    expect(find.byType(SelectableText), findsOne);
    // `find.textContaining` matches an `EditableText` as readily as a `Text`, so
    // scoping to the selectable subtree is what proves the command is the copyable
    // part.
    expect(
      find.descendant(
        of: find.byType(SelectableText),
        matching: find.textContaining('force-idle'),
      ),
      findsOne,
    );
  });

  testWidgets('sets the command in a monospace face', (tester) async {
    await pumpApp(
      tester,
      const ManualStepsBlock(steps: 'adb shell am set-standby-bucket'),
    );

    expect(
      tester
          .widget<SelectableText>(find.byType(SelectableText))
          .style
          ?.fontFamily,
      'monospace',
    );
  });
}
