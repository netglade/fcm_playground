import 'package:fcm_app/i18n/channel_text.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:fcm_app/pages/channels/channels_view.dart';
import 'package:fcm_app/pages/channels/cubit/channels_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';

// Reuse the fake from the cubit test rather than writing a second one.
import '../../fakes/fake_channel_reader.dart';

// A function that pumps rather than one that returns a `Widget`, the same shape
// as `pumpApp` in test/helpers: DCM's `avoid-returning-widgets` flags a global
// function that hands back a `Widget`, so the wrapping happens inside the call
// instead of at the call site.
Future<void> _pump(WidgetTester tester, ChannelsCubit cubit) =>
    tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: BlocProvider.value(value: cubit, child: const ChannelsView()),
        ),
      ),
    );

void main() {
  testWidgets('shows a card per channel with the reported importance', (
    tester,
  ) async {
    final cubit = ChannelsCubit(
      FakeChannelReader([systemChannel('fcm_sample_high')]),
    );
    await _pump(tester, cubit);
    await cubit.load();
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocale.en.buildSync().channelName('fcm_sample_high')),
      findsOneWidget,
    );
    // Every other channel is in the table but not in the fake's answer.
    expect(
      find.text(AppLocale.en.buildSync().channels.not_registered),
      findsWidgets,
    );
  });

  testWidgets('offers the immutability probe on chat_v1 only', (tester) async {
    final cubit = ChannelsCubit(FakeChannelReader([systemChannel('chat_v1')]));
    await _pump(tester, cubit);
    await cubit.load();
    await tester.pumpAndSettle();

    expect(
      find.text(AppLocale.en.buildSync().channels.try_lower),
      findsOneWidget,
    );
  });

  testWidgets(
    'does not flag the system default sound as a mismatch when none was '
    'requested',
    (tester) async {
      // Every channel but custom_sound never sets `playSound`, so Android
      // assigns its own default and reports this URI back — a request that
      // was never made must not read as a disagreement.
      const systemDefaultSoundUri =
          'content://settings/system/notification_sound';
      final cubit = ChannelsCubit(
        FakeChannelReader([
          systemChannel(
            'fcm_sample_high',
            sound: const UriAndroidNotificationSound(systemDefaultSoundUri),
          ),
        ]),
      );
      await _pump(tester, cubit);
      await cubit.load();
      await tester.pumpAndSettle();

      final t = AppLocale.en.buildSync();
      // Rendered as a readable word, not the raw URI.
      expect(find.text(t.channels.default_sound), findsOneWidget);
      expect(find.textContaining(systemDefaultSoundUri), findsNothing);

      // Not styled as a mismatch: the reported sound's Text carries the
      // theme's default color, not colorScheme.error.
      final reportedSound = tester.widget<Text>(
        find.text(t.channels.default_sound),
      );
      final theme = Theme.of(
        tester.element(find.text(t.channels.default_sound)),
      );
      expect(reportedSound.style?.color, isNot(theme.colorScheme.error));
    },
  );
}
