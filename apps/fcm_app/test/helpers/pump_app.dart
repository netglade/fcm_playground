import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fcm_app/i18n/translations.g.dart';

/// Pumps [child] under a `TranslationProvider`, in a pinned language.
///
/// Every widget test needs the provider now that widgets read `context.t`, and the
/// locale is pinned rather than inherited: a test asserting on English copy must not
/// start failing because the host is Czech.
///
/// `setLocaleSync` before pumping rather than a locale argument to the provider —
/// slang keeps the current locale in one place, and letting a test set it there is
/// what makes the global `t` agree with `context.t` inside the same test.
Future<void> pumpApp(
  WidgetTester tester,
  Widget child, {
  AppLocale locale = AppLocale.en,
}) {
  LocaleSettings.setLocaleSync(locale);

  return tester.pumpWidget(
    TranslationProvider(
      child: MaterialApp(home: Scaffold(body: child)),
    ),
  );
}
