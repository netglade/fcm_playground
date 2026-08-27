import 'package:fcm_app/domains/runs/runs.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/countdown/cubit/cubit.dart';
import 'package:flutter/material.dart';

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
    final t = context.t;

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
              Text(t.countdown.seconds, style: theme.textTheme.titleMedium),
              const SizedBox(height: 32),
              Text(
                t.countdown.swipe_away,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              Text(
                t.countdown.dim_note,
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
                    child: Text(t.countdown.dim_screen),
                  ),
                  OutlinedButton(
                    onPressed: screen.openBatterySettings,
                    child: Text(t.countdown.battery_settings),
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
              // The same key used wherever a sheet or selection can be dismissed.
              TextButton(onPressed: onCancel, child: Text(t.common.cancel)),
            ],
          ),
        ),
      ),
    );
  }
}
