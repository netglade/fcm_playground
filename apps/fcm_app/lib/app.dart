import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'di/service_locator.dart';
import 'domains/notifications/entities/notification_channel_reader.dart';
import 'domains/push/repositories/push_repository.dart';
import 'domains/runs/entities/active_run_store.dart';
import 'domains/runs/entities/run_scheduler.dart';
import 'domains/runs/start_run.dart';
import 'domains/sandbox/entities/notification_sender.dart';
import 'domains/telemetry/entities/push_telemetry.dart';
import 'domains/telemetry/entities/telemetry_reader.dart';
import 'i18n/translations.g.dart';
import 'pages/inbox/cubit/inbox_cubit.dart';
import 'pages/sandbox/cubit/sandbox_cubit.dart';
import 'pages/shell/app_shell.dart';

/// Root widget, and the one place the cubits are created.
///
/// Above the shell, not inside the pages, and that placement is load-bearing twice
/// over: `SandboxView` and `ScenariosView` edit the *same* [SandboxCubit], so a
/// provider inside either page would lose the handoff, and the shell's
/// `IndexedStack` is what keeps the half-filled form alive across a tab switch.
///
/// Nothing below this widget reads the locator, so widget tests wrap the widget
/// under test in `BlocProvider.value` and never configure it at all. The
/// `MultiRepositoryProvider` below supplies the [RunScheduler], [StartRun] and
/// [ActiveRunStore] the same way: each is looked up here, once, and every page
/// that needs one — the Runs pages for the scheduler, the Sandbox's footer for
/// `StartRun`, the shell itself for the id of the run it may need to reopen —
/// reads it from `context` instead of from the locator.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MultiRepositoryProvider(
    // The locator stops here. Everything below reads these from `context`, which is
    // what lets a widget test wrap the widget under test in a
    // `RepositoryProvider.value` and configure nothing at all.
    providers: [
      RepositoryProvider<RunScheduler>(create: (_) => getIt<RunScheduler>()),
      RepositoryProvider<StartRun>(create: (_) => getIt<StartRun>()),
      RepositoryProvider<ActiveRunStore>(
        create: (_) => getIt<ActiveRunStore>(),
      ),
      RepositoryProvider<TelemetryReader>(
        create: (_) => getIt<TelemetryReader>(),
      ),
      RepositoryProvider<NotificationChannelReader>(
        create: (_) => getIt<NotificationChannelReader>(),
      ),
    ],
    child: MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => InboxCubit(getIt<PushRepository>())),
        BlocProvider(
          create: (_) => SandboxCubit(
            sender: getIt<NotificationSender>(),
            // A callback rather than the repository itself, so the sandbox reads
            // the token without tying its lifetime to the inbox's cubit.
            token: () => getIt<PushRepository>().token,
            telemetry: getIt<PushTelemetry>(),
            startRun: getIt<StartRun>(),
          ),
        ),
      ],
      child: MaterialApp(
        onGenerateTitle: (context) => context.t.app.title,
        locale: TranslationProvider.of(context).flutterLocale,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: AppLocaleUtils.supportedLocales,
        theme: ThemeData(colorSchemeSeed: Colors.indigo),
        home: const AppShell(),
      ),
    ),
  );
}
