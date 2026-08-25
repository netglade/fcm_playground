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
}
