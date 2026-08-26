import 'package:fcm_app/domains/notifications/entities/notification_channel_reader.dart';
import 'package:fcm_app/domains/notifications/entities/notification_presenter.dart';
import 'package:fcm_app/domains/push/repositories/push_repository.dart';
import 'package:fcm_app/domains/runs/entities/active_run_store.dart';
import 'package:fcm_app/domains/runs/entities/run_scheduler.dart';
import 'package:fcm_app/domains/runs/start_run.dart';
import 'package:fcm_app/domains/telemetry/entities/telemetry_reader.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:fcm_app/pages/inbox/cubit/inbox_cubit.dart';
import 'package:fcm_app/pages/inbox/message_detail_page.dart';
import 'package:fcm_app/pages/inbox/widgets/message_tile.dart';
import 'package:fcm_app/pages/sandbox/cubit/sandbox_cubit.dart';
import 'package:fcm_app/pages/shell/app_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glade_forms/glade_forms.dart';

import '../../fakes/fake_notification_sender.dart';
import '../../fakes/fake_push_payload_store.dart';
import '../../fakes/fake_push_source.dart';
import '../../fakes/fake_run_scheduler.dart';
import '../../fakes/fake_telemetry_reader.dart';
import '../../fakes/in_memory_active_run_store.dart';
import '../../fakes/recording_notification_presenter.dart';
import '../channels/cubit/channels_cubit_test.dart' show FakeChannelReader;

Map<String, Object?> payload({String id = 'msg-1'}) => {
  'id': id,
  'title': 'Build finished',
  'body': 'Release 1.0.0 is ready.',
  'sentAt': '2026-08-06T09:30:00Z',
  'deepLink': '/builds/42',
};

void main() {
  setUpAll(GladeForms.initialize);

  late FakePushSource source;
  late PushRepository repository;
  late InboxCubit inbox;
  late SandboxCubit sandbox;
  late RecordingNotificationPresenter presenter;

  // The shell under this test's own cubits: `App`'s providers build theirs
  // out of `getIt`, which no widget test configures. The shell rather than
  // `InboxView` alone because two tests below assert on the app bar it owns.
  //
  // A full `MaterialApp` of its own rather than the shared `pumpApp` helper: this
  // closure is itself called `pumpApp`, and giving it the helper's shape too would
  // only rename one collision into another. `TranslationProvider` still wraps it
  // directly, for the same reason the helper carries one: `AppShell` reads
  // `context.t` for its language-switcher tooltip.
  Future<void> pumpApp(WidgetTester tester) async {
    sandbox = SandboxCubit(
      sender: FakeNotificationSender(),
      token: () => inbox.state.token,
      startRun: StartRun(
        scheduler: FakeRunScheduler(),
        active: InMemoryActiveRunStore(),
      ),
    );
    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: MultiRepositoryProvider(
            providers: [
              RepositoryProvider<RunScheduler>.value(value: FakeRunScheduler()),
              RepositoryProvider<ActiveRunStore>.value(
                value: InMemoryActiveRunStore(),
              ),
              RepositoryProvider<TelemetryReader>.value(
                value: FakeTelemetryReader(),
              ),
              RepositoryProvider<NotificationChannelReader>.value(
                value: FakeChannelReader([]),
              ),
              RepositoryProvider<NotificationPresenter>.value(value: presenter),
            ],
            child: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: inbox),
                BlocProvider.value(value: sandbox),
              ],
              child: const AppShell(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  setUp(() {
    source = FakePushSource();
    presenter = RecordingNotificationPresenter();
    // Pinned rather than inherited: an assertion on English copy below must not
    // start failing because the host is Czech.
    LocaleSettings.setLocaleSync(AppLocale.en);
  });

  tearDown(() async {
    await sandbox.close();
    await inbox.close();
    repository.dispose();
    await source.dispose();
    await presenter.dispose();
  });

  testWidgets('shows an empty state before anything arrives', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);

    await pumpApp(tester);

    expect(find.text('No pushes received yet.'), findsOne);
  });

  testWidgets('renders a received message with its data keys', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);

    source.emit(payload());
    await tester.pumpAndSettle();

    expect(find.text('Build finished'), findsOne);
    expect(find.textContaining('deepLink'), findsOne);
    expect(find.text('09:30'), findsOne);
    expect(find.text('No pushes received yet.'), findsNothing);
  });

  testWidgets('shows the registration token once resolved', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await repository.refreshToken();

    await pumpApp(tester);

    expect(find.text('fake-token'), findsOne);
  });

  testWidgets('surfaces a setup error in a banner', (tester) async {
    repository = PushRepository(
      source,
      store: FakePushPayloadStore(),
      setupError: 'Firebase is not configured',
    );
    inbox = InboxCubit(repository);

    await pumpApp(tester);

    expect(find.text('Firebase is not configured'), findsOne);
    expect(find.byType(ColoredBox), findsAtLeast(1));
  });

  testWidgets('counts malformed payloads', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);

    source.emit({'id': 'broken'});
    await tester.pumpAndSettle();

    expect(find.text('1 malformed payload dropped'), findsOne);
  });

  testWidgets('pluralises the malformed-payload count', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);

    source.emit({'id': 'broken-1'});
    source.emit({'id': 'broken-2'});
    await tester.pumpAndSettle();

    expect(find.text('2 malformed payloads dropped'), findsOne);
  });

  testWidgets('shows a placeholder for a push with no title', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);

    source.emit({
      'id': 'silent-1',
      'sentAt': '2026-08-06T09:30:00Z',
      'event': 'sync',
    });
    await tester.pumpAndSettle();

    expect(find.text('(no title)'), findsOne);
    expect(find.textContaining('event'), findsOne);
    expect(find.text('1 malformed payload dropped'), findsNothing);
  });

  testWidgets('opens the detail page when a row is tapped', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);
    source.emit(payload());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Build finished'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsOne);
    expect(find.text('/builds/42'), findsOne);
  });

  testWidgets('comes back to the inbox from the detail page', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);
    source.emit(payload());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Build finished'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    expect(find.byType(MessageDetailPage), findsNothing);
    expect(find.widgetWithText(AppBar, 'Push inbox'), findsOne);
  });

  testWidgets('clears the tray without emptying the inbox', (tester) async {
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
    await pumpApp(tester);
    source.emit(payload());
    await tester.pumpAndSettle();
    // A message is present before the tap, and must still be after it.
    expect(find.byType(MessageTile), findsWidgets);

    await tester.tap(find.text('Clear notifications'));
    await tester.pumpAndSettle();

    expect(presenter.cleared, 1);
    expect(
      find.byType(MessageTile),
      findsWidgets,
      reason:
          'the tray and the inbox are different lists — clearing one must not '
          'destroy the record of what arrived',
    );
  });
}
