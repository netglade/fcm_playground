import 'package:flutter_test/flutter_test.dart';

import 'package:fcm_app/i18n/translations.g.dart';

/// What the three `http_*` data sources depend on: the current language, reachable
/// with no widget tree and no priming of our own.
void main() {
  tearDown(() => LocaleSettings.setLocaleSync(AppLocale.en));

  test('the global t follows LocaleSettings', () {
    LocaleSettings.setLocaleSync(AppLocale.cs);
    expect(t.api.item.event, 'událost');

    LocaleSettings.setLocaleSync(AppLocale.en);
    expect(t.api.item.event, 'an event');
  });

  // Czech has three cardinal plural forms where English has two — the CLDR
  // grammar that justified slang over a hand-rolled generator in the first
  // place. Nothing pinned any of the three Czech branches of any of the app's
  // three-form plurals before this: swapping the `.one` and `.few` Czech cells
  // of `selection_bar.selected_count` in the CSV and regenerating left every
  // test in the suite, including `melos run ci`, green.
  group('the app\'s three-form Czech plurals resolve every branch', () {
    setUp(() => LocaleSettings.setLocaleSync(AppLocale.cs));

    test('selection_bar.selected_count', () {
      expect(
        t.selection_bar.selected_count(n: 1),
        '1 vybrán',
        reason:
            'CLDR "one": masculine singular passive participle, the form a '
            '.one/.few swap in the CSV would put "vybrány" in instead',
      );
      expect(
        t.selection_bar.selected_count(n: 3),
        '3 vybrány',
        reason:
            'CLDR "few" (2-4): masculine-inanimate/feminine plural, the '
            'form English has no counterpart for and the whole reason a '
            'plural-aware format was required',
      );
      expect(
        t.selection_bar.selected_count(n: 5),
        '5 vybráno',
        reason: 'CLDR "other" (0, 5+): the genitive-triggering neuter form',
      );
    });

    test('inbox.malformed_dropped', () {
      expect(
        t.inbox.malformed_dropped(n: 1),
        '1 poškozený payload zahozen',
        reason: 'CLDR "one" branch of the malformed-payload banner',
      );
      expect(
        t.inbox.malformed_dropped(n: 3),
        '3 poškozené payloady zahozeny',
        reason: 'CLDR "few" branch of the malformed-payload banner',
      );
      expect(
        t.inbox.malformed_dropped(n: 5),
        '5 poškozených payloadů zahozeno',
        reason: 'CLDR "other" branch of the malformed-payload banner',
      );
    });

    test('send_result.scheduled', () {
      expect(
        t.send_result.scheduled(n: 1, runId: 'run-1'),
        '✓ Naplánováno · běh run-1 · 1 zpráva · zatím nic neodesláno',
        reason: 'CLDR "one" branch of the schedule result card',
      );
      expect(
        t.send_result.scheduled(n: 3, runId: 'run-1'),
        '✓ Naplánováno · běh run-1 · 3 zprávy · zatím nic neodesláno',
        reason: 'CLDR "few" branch of the schedule result card',
      );
      expect(
        t.send_result.scheduled(n: 5, runId: 'run-1'),
        '✓ Naplánováno · běh run-1 · 5 zpráv · zatím nic neodesláno',
        reason: 'CLDR "other" branch of the schedule result card',
      );
    });
  });
}
