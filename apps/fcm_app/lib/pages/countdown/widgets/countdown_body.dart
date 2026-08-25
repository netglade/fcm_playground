import 'package:flutter/material.dart';

import '../../../domains/runs/entities/countdown_screen.dart';
import '../cubit/countdown_state.dart';

/// The countdown's face: the seconds left, the instruction to swipe the app away,
/// and the two buttons a user reaches for while they wait.
///
/// Split out of [CountdownPage] to keep its `build` under the project's line
/// budget for a single method, rather than folded into a `Widget`-returning helper.
class CountdownBody extends StatelessWidget {
  const CountdownBody({
    required this.state,
    required this.screen,
    required this.onCancel,
    super.key,
  });

  final CountdownState state;

  final CountdownScreen screen;

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${state.remainingSeconds}',
                style: theme.textTheme.displayLarge,
              ),
              Text('seconds', style: theme.textTheme.titleMedium),
              const SizedBox(height: 32),
              Text(
                'Swipe the app away from recents now. The push is already '
                'scheduled on the server, so it will arrive whether this app '
                'is running or not.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                'An ordinary app cannot switch the display off — only dim it '
                'and stop keeping it awake, so the system times out on its '
                'own.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: screen.dim,
                    child: const Text('Dim the screen'),
                  ),
                  OutlinedButton(
                    onPressed: screen.openBatterySettings,
                    child: const Text('Battery settings'),
                  ),
                ],
              ),
              if (state.error case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    error,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: 24),
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
            ],
          ),
        ),
      ),
    );
  }
}
