import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:fcm_app/domains/settings/data_sources/shared_preferences_locale_store.dart';
import 'package:fcm_app/i18n/translations.g.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('an unset preference means follow the system', () {
    expect(const SharedPreferencesLocaleStore().read(), completion(isNull));
  });

  test('a written locale comes back', () async {
    const store = SharedPreferencesLocaleStore();

    await store.write(AppLocale.cs);

    expect(await store.read(), AppLocale.cs);
  });

  test('writing null clears the override', () async {
    const store = SharedPreferencesLocaleStore();
    await store.write(AppLocale.cs);

    await store.write(null);

    expect(await store.read(), isNull);
  });

  test('an unsupported stored tag is ignored rather than trusted', () {
    // A tag can outlive the build that wrote it. Falling back to the system beats
    // handing slang a locale this build has no translations for.
    SharedPreferences.setMockInitialValues({localeKey: 'kl'});

    expect(const SharedPreferencesLocaleStore().read(), completion(isNull));
  });

  test('every supported locale round-trips through the store', () async {
    // Pinned against the generated list rather than the two locales spelled out
    // above: this is the test that would have caught `write` and `read` disagreeing
    // on how a locale is represented (languageCode vs. languageTag) the day a
    // locale carries a country or script code, and it keeps catching it without an
    // edit when a locale is added.
    const store = SharedPreferencesLocaleStore();

    for (final locale in AppLocale.values) {
      await store.write(locale);

      expect(await store.read(), locale);
    }
  });
}
