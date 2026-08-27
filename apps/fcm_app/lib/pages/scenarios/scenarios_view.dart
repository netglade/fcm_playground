import 'package:fcm_app/domains/runs/runs.dart';
import 'package:fcm_app/i18n/i18n.dart';
import 'package:fcm_app/pages/countdown/countdown.dart';
import 'package:fcm_app/pages/runs/runs.dart';
import 'package:fcm_app/pages/sandbox/cubit/cubit.dart';
import 'package:fcm_app/pages/sandbox/widgets/widgets.dart';
import 'package:fcm_app/pages/scenarios/widgets/widgets.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// The scenario gallery's own page.
///
/// Two modes. Tapping a card normally hands off to the Sandbox with the template
/// applied; in selection mode a tap ticks a box instead, and the ticked scenarios
/// are scheduled as one run.
class ScenariosView extends StatefulWidget {
  const ScenariosView({required this.onScenarioSelected, super.key});

  /// Called once a tapped scenario has been applied, so the caller can move on —
  /// this page does not know what "on" means.
  final VoidCallback onScenarioSelected;

  @override
  State<ScenariosView> createState() => _ScenariosViewState();
}

class _ScenariosViewState extends State<ScenariosView> {
  /// Null when not selecting, which is also what the cards read to decide whether
  /// to draw a checkbox at all.
  Set<String>? _selected;

  // A Column with the bar pinned outside the `ListView`, rather than the bar as
  // that list's first child: scrolling to a ticked-far-down card must not carry
  // the bar — and the "N selected" count it shows — off screen with it.
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: SelectionBar(
          selectedCount: _selected?.length ?? 0,
          isSelecting: _selected != null,
          onStart: () => setState(() => _selected = {}),
          onCancel: () => setState(() => _selected = null),
          onSchedule: _schedule,
        ),
      ),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ScenarioGroupList(
              onScenarioSelected: widget.onScenarioSelected,
              selectedIds: _selected,
              onSelectionChanged: _toggle,
            ),
          ],
        ),
      ),
    ],
  );

  void _toggle(String id, bool isSelected) {
    final selected = _selected;
    if (selected == null) {
      return;
    }

    setState(() {
      if (isSelected) {
        selected.add(id);
      } else {
        selected.remove(id);
      }
    });
  }

  /// Schedules every ticked scenario as one run, in catalogue order.
  Future<void> _schedule() async {
    final ids = _selected;
    if (ids == null || ids.isEmpty) {
      return;
    }

    final token = context.read<SandboxCubit>().deviceToken;
    final scenarios = [
      for (final scenario in scenarioGallery)
        if (ids.contains(scenario.id)) scenario,
    ];
    // Only a scenario without a target of its own needs this device's token; a
    // topic or a condition names its own audience.
    if (token == null && scenarios.any((s) => s.target == null)) {
      _report(context.t.scenarios.no_token);

      return;
    }

    // Read before the first await, along with everything else this method needs
    // from `context` past that point — `showScheduleSheet` is the first one.
    final startRun = context.read<StartRun>();
    final scheduler = context.read<RunScheduler>();
    final active = context.read<ActiveRunStore>();
    final navigator = Navigator.of(context);
    final choice = await showScheduleSheet(
      context,
      initialDelaySeconds: scenarios.first.defaultDelaySeconds,
      withSpacing: true,
    );
    if (choice == null) {
      return;
    }

    final ScheduledRun run;
    try {
      run = await startRun(
        ScheduleRunRequest(
          delaySeconds: choice.delaySeconds,
          spacingSeconds: choice.spacingSeconds,
          items: [
            for (final scenario in scenarios)
              SendMessageRequest(
                target: scenario.target ?? TokenTarget(token!),
                message: FcmMessage.fromJson(scenario.payloadTemplate),
                scenarioId: scenario.id,
              ),
          ],
        ),
      );
    } on RunSchedulerException catch (error) {
      _report(error.message);

      return;
    }

    if (!mounted) {
      return;
    }
    setState(() => _selected = null);

    // Built here, before the push, rather than inside the route's `builder` — a
    // `builder` can run again on a rebuild, and a cubit built there would restart
    // the countdown out from under the user.
    final countdown = CountdownCubit(
      scheduler: scheduler,
      run: run,
      active: active,
      delaySeconds: choice.delaySeconds,
    );
    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => CountdownPage(
          cubit: countdown,
          onFinished: () => navigator.pushReplacement(
            MaterialPageRoute<void>(
              builder: (_) =>
                  RunTimelinePage(scheduler: scheduler, runId: run.id),
            ),
          ),
        ),
      ),
    );
  }

  void _report(String message) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }
}
