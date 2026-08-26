import 'package:fcm_app/i18n/channel_text.dart';
import 'package:fcm_app/i18n/translations.g.dart';
import 'package:fcm_app/pages/channels/channels_view.dart';
import 'package:fcm_app/pages/channels/cubit/channels_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

// Reuse the fake from the cubit test rather than writing a second one.
import 'cubit/channels_cubit_test.dart' show FakeChannelReader, systemChannel;

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
}
