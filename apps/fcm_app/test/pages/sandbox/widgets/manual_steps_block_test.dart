import 'package:fcm_app/ui/manual_steps_block.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the steps as selectable text, so a command can be copied', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ManualStepsBlock(
            steps: 'adb shell dumpsys deviceidle force-idle',
          ),
        ),
      ),
    );

    expect(find.byType(SelectableText), findsOne);
    // `find.textContaining` matches an `EditableText` as readily as a `Text`,
    // and `SelectableText` builds one — so on its own the finder below could
    // be satisfied by a plain `Text` sitting beside an empty `SelectableText`.
    // Scoping it to the selectable subtree is what proves the command itself
    // is the copyable part.
    expect(
      find.descendant(
        of: find.byType(SelectableText),
        matching: find.textContaining('force-idle'),
      ),
      findsOne,
    );
  });

  testWidgets('sets the command in a monospace face', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ManualStepsBlock(steps: 'adb shell am set-standby-bucket'),
        ),
      ),
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
