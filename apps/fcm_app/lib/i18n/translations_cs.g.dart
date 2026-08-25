///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:slang/generated.dart';
import 'translations.g.dart';

// Path: <root>
class TranslationsCs with BaseTranslations<AppLocale, Translations> implements Translations {
	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	TranslationsCs({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.cs,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <cs>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	@override dynamic operator[](String key) => $meta.getTranslation(key);

	late final TranslationsCs _root = this; // ignore: unused_field

	@override 
	TranslationsCs $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => TranslationsCs(meta: meta ?? this.$meta);

	// Translations
	@override late final _Translations$app$cs app = _Translations$app$cs._(_root);
	@override late final _Translations$language$cs language = _Translations$language$cs._(_root);
	@override late final _Translations$shell$cs shell = _Translations$shell$cs._(_root);
	@override late final _Translations$drawer$cs drawer = _Translations$drawer$cs._(_root);
	@override late final _Translations$inbox$cs inbox = _Translations$inbox$cs._(_root);
	@override late final _Translations$message_detail$cs message_detail = _Translations$message_detail$cs._(_root);
	@override late final _Translations$message_tile$cs message_tile = _Translations$message_tile$cs._(_root);
}

// Path: app
class _Translations$app$cs implements Translations$app$en {
	_Translations$app$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// MaterialApp title and drawer header; a product name, so the same in both
	@override String get title => 'FCM Sample';
}

// Path: language
class _Translations$language$cs implements Translations$language$en {
	_Translations$language$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// AppBar action tooltip for the language switcher
	@override String get tooltip => 'Jazyk';

	/// Language choice that follows the device
	@override String get system => 'Systém';

	/// Language choice; each language names itself
	@override String get english => 'English';

	/// Language choice; each language names itself
	@override String get czech => 'Čeština';
}

// Path: shell
class _Translations$shell$cs implements Translations$shell$en {
	_Translations$shell$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$shell$title$cs title = _Translations$shell$title$cs._(_root);
}

// Path: drawer
class _Translations$drawer$cs implements Translations$drawer$en {
	_Translations$drawer$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Drawer destination; shorter than the AppBar title
	@override String get inbox => 'Doručené';

	/// Drawer destination
	@override String get scenarios => 'Scénáře';

	/// Drawer destination
	@override String get sandbox => 'Sandbox';

	/// Drawer destination
	@override String get runs => 'Běhy';

	/// Drawer destination
	@override String get telemetry => 'Telemetrie';
}

// Path: inbox
class _Translations$inbox$cs implements Translations$inbox$en {
	_Translations$inbox$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Tile above the FCM token
	@override String get registration_token => 'Registrační token';

	/// Empty state
	@override String get empty => 'Zatím nedorazil žádný push.';

	@override String malformed_dropped({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${n} poškozený payload zahozen',
		few: '${n} poškozené payloady zahozeny',
		other: '${n} poškozených payloadů zahozeno',
	);
}

// Path: message_detail
class _Translations$message_detail$cs implements Translations$message_detail$en {
	_Translations$message_detail$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Detail line naming the action button that opened the app
	@override String opened_by_action({required Object label}) => 'Otevřeno akcí: ${label}';

	/// Detail line naming which surface the press came from
	@override String from({required Object from}) => 'z: ${from}';

	/// Detail line showing an inline reply
	@override String replied({required Object text}) => 'Odpovězeno: ${text}';

	/// Label above the send timestamp
	@override String get sent => 'Odesláno';

	/// Label above the message id
	@override String get payload_id => 'ID payloadu';

	/// Label above the data map
	@override String get extra_data => 'Extra data';

	/// Shown when the data map is empty
	@override String get no_extra_data => 'Žádné extra klíče.';
}

// Path: message_tile
class _Translations$message_tile$cs implements Translations$message_tile$en {
	_Translations$message_tile$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Stand-in headline for a message with an empty title
	@override String get no_title => '(bez titulku)';

	/// Tile subtitle when the message carries a data map
	@override String body_with_data({required Object body, required Object keys}) => '${body}\ndata: ${keys}';
}

// Path: shell.title
class _Translations$shell$title$cs implements Translations$shell$title$en {
	_Translations$shell$title$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// AppBar title for the inbox destination
	@override String get inbox => 'Doručené pushe';

	/// AppBar title
	@override String get scenarios => 'Scénáře';

	/// AppBar title; the product's own term
	@override String get sandbox => 'Sandbox';

	/// AppBar title
	@override String get runs => 'Běhy';

	/// AppBar title
	@override String get telemetry => 'Telemetrie';
}

/// The flat map containing all translations for locale <cs>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on TranslationsCs {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'FCM Sample',
			'language.tooltip' => 'Jazyk',
			'language.system' => 'Systém',
			'language.english' => 'English',
			'language.czech' => 'Čeština',
			'shell.title.inbox' => 'Doručené pushe',
			'shell.title.scenarios' => 'Scénáře',
			'shell.title.sandbox' => 'Sandbox',
			'shell.title.runs' => 'Běhy',
			'shell.title.telemetry' => 'Telemetrie',
			'drawer.inbox' => 'Doručené',
			'drawer.scenarios' => 'Scénáře',
			'drawer.sandbox' => 'Sandbox',
			'drawer.runs' => 'Běhy',
			'drawer.telemetry' => 'Telemetrie',
			'inbox.registration_token' => 'Registrační token',
			'inbox.empty' => 'Zatím nedorazil žádný push.',
			'inbox.malformed_dropped' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${n} poškozený payload zahozen', few: '${n} poškozené payloady zahozeny', other: '${n} poškozených payloadů zahozeno', ), 
			'message_detail.opened_by_action' => ({required Object label}) => 'Otevřeno akcí: ${label}',
			'message_detail.from' => ({required Object from}) => 'z: ${from}',
			'message_detail.replied' => ({required Object text}) => 'Odpovězeno: ${text}',
			'message_detail.sent' => 'Odesláno',
			'message_detail.payload_id' => 'ID payloadu',
			'message_detail.extra_data' => 'Extra data',
			'message_detail.no_extra_data' => 'Žádné extra klíče.',
			'message_tile.no_title' => '(bez titulku)',
			'message_tile.body_with_data' => ({required Object body, required Object keys}) => '${body}\ndata: ${keys}',
			_ => null,
		};
	}
}
