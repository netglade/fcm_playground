import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'di/service_locator.dart';
import 'domains/domains.dart';
import 'i18n/translations.g.dart';
import 'pages/pages.dart';

/// Root widget, and the one place the cubits are created.
///
/// Above the shell, not inside the pages, and that placement is load-bearing twice
/// over: `SandboxView` and `ScenariosView` edit the *same* [SandboxCubit], so a
/// provider inside either page would lose the handoff, and the shell's
/// `IndexedStack` is what keeps the half-filled form alive across a tab switch.
///
/// Nothing below this widget reads the locator except `AppShell`'s language
/// switcher (`app_shell.dart`), which writes through `getIt<LocaleStore>()`
/// directly rather than through a provider: it is the one widget that writes
/// it, the write is fire-and-forget, and threading a repository down for a
/// single call would be ceremony a second writer would justify. So a widget
/// test still wraps its widget under test in `BlocProvider.value` and
/// configures nothing else, unless it exercises that one switcher, which then
/// needs its own `LocaleStore` registered. The
/// `MultiRepositoryProvider` below supplies the [RunScheduler], [StartRun],
/// [ActiveRunStore] and [NotificationPresenter] the same way: each is looked up
/// here, once, and every page that needs one — the Runs pages for the
/// scheduler, the Sandbox's footer for `StartRun`, the shell itself for the id
/// of the run it may need to reopen, the Inbox for its Clear button — reads it
/// from `context` instead of from the locator.
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
      RepositoryProvider<NotificationPresenter>(
        create: (_) => getIt<NotificationPresenter>(),
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
