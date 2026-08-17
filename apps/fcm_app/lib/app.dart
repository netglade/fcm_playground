import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'di/service_locator.dart';
import 'domains/push/repositories/push_repository.dart';
import 'domains/sandbox/entities/notification_sender.dart';
import 'domains/telemetry/entities/push_telemetry.dart';
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
/// under test in `BlocProvider.value` and never configure it at all.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(create: (_) => InboxCubit(getIt<PushRepository>())),
      BlocProvider(
        create: (_) => SandboxCubit(
          sender: getIt<NotificationSender>(),
          // A callback rather than the repository itself, so the sandbox reads
          // the token without tying its lifetime to the inbox's cubit.
          token: () => getIt<PushRepository>().token,
          telemetry: getIt<PushTelemetry>(),
        ),
      ),
    ],
    child: MaterialApp(
      title: 'FCM Sample',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const AppShell(),
    ),
  );
}
