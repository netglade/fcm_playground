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
	@override late final _Translations$reply$cs reply = _Translations$reply$cs._(_root);
	@override late final _Translations$message_tile$cs message_tile = _Translations$message_tile$cs._(_root);
	@override late final _Translations$scenarios$cs scenarios = _Translations$scenarios$cs._(_root);
	@override late final _Translations$scenario_card$cs scenario_card = _Translations$scenario_card$cs._(_root);
	@override late final _Translations$common$cs common = _Translations$common$cs._(_root);
	@override late final _Translations$selection_bar$cs selection_bar = _Translations$selection_bar$cs._(_root);
	@override late final _Translations$runs$cs runs = _Translations$runs$cs._(_root);
	@override late final _Translations$run_timeline$cs run_timeline = _Translations$run_timeline$cs._(_root);
	@override late final _Translations$run_tile$cs run_tile = _Translations$run_tile$cs._(_root);
	@override late final _Translations$run_item$cs run_item = _Translations$run_item$cs._(_root);
	@override late final _Translations$sandbox$cs sandbox = _Translations$sandbox$cs._(_root);
	@override late final _Translations$send$cs send = _Translations$send$cs._(_root);
	@override late final _Translations$send_target$cs send_target = _Translations$send_target$cs._(_root);
	@override late final _Translations$schedule_sheet$cs schedule_sheet = _Translations$schedule_sheet$cs._(_root);
	@override late final _Translations$preset_chip$cs preset_chip = _Translations$preset_chip$cs._(_root);
	@override late final _Translations$not_received$cs not_received = _Translations$not_received$cs._(_root);
	@override late final _Translations$send_result$cs send_result = _Translations$send_result$cs._(_root);
	@override late final _Translations$countdown$cs countdown = _Translations$countdown$cs._(_root);
	@override late final _Translations$telemetry$cs telemetry = _Translations$telemetry$cs._(_root);
	@override late final _Translations$api$cs api = _Translations$api$cs._(_root);
	@override late final _Translations$scenario$cs scenario = _Translations$scenario$cs._(_root);
	@override late final _Translations$scenario_group$cs scenario_group = _Translations$scenario_group$cs._(_root);
	@override late final _Translations$scenario_need$cs scenario_need = _Translations$scenario_need$cs._(_root);
	@override late final _Translations$form_section$cs form_section = _Translations$form_section$cs._(_root);
	@override late final _Translations$form_field$cs form_field = _Translations$form_field$cs._(_root);
	@override late final _Translations$channels$cs channels = _Translations$channels$cs._(_root);
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

	/// Drawer destination
	@override String get channels => 'Kanály';
}

// Path: inbox
class _Translations$inbox$cs implements Translations$inbox$en {
	_Translations$inbox$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Tile above the FCM token
	@override String get registration_token => 'Registrační token';

	/// Button that empties the notification tray, leaving the inbox list untouched
	@override String get clear_notifications => 'Vymazat notifikace';

	/// Empty state
	@override String get empty => 'Zatím nedorazil žádný push.';

	@override String malformed_dropped({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${n} poškozený payload zahozen',
		few: '${n} poškozené payloady zahozeny',
		other: '${n} poškozených payloadů zahozeno',
	);

	/// Banner shown when the push store fails to restore its history on launch
	@override String setup_error({required Object error}) => 'Uložené pushe se nepodařilo načíst: ${error}';
}

// Path: message_detail
class _Translations$message_detail$cs implements Translations$message_detail$en {
	_Translations$message_detail$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Detail line naming the action button that opened the app
	@override String opened_by_action({required Object label}) => 'Otevřeno akcí: ${label}';

	/// Detail line naming which surface the press came from
	@override String from({required Object from}) => 'Zdroj: ${from}';

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

// Path: reply
class _Translations$reply$cs implements Translations$reply$en {
	_Translations$reply$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of the notification shown while an inline reply is in flight
	@override String get sending => 'Odesílám…';

	/// Title of the notification once the reply went out
	@override String get sent => 'Odesláno';

	/// Title of the notification when the reply failed
	@override String get not_sent => 'Neodesláno';
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

// Path: scenarios
class _Translations$scenarios$cs implements Translations$scenarios$en {
	_Translations$scenarios$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Banner when the device has not registered
	@override String get no_token => 'Zatím není registrační token, takže není kam posílat. Otevři Doručené, až se aplikace zaregistruje.';
}

// Path: scenario_card
class _Translations$scenario_card$cs implements Translations$scenario_card$en {
	_Translations$scenario_card$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Chip on a scenario whose needs are unmet
	@override String get needs_work => 'potřebuje práci';
}

// Path: common
class _Translations$common$cs implements Translations$common$en {
	_Translations$common$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Badge on a scenario that only means something with the app killed; used on the card and in the Sandbox
	@override String get needs_killed_app => 'Vyžaduje zabitou aplikaci';

	/// Dismisses a sheet or leaves selection mode; used in several places
	@override String get cancel => 'Zrušit';

	/// Opens the schedule sheet; used on the selection bar and the send footer
	@override String get schedule_ellipsis => 'Naplánovat…';

	/// Refresh action; used on the run timeline and on Telemetry
	@override String get reload => 'Znovu načíst';

	/// Stands in for a trace with no scenario id; used on the matrix and the trace card
	@override String get no_scenario => 'bez scénáře';

	/// Stands in for a trace with no device id
	@override String get no_device_yet => 'zatím žádné zařízení';
}

// Path: selection_bar
class _Translations$selection_bar$cs implements Translations$selection_bar$en {
	_Translations$selection_bar$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Button that enters multi-select
	@override String get select_for_batch => 'Vybrat do dávky';

	@override String selected_count({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${n} vybrán',
		few: '${n} vybrány',
		other: '${n} vybráno',
	);
}

// Path: runs
class _Translations$runs$cs implements Translations$runs$en {
	_Translations$runs$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Empty state on the Runs page
	@override String get empty => 'Zatím nic naplánováno. Vyber scénář a zvol Naplánovat.';
}

// Path: run_timeline
class _Translations$run_timeline$cs implements Translations$run_timeline$en {
	_Translations$run_timeline$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// AppBar title of a single run's timeline
	@override String get title => 'Běh';
}

// Path: run_tile
class _Translations$run_tile$cs implements Translations$run_tile$en {
	_Translations$run_tile$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override String sends({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '${n} odeslání',
		other: '${n} odeslání',
	);

	/// When the run's next message goes out
	@override String next_due({required Object time}) => 'další v ${time}';
}

// Path: run_item
class _Translations$run_item$cs implements Translations$run_item$en {
	_Translations$run_item$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Stands in for a run item with no scenario id
	@override String get composed_by_hand => '(složeno ručně)';

	/// When one run item goes out
	@override String due({required Object time}) => 'v ${time}';

	/// Empty state for a run item's events
	@override String get nothing_recorded => 'Zatím nic nezaznamenáno.';
}

// Path: sandbox
class _Translations$sandbox$cs implements Translations$sandbox$en {
	_Translations$sandbox$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Switch that asks FCM to validate without delivering
	@override String get validate_only => 'Jen validovat';

	/// Banner listing what a scenario is missing; under sandbox.* rather than scenario_needs.* so it cannot be confused with the scenario_need.* labels it interpolates
	@override String needs_banner({required Object needs}) => 'Potřebuje ${needs}. Push se pošle, ale tento scénář se tady nedá pozorovat.';

	@override late final _Translations$sandbox$send_blocked$cs send_blocked = _Translations$sandbox$send_blocked$cs._(_root);
}

// Path: send
class _Translations$send$cs implements Translations$send$en {
	_Translations$send$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Send button label
	@override String get to_this_device => 'Poslat na toto zařízení';

	/// Send button label
	@override String get to_that_token => 'Poslat na ten token';

	/// Send button label
	@override String to_topic({required Object topic}) => 'Poslat do tématu „${topic}“';

	/// Send button label
	@override String get to_condition => 'Poslat na podmínku';

	/// Send button label
	@override String get to_every_device => 'Poslat na všechna zařízení';
}

// Path: send_target
class _Translations$send_target$cs implements Translations$send_target$en {
	_Translations$send_target$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Label of the delivery-target dropdown
	@override String get label => 'Poslat na';

	/// Delivery-target choice
	@override String get this_device => 'Toto zařízení';

	/// Delivery-target choice; the FCM term
	@override String get token => 'Token';

	/// Delivery-target choice
	@override String get topic => 'Téma';

	/// Delivery-target choice
	@override String get condition => 'Podmínka';

	/// Delivery-target choice
	@override String get all_devices => 'Všechna zařízení';

	/// Warning under the all-devices choice
	@override String get all_devices_warning => 'Odeslání na všechna zařízení potřebuje registr tokenů, který API zatím nemá, takže bude odmítnuto.';
}

// Path: schedule_sheet
class _Translations$schedule_sheet$cs implements Translations$schedule_sheet$en {
	_Translations$schedule_sheet$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Section heading in the schedule sheet
	@override String get delay => 'Zpoždění';

	/// Section heading in the schedule sheet
	@override String get spacing => 'Rozestup';

	/// Help text under Spacing
	@override String get spacing_help => 'Přičte se za každou zprávu po první, takže dávka dorazí rozprostřená, ne jako jeden shluk.';

	/// Confirm button in the schedule sheet; no ellipsis because this one acts
	@override String get confirm => 'Naplánovat';
}

// Path: preset_chip
class _Translations$preset_chip$cs implements Translations$preset_chip$en {
	_Translations$preset_chip$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Delay preset chip
	@override String seconds({required Object value}) => '${value} s';
}

// Path: not_received
class _Translations$not_received$cs implements Translations$not_received$en {
	_Translations$not_received$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Button reporting a push that did not show up
	@override String get button => 'Nikdy nedorazilo';

	/// The same button once pressed; echoes the unpressed label deliberately
	@override String get reported => 'Nahlášeno: nikdy nedorazilo';
}

// Path: send_result
class _Translations$send_result$cs implements Translations$send_result$en {
	_Translations$send_result$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Result card after a validate-only send
	@override String validated({required Object messageId, required Object traceId}) => '✓ Zvalidováno · zpráva ${messageId} · trace ${traceId} · payload byl zvalidován, ne odeslán';

	/// Result card after a send
	@override String sent({required Object messageId, required Object traceId}) => '✓ Odesláno · zpráva ${messageId} · trace ${traceId} · za chvíli by se mělo objevit v Doručených';

	@override String scheduled({required num n, required Object runId}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n,
		one: '✓ Naplánováno · běh ${runId} · ${n} zpráva · zatím nic neodesláno',
		few: '✓ Naplánováno · běh ${runId} · ${n} zprávy · zatím nic neodesláno',
		other: '✓ Naplánováno · běh ${runId} · ${n} zpráv · zatím nic neodesláno',
	);
}

// Path: countdown
class _Translations$countdown$cs implements Translations$countdown$en {
	_Translations$countdown$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Unit under the countdown's number
	@override String get seconds => 'sekund';

	/// Instruction on the countdown screen
	@override String get swipe_away => 'Teď odsuň aplikaci z posledních. Push je už naplánovaný na serveru, takže dorazí, ať aplikace běží nebo ne.';

	/// Explains why the button dims rather than switches off
	@override String get dim_note => 'Obyčejná aplikace nedokáže vypnout displej — dovede ho pouze ztlumit a přestat mu bránit v uspání, takže systém časem vypne sám.';

	/// Button on the countdown screen
	@override String get dim_screen => 'Ztmavit displej';

	/// Opens the OS battery settings
	@override String get battery_settings => 'Nastavení baterie';
}

// Path: telemetry
class _Translations$telemetry$cs implements Translations$telemetry$en {
	_Translations$telemetry$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$telemetry$tab$cs tab = _Translations$telemetry$tab$cs._(_root);
	@override late final _Translations$telemetry$events$cs events = _Translations$telemetry$events$cs._(_root);
	@override late final _Translations$telemetry$event_row$cs event_row = _Translations$telemetry$event_row$cs._(_root);
	@override late final _Translations$telemetry$latency$cs latency = _Translations$telemetry$latency$cs._(_root);
}

// Path: api
class _Translations$api$cs implements Translations$api$en {
	_Translations$api$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Shown when the local API is not answering; identical in all three data sources
	@override String unreachable({required Object baseUrl, required Object error}) => 'Nepodařilo se spojit s ${baseUrl} — běží API?\nNa fyzickém zařízení spusť: adb reverse tcp:8080 tcp:8080\n(${error})';

	/// Shown for a non-200; the body is the server's own text and stays as sent
	@override String answered_status({required Object status, required Object body}) => 'API odpovědělo ${status}: ${body}';

	/// A 200 whose body is not JSON
	@override String answered_unreadable({required Object error}) => 'API odpovědělo 200 něčím nečitelným: ${error}';

	/// A 200 whose body is not JSON
	@override String answered_not_json({required Object error}) => 'API odpovědělo 200 něčím, co není JSON: ${error}';

	/// A 200 whose body parses but is the wrong shape
	@override String answered_wrong_shape({required Object type}) => 'API odpovědělo 200 typem ${type}, kde se čekal seznam.';

	/// A 200 whose body parses but is the wrong shape
	@override String answered_wrong_shape_runs({required Object type}) => 'API odpovědělo 200 typem ${type}, kde se čekal seznam běhů.';

	/// A 200 carrying an item this build's model rejects
	@override String answered_unreadable_item({required Object what, required Object error}) => 'API odpovědělo 200 s ${what}, co tento build neumí přečíst: ${error}';

	@override late final _Translations$api$item$cs item = _Translations$api$item$cs._(_root);

	/// A decoded JSON value used as a map that is not one. All THREE throw sites take this key, http_notification_sender.dart included: its local `on FormatException` does not discard the message, it forwards error.message into api.answered_unreadable, so a bare literal there would surface as an English fragment inside a Czech sentence
	@override String expected_object({required Object type}) => 'Byl přijat typ ${type}, kde se čekal JSON objekt.';
}

// Path: scenario
class _Translations$scenario$cs implements Translations$scenario$en {
	_Translations$scenario$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$scenario$a1_notification_only$cs a1_notification_only = _Translations$scenario$a1_notification_only$cs._(_root);
	@override late final _Translations$scenario$a2_data_only$cs a2_data_only = _Translations$scenario$a2_data_only$cs._(_root);
	@override late final _Translations$scenario$a3_hybrid$cs a3_hybrid = _Translations$scenario$a3_hybrid$cs._(_root);
	@override late final _Translations$scenario$a4_no_display$cs a4_no_display = _Translations$scenario$a4_no_display$cs._(_root);
	@override late final _Translations$scenario$b1_foreground$cs b1_foreground = _Translations$scenario$b1_foreground$cs._(_root);
	@override late final _Translations$scenario$b2_background$cs b2_background = _Translations$scenario$b2_background$cs._(_root);
	@override late final _Translations$scenario$b3_killed$cs b3_killed = _Translations$scenario$b3_killed$cs._(_root);
	@override late final _Translations$scenario$b4_after_reboot$cs b4_after_reboot = _Translations$scenario$b4_after_reboot$cs._(_root);
	@override late final _Translations$scenario$b5_force_stopped$cs b5_force_stopped = _Translations$scenario$b5_force_stopped$cs._(_root);
	@override late final _Translations$scenario$b6_token_refresh$cs b6_token_refresh = _Translations$scenario$b6_token_refresh$cs._(_root);
	@override late final _Translations$scenario$c1_priority_high$cs c1_priority_high = _Translations$scenario$c1_priority_high$cs._(_root);
	@override late final _Translations$scenario$c2_priority_normal$cs c2_priority_normal = _Translations$scenario$c2_priority_normal$cs._(_root);
	@override late final _Translations$scenario$c3_ttl_zero$cs c3_ttl_zero = _Translations$scenario$c3_ttl_zero$cs._(_root);
	@override late final _Translations$scenario$c4_ttl_long$cs c4_ttl_long = _Translations$scenario$c4_ttl_long$cs._(_root);
	@override late final _Translations$scenario$c5_collapse_key$cs c5_collapse_key = _Translations$scenario$c5_collapse_key$cs._(_root);
	@override late final _Translations$scenario$c6_doze_test$cs c6_doze_test = _Translations$scenario$c6_doze_test$cs._(_root);
	@override late final _Translations$scenario$c7_standby_bucket$cs c7_standby_bucket = _Translations$scenario$c7_standby_bucket$cs._(_root);
	@override late final _Translations$scenario$d1_importance_high$cs d1_importance_high = _Translations$scenario$d1_importance_high$cs._(_root);
	@override late final _Translations$scenario$d2_importance_default$cs d2_importance_default = _Translations$scenario$d2_importance_default$cs._(_root);
	@override late final _Translations$scenario$d3_importance_low$cs d3_importance_low = _Translations$scenario$d3_importance_low$cs._(_root);
	@override late final _Translations$scenario$d4_importance_min$cs d4_importance_min = _Translations$scenario$d4_importance_min$cs._(_root);
	@override late final _Translations$scenario$d5_custom_sound$cs d5_custom_sound = _Translations$scenario$d5_custom_sound$cs._(_root);
	@override late final _Translations$scenario$d6_vibration_pattern$cs d6_vibration_pattern = _Translations$scenario$d6_vibration_pattern$cs._(_root);
	@override late final _Translations$scenario$d7_channel_immutability$cs d7_channel_immutability = _Translations$scenario$d7_channel_immutability$cs._(_root);
	@override late final _Translations$scenario$d8_channel_group$cs d8_channel_group = _Translations$scenario$d8_channel_group$cs._(_root);
	@override late final _Translations$scenario$e1_long_text$cs e1_long_text = _Translations$scenario$e1_long_text$cs._(_root);
	@override late final _Translations$scenario$e2_image_remote$cs e2_image_remote = _Translations$scenario$e2_image_remote$cs._(_root);
	@override late final _Translations$scenario$e3_image_local$cs e3_image_local = _Translations$scenario$e3_image_local$cs._(_root);
	@override late final _Translations$scenario$e4_image_huge$cs e4_image_huge = _Translations$scenario$e4_image_huge$cs._(_root);
	@override late final _Translations$scenario$e5_image_404$cs e5_image_404 = _Translations$scenario$e5_image_404$cs._(_root);
	@override late final _Translations$scenario$e6_large_icon$cs e6_large_icon = _Translations$scenario$e6_large_icon$cs._(_root);
	@override late final _Translations$scenario$e7_inbox_style$cs e7_inbox_style = _Translations$scenario$e7_inbox_style$cs._(_root);
	@override late final _Translations$scenario$e8_messaging_style$cs e8_messaging_style = _Translations$scenario$e8_messaging_style$cs._(_root);
	@override late final _Translations$scenario$e9_progress$cs e9_progress = _Translations$scenario$e9_progress$cs._(_root);
	@override late final _Translations$scenario$e10_color_and_icon$cs e10_color_and_icon = _Translations$scenario$e10_color_and_icon$cs._(_root);
	@override late final _Translations$scenario$e11_emoji_rtl$cs e11_emoji_rtl = _Translations$scenario$e11_emoji_rtl$cs._(_root);
	@override late final _Translations$scenario$f1_actions$cs f1_actions = _Translations$scenario$f1_actions$cs._(_root);
	@override late final _Translations$scenario$f2_inline_reply$cs f2_inline_reply = _Translations$scenario$f2_inline_reply$cs._(_root);
	@override late final _Translations$scenario$f3_deeplink_foreground$cs f3_deeplink_foreground = _Translations$scenario$f3_deeplink_foreground$cs._(_root);
	@override late final _Translations$scenario$f4_deeplink_background$cs f4_deeplink_background = _Translations$scenario$f4_deeplink_background$cs._(_root);
	@override late final _Translations$scenario$f5_deeplink_killed$cs f5_deeplink_killed = _Translations$scenario$f5_deeplink_killed$cs._(_root);
	@override late final _Translations$scenario$f6_delete_intent$cs f6_delete_intent = _Translations$scenario$f6_delete_intent$cs._(_root);
	@override late final _Translations$scenario$f7_ongoing$cs f7_ongoing = _Translations$scenario$f7_ongoing$cs._(_root);
	@override late final _Translations$scenario$f8_full_screen_intent$cs f8_full_screen_intent = _Translations$scenario$f8_full_screen_intent$cs._(_root);
	@override late final _Translations$scenario$f9_trampoline$cs f9_trampoline = _Translations$scenario$f9_trampoline$cs._(_root);
	@override late final _Translations$scenario$g1_group_summary$cs g1_group_summary = _Translations$scenario$g1_group_summary$cs._(_root);
	@override late final _Translations$scenario$g2_update_same_id$cs g2_update_same_id = _Translations$scenario$g2_update_same_id$cs._(_root);
	@override late final _Translations$scenario$g3_badge$cs g3_badge = _Translations$scenario$g3_badge$cs._(_root);
	@override late final _Translations$scenario$g4_badge_ios$cs g4_badge_ios = _Translations$scenario$g4_badge_ios$cs._(_root);
	@override late final _Translations$scenario$h1_dnd_bypass$cs h1_dnd_bypass = _Translations$scenario$h1_dnd_bypass$cs._(_root);
	@override late final _Translations$scenario$h2_category_alarm$cs h2_category_alarm = _Translations$scenario$h2_category_alarm$cs._(_root);
	@override late final _Translations$scenario$h3_ios_time_sensitive$cs h3_ios_time_sensitive = _Translations$scenario$h3_ios_time_sensitive$cs._(_root);
	@override late final _Translations$scenario$h4_ios_critical$cs h4_ios_critical = _Translations$scenario$h4_ios_critical$cs._(_root);
	@override late final _Translations$scenario$h5_ios_passive$cs h5_ios_passive = _Translations$scenario$h5_ios_passive$cs._(_root);
	@override late final _Translations$scenario$i1_silent_no_sound$cs i1_silent_no_sound = _Translations$scenario$i1_silent_no_sound$cs._(_root);
	@override late final _Translations$scenario$i2_silent_data_sync$cs i2_silent_data_sync = _Translations$scenario$i2_silent_data_sync$cs._(_root);
	@override late final _Translations$scenario$i3_ios_content_available$cs i3_ios_content_available = _Translations$scenario$i3_ios_content_available$cs._(_root);
	@override late final _Translations$scenario$i4_burst$cs i4_burst = _Translations$scenario$i4_burst$cs._(_root);
	@override late final _Translations$scenario$j1_topic$cs j1_topic = _Translations$scenario$j1_topic$cs._(_root);
	@override late final _Translations$scenario$j2_condition$cs j2_condition = _Translations$scenario$j2_condition$cs._(_root);
	@override late final _Translations$scenario$j3_multicast$cs j3_multicast = _Translations$scenario$j3_multicast$cs._(_root);
	@override late final _Translations$scenario$k1_payload_oversize$cs k1_payload_oversize = _Translations$scenario$k1_payload_oversize$cs._(_root);
	@override late final _Translations$scenario$k2_invalid_token$cs k2_invalid_token = _Translations$scenario$k2_invalid_token$cs._(_root);
	@override late final _Translations$scenario$k3_permission_denied$cs k3_permission_denied = _Translations$scenario$k3_permission_denied$cs._(_root);
	@override late final _Translations$scenario$k4_notifications_disabled$cs k4_notifications_disabled = _Translations$scenario$k4_notifications_disabled$cs._(_root);
	@override late final _Translations$scenario$k5_battery_restricted$cs k5_battery_restricted = _Translations$scenario$k5_battery_restricted$cs._(_root);
}

// Path: scenario_group
class _Translations$scenario_group$cs implements Translations$scenario_group$en {
	_Translations$scenario_group$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Display name of scenario group A
	@override String get a => 'A — Základní doručení';

	/// Display name of scenario group B
	@override String get b => 'B — Stavy aplikace';

	/// Display name of scenario group C
	@override String get c => 'C — Priorita a doručovací okno';

	/// Display name of scenario group D
	@override String get d => 'D — Kanály a důležitost';

	/// Display name of scenario group E
	@override String get e => 'E — Vzhled';

	/// Display name of scenario group F
	@override String get f => 'F — Interakce';

	/// Display name of scenario group G
	@override String get g => 'G — Skupiny, odznak, aktualizace';

	/// Display name of scenario group H
	@override String get h => 'H — Rušivost a priorita';

	/// Display name of scenario group I
	@override String get i => 'I — Tiché a datové';

	/// Display name of scenario group J
	@override String get j => 'J — Cílení';

	/// Display name of scenario group K
	@override String get k => 'K — Krajní případy a chyby';
}

// Path: scenario_need
class _Translations$scenario_need$cs implements Translations$scenario_need$en {
	_Translations$scenario_need$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Label for the badge scenario need
	@override String get badge => 'odznak na ikoně aplikace';

	/// Label for the targeting scenario need
	@override String get targeting => 'registr zařízení';

	@override String get manual_step => 'manuální krok';
	@override String get external_approval => 'externí schválení';

	/// Label for the nativeCode scenario need
	@override String get native_code => 'nativní kód';
}

// Path: form_section
class _Translations$form_section$cs implements Translations$form_section$en {
	_Translations$form_section$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Subtitle of the outermost payload-form section
	@override String get message => 'Zpráva FCM v1 bez cíle doručení, který nastavuje server.';

	/// Subtitle of the cross-platform notification section
	@override String get notification => 'Zobrazuje se na všech platformách, pokud ho nepřebije blok konkrétní platformy.';

	/// Subtitle of the android section
	@override String get android => 'Možnosti doručení a zobrazení pro Android.';

	/// Subtitle of the android.notification section
	@override String get android_notification => 'Vše, co umí panel oznámení Androidu navíc oproti sdílenému bloku.';

	/// Subtitle of the apns section
	@override String get apns => 'Možnosti doručení a zobrazení pro iOS a macOS.';

	/// Subtitle of the APNs fcm_options section
	@override String get apns_fcm_options => 'Možnosti doručení, včetně obrázku, který přijímá jen APNs.';

	/// Subtitle of the webpush section
	@override String get webpush => 'Možnosti doručení a zobrazení pro prohlížeče.';

	/// Subtitle of the WebPush fcm_options section
	@override String get webpush_fcm_options => 'Možnosti doručení, včetně odkazu, který se otevře po kliknutí.';

	/// Subtitle of the platform-independent fcm_options section
	@override String get fcm_options => 'Možnosti doručení, které FCM uplatňuje na všech platformách.';

	/// Subtitle of the light_settings section
	@override String get light_settings => 'Jakmile je tento blok přítomen, FCM vyžaduje všechna jeho pole.';
}

// Path: form_field
class _Translations$form_field$cs implements Translations$form_field$en {
	_Translations$form_field$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Icon-button tooltip that deletes one row of a string list or map editor; shared by both editors, so one key covers both
	@override String get remove_row => 'Odebrat tento řádek';

	/// Button that appends a new empty row to a string list or map editor; shared by both editors, so one key covers both
	@override String get add_row => 'Přidat';

	/// Dropdown entry standing in for an omitted optional enum field
	@override String get not_set => 'Nenastaveno';

	/// Subtitle under a tristate checkbox when the underlying FCM field is left out of the payload
	@override String get not_sent => 'Neodesláno';
}

// Path: channels
class _Translations$channels$cs implements Translations$channels$en {
	_Translations$channels$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$channels$fcm_sample_high$cs fcm_sample_high = _Translations$channels$fcm_sample_high$cs._(_root);
	@override late final _Translations$channels$importance_high$cs importance_high = _Translations$channels$importance_high$cs._(_root);
	@override late final _Translations$channels$importance_default$cs importance_default = _Translations$channels$importance_default$cs._(_root);
	@override late final _Translations$channels$importance_low$cs importance_low = _Translations$channels$importance_low$cs._(_root);
	@override late final _Translations$channels$importance_min$cs importance_min = _Translations$channels$importance_min$cs._(_root);
	@override late final _Translations$channels$custom_sound$cs custom_sound = _Translations$channels$custom_sound$cs._(_root);
	@override late final _Translations$channels$vibration_pattern$cs vibration_pattern = _Translations$channels$vibration_pattern$cs._(_root);
	@override late final _Translations$channels$chat_v1$cs chat_v1 = _Translations$channels$chat_v1$cs._(_root);
	@override late final _Translations$channels$chat_v2$cs chat_v2 = _Translations$channels$chat_v2$cs._(_root);
	@override late final _Translations$channels$dnd_bypass$cs dnd_bypass = _Translations$channels$dnd_bypass$cs._(_root);
	@override late final _Translations$channels$alarms$cs alarms = _Translations$channels$alarms$cs._(_root);
	@override late final _Translations$channels$group$cs group = _Translations$channels$group$cs._(_root);

	/// AppBar title on the Channels page
	@override String get title => 'Kanály oznámení';

	/// Column heading: what the app asked Android for
	@override String get requested => 'Vyžádáno';

	/// Column heading: what Android answered
	@override String get reported => 'Hlášeno systémem';

	/// Shown when the system holds no channel with this id
	@override String get not_registered => 'Neregistrováno';

	/// Row label on a channel card
	@override String get importance => 'Důležitost';

	/// Row label on a channel card
	@override String get sound => 'Zvuk';

	/// Shown for a reported sound that is the platform default rather than something this app requested
	@override String get default_sound => 'Výchozí';

	/// Row label on a channel card
	@override String get vibration => 'Vibrace';

	/// Row label on a channel card
	@override String get bypass_dnd => 'Obchází Nerušit';

	/// Row label on a channel card; not channels.group.chat.name, which already exists as a nested key for the group heading
	@override String get group_label => 'Skupina';

	/// Row label on a channel card
	@override String get badge => 'Zobrazuje odznak';

	/// Button on chat_v1; performs d7 by asking Android to change a frozen importance
	@override String get try_lower => 'Zkusit snížit';

	/// Explains what the d7 button does; also warns that pressing it cancels the notification currently shown for this channel
	@override String get immutability_hint => 'Důležitost se zmrazí při vzniku kanálu. Zmáčkni a sleduj, že se hlášená hodnota nehne — stisknutím se ale zruší i oznámení, které pro tento kanál právě visí v liště.';

	/// AppBar action on the Channels page
	@override String get refresh => 'Načíst znovu';
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

// Path: sandbox.send_blocked
class _Translations$sandbox$send_blocked$cs implements Translations$sandbox$send_blocked$en {
	_Translations$sandbox$send_blocked$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Reason Send is disabled: no delivery target is chosen
	@override String get no_target => 'Vyplň cíl doručení, nebo se přepni zpět na toto zařízení.';

	/// Reason Send is disabled: this device has not registered yet; shares its Czech clause with scenarios.no_token, whose English carries one more sentence
	@override String get no_token => 'Zatím není registrační token, takže není kam posílat.';

	/// Reason Send is disabled while this page's own send is in flight; kept apart from reply.sending, which titles a background notification for an unrelated send
	@override String get sending => 'Odesílám…';

	/// Reason Send is disabled: the payload form has an invalid field
	@override String get invalid_field => 'Některé pole je neplatné. Které, poznáš podle sekcí s ikonou chyby.';
}

// Path: telemetry.tab
class _Translations$telemetry$tab$cs implements Translations$telemetry$tab$en {
	_Translations$telemetry$tab$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Tab on the Telemetry page
	@override String get events => 'Události';

	/// Tab on the Telemetry page
	@override String get latency => 'Latence';
}

// Path: telemetry.events
class _Translations$telemetry$events$cs implements Translations$telemetry$events$en {
	_Translations$telemetry$events$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Empty state on the Events tab
	@override String get empty => 'Zatím nic nezaznamenáno. Pošli push ze Sandboxu a načti znovu.';
}

// Path: telemetry.event_row
class _Translations$telemetry$event_row$cs implements Translations$telemetry$event_row$en {
	_Translations$telemetry$event_row$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Caveat appended to a stamp taken before the request was handled
	@override String get request_received => ' · (požadavek přijat)';
}

// Path: telemetry.latency
class _Translations$telemetry$latency$cs implements Translations$telemetry$latency$en {
	_Translations$telemetry$latency$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Empty state on the Latency tab
	@override String get empty => 'Zatím žádná měření. Řádek potřebuje odeslání i doručení pro stejný trace.';

	/// Column header on the latency table
	@override String get scenario_column => 'scénář';

	/// Footnote under the latency table
	@override String get footnote => '`sent` je okamžik, kdy API dostalo požadavek, ne kdy odpovědělo FCM, takže každé číslo výše zahrnuje i dobu volání FCM.';
}

// Path: api.item
class _Translations$api$item$cs implements Translations$api$item$en {
	_Translations$api$item$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Names the item kind in api.answered_unreadable_item
	@override String get event => 'událost';

	/// Names the item kind in api.answered_unreadable_item
	@override String get latency_row => 'řádek latence';
}

// Path: scenario.a1_notification_only
class _Translations$scenario$a1_notification_only$cs implements Translations$scenario$a1_notification_only$en {
	_Translations$scenario$a1_notification_only$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario a1_notification_only
	@override String get title => 'Payload jen s notification';

	/// Description of scenario a1_notification_only
	@override String get description => 'Sleduj, která vrstva ho vykreslila — systém, když je aplikace na pozadí, aplikace, když je na popředí — a jak vyjdou ikona a barva zvýraznění.';
}

// Path: scenario.a2_data_only
class _Translations$scenario$a2_data_only$cs implements Translations$scenario$a2_data_only$en {
	_Translations$scenario$a2_data_only$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario a2_data_only
	@override String get title => 'Payload jen s daty, vykreslený lokálně';

	/// Description of scenario a2_data_only
	@override String get description => 'Tohle nevykreslí nic jiného než aplikace. Sleduj, jestli push dorazí i se zabitou aplikací — přesně pro tenhle případ data-only doručení existuje.';

	/// Expectation caveat for scenario a2_data_only
	@override String get expectation => 'Na iOS potřebuje data-only push content-available a je omezovaný (throttling); viz i3_ios_content_available.';
}

// Path: scenario.a3_hybrid
class _Translations$scenario$a3_hybrid$cs implements Translations$scenario$a3_hybrid$en {
	_Translations$scenario$a3_hybrid$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario a3_hybrid
	@override String get title => 'notification a data společně';

	/// Description of scenario a3_hybrid
	@override String get description => 'Běžný tvar v produkci. Sleduj, jestli data mapa dorazí do handleru po tapnutí — přesně tam si deep linky berou svoje argumenty.';
}

// Path: scenario.a4_no_display
class _Translations$scenario$a4_no_display$cs implements Translations$scenario$a4_no_display$en {
	_Translations$scenario$a4_no_display$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario a4_no_display
	@override String get title => 'Data zalogovaná tiše, vykreslení prázdné';

	/// Description of scenario a4_no_display
	@override String get description => 'Tichá synchronizace: handler se spustí a zapíše řádek do logu. Banner bez titulku nic nezastaví, takže se v liště i tak objeví záznam — ikona a název aplikace, žádný text. Pozorovatelný rozdíl oproti a1 je chybějící text, ne chybějící notifikace. Sleduj Doručené kvůli řádku v logu; lišta nemá co zobrazit.';
}

// Path: scenario.b1_foreground
class _Translations$scenario$b1_foreground$cs implements Translations$scenario$b1_foreground$en {
	_Translations$scenario$b1_foreground$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario b1_foreground
	@override String get title => 'Doručeno s aplikací na popředí';

	/// Description of scenario b1_foreground
	@override String get description => 'Spustí se onMessage a systém nic nevykresluje, takže to musí zajistit aplikace. Sleduj, jestli se banner objeví vůbec.';
}

// Path: scenario.b2_background
class _Translations$scenario$b2_background$cs implements Translations$scenario$b2_background$en {
	_Translations$scenario$b2_background$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario b2_background
	@override String get title => 'Aplikace na pozadí, zamčená obrazovka';

	/// Description of scenario b2_background
	@override String get description => 'Tenhle vykreslí systém. Sleduj, jestli se dostane až na zamčenou obrazovku a kolik z něj se tam zobrazí.';

	/// Manual steps for scenario b2_background
	@override String get manual_steps => 'Dej aplikaci na pozadí tlačítkem home, pak zamkni obrazovku. Pošli z jiného zařízení, nebo nejdřív ověř payload přes validate-only.';
}

// Path: scenario.b3_killed
class _Translations$scenario$b3_killed$cs implements Translations$scenario$b3_killed$en {
	_Translations$scenario$b3_killed$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario b3_killed
	@override String get title => 'Aplikace odsunutá z posledních';

	/// Description of scenario b3_killed
	@override String get description => 'Nejtěžší případ, a důvod, proč existuje zpožděné odesílání: odeslání musí proběhnout až po tom, co je aplikace pryč. Sleduj, jestli se spustí data handler.';
}

// Path: scenario.b4_after_reboot
class _Translations$scenario$b4_after_reboot$cs implements Translations$scenario$b4_after_reboot$en {
	_Translations$scenario$b4_after_reboot$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario b4_after_reboot
	@override String get title => 'Po restartu, aplikace nikdy neotevřená';

	/// Description of scenario b4_after_reboot
	@override String get description => 'Dokud se aplikace po startu telefonu ani jednou neotevře, někteří výrobci jí úplně zablokují práci na pozadí. Sleduj, jestli něco dorazí.';

	/// Manual steps for scenario b4_after_reboot
	@override String get manual_steps => 'adb reboot — a pak aplikaci NEOTVÍREJ. Počkej na zamčenou obrazovku a pošli.';
}

// Path: scenario.b5_force_stopped
class _Translations$scenario$b5_force_stopped$cs implements Translations$scenario$b5_force_stopped$en {
	_Translations$scenario$b5_force_stopped$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario b5_force_stopped
	@override String get title => 'Po Force stop';

	/// Description of scenario b5_force_stopped
	@override String get description => 'Force stop aplikaci odebere možnost být vzbuzena. Tenhle scénář existuje, aby to dokázal, ne aby se debugoval.';

	/// Expectation caveat for scenario b5_force_stopped
	@override String get expectation => 'Očekávaný výsledek: nic. Aplikace po Force stop nedostane žádný push, dokud ji uživatel ručně nespustí. Pokud něco přesto dorazí, stojí za to to vyšetřit.';

	/// Manual steps for scenario b5_force_stopped
	@override String get manual_steps => 'Nastavení › Aplikace › FCM Sample › Force stop. Pak pošli a nečekej nic.';
}

// Path: scenario.b6_token_refresh
class _Translations$scenario$b6_token_refresh$cs implements Translations$scenario$b6_token_refresh$en {
	_Translations$scenario$b6_token_refresh$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario b6_token_refresh
	@override String get title => 'Token obměněný přeinstalací nebo vymazáním dat';

	/// Description of scenario b6_token_refresh
	@override String get description => 'Starý token je mrtvý a odeslání na něj musí hlasitě selhat. Sleduj stránku Doručené pro nový token a porovnej ho se starým.';

	/// Manual steps for scenario b6_token_refresh
	@override String get manual_steps => 'adb shell pm clear cz.netglade.fcm_app — znovu otevři aplikaci a přečti nový token ze stránky Doručené. Odeslání na starý by mělo vrátit UNREGISTERED, což je k2_invalid_token.';
}

// Path: scenario.c1_priority_high
class _Translations$scenario$c1_priority_high$cs implements Translations$scenario$c1_priority_high$en {
	_Translations$scenario$c1_priority_high$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario c1_priority_high
	@override String get title => 'android.priority HIGH';

	/// Description of scenario c1_priority_high
	@override String get description => 'Vzbudí zařízení v Doze. Sleduj, jak rychle dorazí se zhasnutou obrazovkou ve srovnání s c2.';
}

// Path: scenario.c2_priority_normal
class _Translations$scenario$c2_priority_normal$cs implements Translations$scenario$c2_priority_normal$en {
	_Translations$scenario$c2_priority_normal$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario c2_priority_normal
	@override String get title => 'android.priority NORMAL';

	/// Description of scenario c2_priority_normal
	@override String get description => 'Může počkat na další údržbové okno. Sleduj zpoždění se zhasnutou obrazovkou — to je obvyklá příčina „chybějícího“ pushe.';
}

// Path: scenario.c3_ttl_zero
class _Translations$scenario$c3_ttl_zero$cs implements Translations$scenario$c3_ttl_zero$en {
	_Translations$scenario$c3_ttl_zero$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario c3_ttl_zero
	@override String get title => 'android.ttl 0s — teď, nebo nikdy';

	/// Description of scenario c3_ttl_zero
	@override String get description => 'FCM to zkusí jednou a zprávu zahodí, pokud zařízení není dostupné. Sleduj, že offline zařízení zprávu nikdy nedostane.';
}

// Path: scenario.c4_ttl_long
class _Translations$scenario$c4_ttl_long$cs implements Translations$scenario$c4_ttl_long$en {
	_Translations$scenario$c4_ttl_long$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario c4_ttl_long
	@override String get title => 'android.ttl 86400s — den opakovaných pokusů';

	/// Description of scenario c4_ttl_long
	@override String get description => 'Držena 24 hodin. Sleduj, jak dorazí, až se vrátí síť — dlouho po odeslání.';
}

// Path: scenario.c5_collapse_key
class _Translations$scenario$c5_collapse_key$cs implements Translations$scenario$c5_collapse_key$en {
	_Translations$scenario$c5_collapse_key$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario c5_collapse_key
	@override String get title => 'Pět odeslání se stejným collapse_key, offline';

	/// Description of scenario c5_collapse_key
	@override String get description => 'Přežít by mělo jen to poslední. Sleduj, že se po návratu sítě objeví jedna notifikace, ne pět.';

	/// Manual steps for scenario c5_collapse_key
	@override String get manual_steps => 'Přepni zařízení do režimu letadlo. Pošli pětkrát, pokaždé se změněným textem těla. Obnov síť: měla by se objevit přesně jedna notifikace s posledním textem.';
}

// Path: scenario.c6_doze_test
class _Translations$scenario$c6_doze_test$cs implements Translations$scenario$c6_doze_test$en {
	_Translations$scenario$c6_doze_test$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario c6_doze_test
	@override String get title => 'Doručení, když je zařízení v Doze';

	/// Description of scenario c6_doze_test
	@override String get description => 'Skutečné chování Doze, ne simulace. Sleduj, které priority se prosadí a které se pozdrží.';

	/// Manual steps for scenario c6_doze_test
	@override String get manual_steps => 'adb shell dumpsys deviceidle force-idle — pošli, pak obnov pomocí adb shell dumpsys deviceidle unforce.';
}

// Path: scenario.c7_standby_bucket
class _Translations$scenario$c7_standby_bucket$cs implements Translations$scenario$c7_standby_bucket$en {
	_Translations$scenario$c7_standby_bucket$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario c7_standby_bucket
	@override String get title => 'Aplikace v omezeném standby bucketu';

	/// Description of scenario c7_standby_bucket
	@override String get description => 'Nejtvrdší stav, který Android uvalí na nevyužívanou aplikaci. Sleduj, jestli push s prioritou HIGH i tak dorazí.';

	/// Manual steps for scenario c7_standby_bucket
	@override String get manual_steps => 'adb shell am set-standby-bucket cz.netglade.fcm_app restricted — ověř pomocí adb shell am get-standby-bucket cz.netglade.fcm_app.';
}

// Path: scenario.d1_importance_high
class _Translations$scenario$d1_importance_high$cs implements Translations$scenario$d1_importance_high$en {
	_Translations$scenario$d1_importance_high$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario d1_importance_high
	@override String get title => 'IMPORTANCE_HIGH — plovoucí (heads-up) banner';

	/// Description of scenario d1_importance_high
	@override String get description => 'Sleduj banner, který se objeví nad aktuální aplikací, se zvukem.';
}

// Path: scenario.d2_importance_default
class _Translations$scenario$d2_importance_default$cs implements Translations$scenario$d2_importance_default$en {
	_Translations$scenario$d2_importance_default$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario d2_importance_default
	@override String get title => 'IMPORTANCE_DEFAULT — zvuk, bez banneru';

	/// Description of scenario d2_importance_default
	@override String get description => 'Sleduj zvuk a záznam v liště, ale nic plovoucího.';
}

// Path: scenario.d3_importance_low
class _Translations$scenario$d3_importance_low$cs implements Translations$scenario$d3_importance_low$en {
	_Translations$scenario$d3_importance_low$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario d3_importance_low
	@override String get title => 'IMPORTANCE_LOW — tichá';

	/// Description of scenario d3_importance_low
	@override String get description => 'Viditelná, ale beze zvuku a bez vibrací. Sleduj, že je opravdu tichá, ne jen potichlejší.';
}

// Path: scenario.d4_importance_min
class _Translations$scenario$d4_importance_min$cs implements Translations$scenario$d4_importance_min$en {
	_Translations$scenario$d4_importance_min$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario d4_importance_min
	@override String get title => 'IMPORTANCE_MIN — jen stavový řádek';

	/// Description of scenario d4_importance_min
	@override String get description => 'Na některých verzích žádná ikona ve stavovém řádku; jen v rozbalovací liště. Sleduj, kde se vůbec objeví.';
}

// Path: scenario.d5_custom_sound
class _Translations$scenario$d5_custom_sound$cs implements Translations$scenario$d5_custom_sound$en {
	_Translations$scenario$d5_custom_sound$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario d5_custom_sound
	@override String get title => 'Vlastní zvuk na kanálu';

	/// Description of scenario d5_custom_sound
	@override String get description => 'Zvuk je vlastnost kanálu, takže jeho změna vyžaduje nový kanál. Sleduj, že se přehraje vlastní zvuk, a ne výchozí.';

	/// Expectation caveat for scenario d5_custom_sound
	@override String get expectation => 'Pojmenovaný zdroj musí existovat v android/app/src/main/res/raw. Chybějící soubor se tiše přepne na výchozí zvuk.';
}

// Path: scenario.d6_vibration_pattern
class _Translations$scenario$d6_vibration_pattern$cs implements Translations$scenario$d6_vibration_pattern$en {
	_Translations$scenario$d6_vibration_pattern$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario d6_vibration_pattern
	@override String get title => 'Vlastní vibrační vzor';

	/// Description of scenario d6_vibration_pattern
	@override String get description => 'Střídání délek vibrace a pauzy. Sleduj, že se použije požadovaný vzor, a ne výchozí hodnota kanálu.';
}

// Path: scenario.d7_channel_immutability
class _Translations$scenario$d7_channel_immutability$cs implements Translations$scenario$d7_channel_immutability$en {
	_Translations$scenario$d7_channel_immutability$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario d7_channel_immutability
	@override String get title => 'Změna existujícího kanálu — Android to ignoruje';

	/// Description of scenario d7_channel_immutability
	@override String get description => 'Znovu vytvoř chat_v1 s jinou importance a sleduj, že to Android úplně ignoruje. Tohle je ukázka toho, proč mají kanály ve svém id verzi.';

	/// Expectation caveat for scenario d7_channel_immutability
	@override String get expectation => 'Importance zobrazená na obrazovce kanálu zůstane na své původní hodnotě. Jediná oprava je nový kanál — chat_v2 — a přesně ten používá d8.';
}

// Path: scenario.d8_channel_group
class _Translations$scenario$d8_channel_group$cs implements Translations$scenario$d8_channel_group$en {
	_Translations$scenario$d8_channel_group$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario d8_channel_group
	@override String get title => 'Kanály sdružené do skupiny';

	/// Description of scenario d8_channel_group
	@override String get description => 'Sleduj systémová nastavení notifikací: kanály by se měly zobrazit vnořené pod pojmenovanou skupinou, ne jako plochý seznam.';
}

// Path: scenario.e1_long_text
class _Translations$scenario$e1_long_text$cs implements Translations$scenario$e1_long_text$en {
	_Translations$scenario$e1_long_text$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e1_long_text
	@override String get title => 'BigTextStyle s ~800 znaky';

	/// Description of scenario e1_long_text
	@override String get description => 'Sleduj, kde se text zkrátí ve sbaleném zobrazení a jestli rozbalení ukáže celý text. Diakritika je součástí záměrně, protože limity na délku v bajtech a v znacích se chovají jinak.';
}

// Path: scenario.e2_image_remote
class _Translations$scenario$e2_image_remote$cs implements Translations$scenario$e2_image_remote$en {
	_Translations$scenario$e2_image_remote$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e2_image_remote
	@override String get title => 'notification.image — stažený platformou';

	/// Description of scenario e2_image_remote
	@override String get description => 'FCM předá URL a platforma ho stáhne. Sleduj, že se zobrazí v rozbaleném stavu, a jak dlouho to trvá na pomalém připojení.';

	/// Expectation caveat for scenario e2_image_remote
	@override String get expectation => 'Android to umí nativně. iOS potřebuje Notification Service Extension, kterou tahle aplikace neobsahuje, takže se tam nic nezobrazí.';
}

// Path: scenario.e3_image_local
class _Translations$scenario$e3_image_local$cs implements Translations$scenario$e3_image_local$en {
	_Translations$scenario$e3_image_local$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e3_image_local
	@override String get title => 'Obrázek stažený data handlerem';

	/// Description of scenario e3_image_local
	@override String get description => 'Aplikace si URL stáhne sama a sestaví BigPictureStyle. Porovnej výsledek a časování s e2.';
}

// Path: scenario.e4_image_huge
class _Translations$scenario$e4_image_huge$cs implements Translations$scenario$e4_image_huge$en {
	_Translations$scenario$e4_image_huge$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e4_image_huge
	@override String get title => 'Obrázek 4000×3000';

	/// Description of scenario e4_image_huge
	@override String get description => 'Sleduj zmenšení, pád na out-of-memory, nebo tichý neúspěch, kdy dorazí text, ale obrázek ne.';
}

// Path: scenario.e5_image_404
class _Translations$scenario$e5_image_404$cs implements Translations$scenario$e5_image_404$en {
	_Translations$scenario$e5_image_404$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e5_image_404
	@override String get title => 'URL obrázku, které nejde načíst';

	/// Description of scenario e5_image_404
	@override String get description => 'Důležitá otázka je, jestli text i tak dorazí. Push, který zmizí, protože jeho obrázek vrátí 404, je špatný způsob selhání.';
}

// Path: scenario.e6_large_icon
class _Translations$scenario$e6_large_icon$cs implements Translations$scenario$e6_large_icon$en {
	_Translations$scenario$e6_large_icon$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e6_large_icon
	@override String get title => 'Velká ikona vedle textu';

	/// Description of scenario e6_large_icon
	@override String get description => 'Kulatý slot pro avatar, odlišný od malé ikony ve stavovém řádku. Sleduj, že je kulatý a není roztažený.';
}

// Path: scenario.e7_inbox_style
class _Translations$scenario$e7_inbox_style$cs implements Translations$scenario$e7_inbox_style$en {
	_Translations$scenario$e7_inbox_style$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e7_inbox_style
	@override String get title => 'InboxStyle se sedmi řádky';

	/// Description of scenario e7_inbox_style
	@override String get description => 'Sleduj, kolik řádků se po rozbalení skutečně zobrazí — Android to omezuje, a limit je nižší, než většina lidí čeká.';
}

// Path: scenario.e8_messaging_style
class _Translations$scenario$e8_messaging_style$cs implements Translations$scenario$e8_messaging_style$en {
	_Translations$scenario$e8_messaging_style$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e8_messaging_style
	@override String get title => 'MessagingStyle s několika odesílateli';

	/// Description of scenario e8_messaging_style
	@override String get description => 'Chatové rozvržení, se jménem a avatarem u každé zprávy. Sleduj seskupování a pořadí.';
}

// Path: scenario.e9_progress
class _Translations$scenario$e9_progress$cs implements Translations$scenario$e9_progress$en {
	_Translations$scenario$e9_progress$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e9_progress
	@override String get title => 'Ukazatel průběhu, aktualizovaný na místě';

	/// Description of scenario e9_progress
	@override String get description => 'Několik pushů aktualizujících jednu notifikaci. Sleduj, že se aktualizuje, a ne hromadí, a co se stane po dokončení.';
}

// Path: scenario.e10_color_and_icon
class _Translations$scenario$e10_color_and_icon$cs implements Translations$scenario$e10_color_and_icon$en {
	_Translations$scenario$e10_color_and_icon$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e10_color_and_icon
	@override String get title => 'Barva zvýraznění a monochromatická ikona';

	/// Description of scenario e10_color_and_icon
	@override String get description => 'Klasický Xiaomi bug s bílým čtverečkem: malá ikona, která není plochá monochromatická alpha maska, se vykreslí jako vyplněný blok. Sleduj stavový řádek.';

	/// Expectation caveat for scenario e10_color_and_icon
	@override String get expectation => 'Ikona musí být monochromatický drawable s průhledností. Bílý čtvereček vzniká právě z plnobarevné ikony launcheru.';
}

// Path: scenario.e11_emoji_rtl
class _Translations$scenario$e11_emoji_rtl$cs implements Translations$scenario$e11_emoji_rtl$en {
	_Translations$scenario$e11_emoji_rtl$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario e11_emoji_rtl
	@override String get title => 'Emoji, text zprava doleva a nezalomitelná slova';

	/// Description of scenario e11_emoji_rtl
	@override String get description => 'Sleduj směr textu u arabského řádku, jestli se emoji vykreslí barevně, a kde se zlomí slovo bez mezer.';
}

// Path: scenario.f1_actions
class _Translations$scenario$f1_actions$cs implements Translations$scenario$f1_actions$en {
	_Translations$scenario$f1_actions$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario f1_actions
	@override String get title => 'Dvě nebo tři akční tlačítka';

	/// Description of scenario f1_actions
	@override String get description => 'Sleduj, jestli tlačítka přežijí restart notifikační lišty, a co se stane s notifikací po stisknutí jednoho z nich.';

	/// Expectation caveat for scenario f1_actions
	@override String get expectation => 'Záměrně jen data: záznam vykreslený přímo FCM nemůže nést akční tlačítka, takže tenhle si aplikace vykresluje sama, a to v každém stavu. Jen Android — akce na iOS pocházejí z kategorie registrované při startu.';
}

// Path: scenario.f2_inline_reply
class _Translations$scenario$f2_inline_reply$cs implements Translations$scenario$f2_inline_reply$en {
	_Translations$scenario$f2_inline_reply$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario f2_inline_reply
	@override String get title => 'Inline odpověď přes RemoteInput';

	/// Description of scenario f2_inline_reply
	@override String get description => 'Napiš odpověď bez otevření aplikace. Sleduj, že notifikace zobrazí stav odesílání a pak se aktualizuje.';

	/// Expectation caveat for scenario f2_inline_reply
	@override String get expectation => 'Jen data, takže si ji vykresluje aplikace a tlačítko existuje v každém stavu. Odpověď aplikaci nikdy neotevře: zpracuje se ve vlastním isolate, který notifikaci aktualizuje na místě a text předá aplikaci při dalším spuštění nebo obnovení. Žádný server neexistuje — pauza mezi „Sending…“ a „Sent“ je simulovaná. Neuloží se žádná událost `opened`, protože se nic neotevřelo. Jen Android.';
}

// Path: scenario.f3_deeplink_foreground
class _Translations$scenario$f3_deeplink_foreground$cs implements Translations$scenario$f3_deeplink_foreground$en {
	_Translations$scenario$f3_deeplink_foreground$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario f3_deeplink_foreground
	@override String get title => 'Tap, když aplikace běží';

	/// Description of scenario f3_deeplink_foreground
	@override String get description => 'Routing z onMessage, s aplikací už na obrazovce. Sleduj, že se neztratí aktuální obrazovka.';

	/// Expectation caveat for scenario f3_deeplink_foreground
	@override String get expectation => 'Otevře stránku Telemetrie.';
}

// Path: scenario.f4_deeplink_background
class _Translations$scenario$f4_deeplink_background$cs implements Translations$scenario$f4_deeplink_background$en {
	_Translations$scenario$f4_deeplink_background$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario f4_deeplink_background
	@override String get title => 'Tap, když je aplikace na pozadí';

	/// Description of scenario f4_deeplink_background
	@override String get description => 'Routing z onMessageOpenedApp. Sleduj, že se aplikace obnoví na provázané obrazovce, a ne tam, kde skončila.';

	/// Expectation caveat for scenario f4_deeplink_background
	@override String get expectation => 'Otevře Sandbox.';
}

// Path: scenario.f5_deeplink_killed
class _Translations$scenario$f5_deeplink_killed$cs implements Translations$scenario$f5_deeplink_killed$en {
	_Translations$scenario$f5_deeplink_killed$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario f5_deeplink_killed
	@override String get title => 'Tap se zabitou aplikací';

	/// Description of scenario f5_deeplink_killed
	@override String get description => 'Routing z getInitialMessage, který se spustí jednou při startu a je nejčastějším zdrojem chyb v deep linkách — snadno se na něj zapomene a selhává právě jen v tom jednom stavu, který nikdo ručně netestuje.';

	/// Expectation caveat for scenario f5_deeplink_killed
	@override String get expectation => 'Otevře stránku Běhy.';
}

// Path: scenario.f6_delete_intent
class _Translations$scenario$f6_delete_intent$cs implements Translations$scenario$f6_delete_intent$en {
	_Translations$scenario$f6_delete_intent$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario f6_delete_intent
	@override String get title => 'Detekce odsunutí (swipe-away)';

	/// Description of scenario f6_delete_intent
	@override String get description => 'Delete intent se spustí, když uživatel notifikaci zavře bez tapnutí. Sleduj, že to lze rozlišit od tapnutí.';

	/// Expectation caveat for scenario f6_delete_intent
	@override String get expectation => 'Zjistí se jen tehdy, když je aplikace na obrazovce, protože jen tehdy notifikaci vykreslila sama aplikace přes plugin. Na pozadí vykresluje záznam v liště přímo FCM a odsunutí u něj nic nenahlásí; se zabitou aplikací už nezbyl žádný isolate, kterému by se to nahlásilo. Je to omezení Androidu, ne mezera v aplikaci.';
}

// Path: scenario.f7_ongoing
class _Translations$scenario$f7_ongoing$cs implements Translations$scenario$f7_ongoing$en {
	_Translations$scenario$f7_ongoing$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario f7_ongoing
	@override String get title => 'Trvalá notifikace, kterou nelze zavřít';

	/// Description of scenario f7_ongoing
	@override String get description => 'Sleduj, že ji nelze odsunout, a ověř, že existuje způsob, jak ji zrušit — trvalá notifikace bez úniku je jistý tiket na podporu.';

	/// Expectation caveat for scenario f7_ongoing
	@override String get expectation => 'Jde čistě o data — notifikaci kreslí sama aplikace a příznak ongoing platí ve všech stavech, protože FCM pro něj žádné pole nemá. Příznak říká Androidu, ať uživateli nedovolí notifikaci odsunout; od Androidu 14 to platforma dovolí jen hovorům, notifikacím zásad zařízení a médiím, jinak si uživatel trvalou notifikaci stejně zavřít může. Cestou ven je v obou případech tlačítko Vymazat notifikace na stránce Doručené, které vyčistí lištu a Doručené nechá netknuté — trvalá notifikace bez úniku je jistý tiket na podporu, takže ta cesta ven patří ke scénáři.';
}

// Path: scenario.f8_full_screen_intent
class _Translations$scenario$f8_full_screen_intent$cs implements Translations$scenario$f8_full_screen_intent$en {
	_Translations$scenario$f8_full_screen_intent$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario f8_full_screen_intent
	@override String get title => 'Full-screen intent jako příchozí hovor';

	/// Description of scenario f8_full_screen_intent
	@override String get description => 'Žádá o převzetí celé zamčené obrazovky. Sleduj, jestli je to vůbec povoleno, a na co se to degraduje, když je žádost zamítnuta.';

	/// Expectation caveat for scenario f8_full_screen_intent
	@override String get expectation => 'Jde čistě o data, takže aplikace notifikaci nejen kreslí, ale díky tomu si vůbec může o full-screen intent říct — FCM pro něj žádné pole nemá. Aplikace deklaruje USE_FULL_SCREEN_INTENT, což Android 14 a novější povoluje jen telefonním a budíkovým aplikacím, takže tady čekej degradovanou heads-up notifikaci místo převzetí obrazovky. Ukázkou je právě to zamítnutí. Sleduj to s aplikací na pozadí a se zamčenou nebo vypnutou obrazovkou: full-screen intent totiž zobrazí heads-up notifikaci i na telefonu, který se už používá, i tam, kde bylo oprávnění uděleno, takže na odemčeném telefonu ty dva případy nejde rozlišit. Zařízení, které oprávnění udělí, obrazovku místo toho převezme, a to je stejně platné pozorování.';
}

// Path: scenario.f9_trampoline
class _Translations$scenario$f9_trampoline$cs implements Translations$scenario$f9_trampoline$en {
	_Translations$scenario$f9_trampoline$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario f9_trampoline
	@override String get title => 'Notification trampoline, který má selhat';

	/// Description of scenario f9_trampoline
	@override String get description => 'Spuštění activity ze service nebo broadcast receiveru po tapnutí, místo přímo z notifikace. Android 12 tenhle vzorec rovnou zakázal — aplikaci, která by to takhle dělala, by tap zmizel beze stopy a activity by se nikdy neotevřela.';

	/// Expectation caveat for scenario f9_trampoline
	@override String get expectation => 'Není postaveno. Ukázat ten zákaz v praxi znamená spustit activity z broadcast receiveru nebo service, což vyžaduje nativní kód, který tenhle čistě dartový katalog záměrně nemá — to chybí schválně, ne z nedopatření.';
}

// Path: scenario.g1_group_summary
class _Translations$scenario$g1_group_summary$cs implements Translations$scenario$g1_group_summary$en {
	_Translations$scenario$g1_group_summary$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario g1_group_summary
	@override String get title => 'Pět notifikací se souhrnem';

	/// Description of scenario g1_group_summary
	@override String get description => 'Sleduj, že se sbalí pod jeden souhrnný řádek, a co souhrn říká, když dorazí pátá.';

	/// Expectation caveat for scenario g1_group_summary
	@override String get expectation => 'Jde čistě o data, takže souhrn ve všech stavech vykresluje a odesílá sama aplikace — FCM nemá pole `group`, takže payload s blokem notification by kód souhrnu nechal nedosažitelný, kdykoli je aplikace na pozadí. Souhrn si aplikace posílá sama a s příchodem každé další notifikace mu aktualizuje počet — payload jen pojmenuje skupinu. Pošli ho víckrát za sebou a sleduj, jak počet roste.';
}

// Path: scenario.g2_update_same_id
class _Translations$scenario$g2_update_same_id$cs implements Translations$scenario$g2_update_same_id$en {
	_Translations$scenario$g2_update_same_id$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario g2_update_same_id
	@override String get title => 'Nahrazení notifikace na místě';

	/// Description of scenario g2_update_same_id
	@override String get description => 'Pošli dvakrát se stejným tagem. Sleduj, že druhá nahradí první, a ne že se hromadí, a jestli znovu upozorní.';

	/// Expectation caveat for scenario g2_update_same_id
	@override String get expectation => 'FCM samo respektuje android.notification.tag, když kreslí záznam v liště, a aplikace teď svoje vlastní kreslení klíčuje na stejný tag — takže druhé odeslání nahradí první bez ohledu na to, kdo z nich ho nakreslil.';
}

// Path: scenario.g3_badge
class _Translations$scenario$g3_badge$cs implements Translations$scenario$g3_badge$en {
	_Translations$scenario$g3_badge$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario g3_badge
	@override String get title => 'Číslo na ikoně launcheru';

	/// Description of scenario g3_badge
	@override String get description => 'Nejméně přenositelná věc z celého katalogu. Sleduj, jestli launcher zobrazí číslo, tečku, nebo vůbec nic.';

	/// Expectation caveat for scenario g3_badge
	@override String get expectation => 'Chování se liší podle výrobce: One UI, MIUI a Pixel launcher se v tom neshodnou, a několik z nich navíc vyžaduje, aby uživatel odznaky povolil pro každou aplikaci zvlášť.';
}

// Path: scenario.g4_badge_ios
class _Translations$scenario$g4_badge_ios$cs implements Translations$scenario$g4_badge_ios$en {
	_Translations$scenario$g4_badge_ios$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario g4_badge_ios
	@override String get title => 'Odznak na iOS přes aps.badge';

	/// Description of scenario g4_badge_ios
	@override String get description => 'Jedno jasně definované číslo, nastavené odesílatelem. Sleduj, že se nahradí, a ne přičte — iOS nesčítá.';
}

// Path: scenario.h1_dnd_bypass
class _Translations$scenario$h1_dnd_bypass$cs implements Translations$scenario$h1_dnd_bypass$en {
	_Translations$scenario$h1_dnd_bypass$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario h1_dnd_bypass
	@override String get title => 'Kanál, který obchází Nerušit';

	/// Description of scenario h1_dnd_bypass
	@override String get description => 'Sleduj, že se ozve i s aktivním Nerušit. Nastavení flagu nestačí — uživatel musí navíc udělit přístup k notification policy.';

	/// Expectation caveat for scenario h1_dnd_bypass
	@override String get expectation => 'Vyžaduje Notification Policy Access, který uživatel udělí v systémovém nastavení. Bez něj se flag přijme, ale tiše se ignoruje.';
}

// Path: scenario.h2_category_alarm
class _Translations$scenario$h2_category_alarm$cs implements Translations$scenario$h2_category_alarm$en {
	_Translations$scenario$h2_category_alarm$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario h2_category_alarm
	@override String get title => 'CATEGORY_ALARM';

	/// Description of scenario h2_category_alarm
	@override String get description => 'Nerušit zachází s alarmy jako se speciální třídou. Sleduj, jestli samotná kategorie něco změní i bez přístupu k policy.';

	/// Expectation caveat for scenario h2_category_alarm
	@override String get expectation => 'FCM nemá pole pro kategorii notifikace — nastavuje ji klient při sestavování lokální notifikace, a proto je potřeba práce s kanály.';
}

// Path: scenario.h3_ios_time_sensitive
class _Translations$scenario$h3_ios_time_sensitive$cs implements Translations$scenario$h3_ios_time_sensitive$en {
	_Translations$scenario$h3_ios_time_sensitive$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario h3_ios_time_sensitive
	@override String get title => 'iOS time-sensitive — proniká přes Focus';

	/// Description of scenario h3_ios_time_sensitive
	@override String get description => 'Sleduj, že dorazí i během režimu Focus, který by běžnou notifikaci zadržel.';
}

// Path: scenario.h4_ios_critical
class _Translations$scenario$h4_ios_critical$cs implements Translations$scenario$h4_ios_critical$en {
	_Translations$scenario$h4_ios_critical$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario h4_ios_critical
	@override String get title => 'iOS critical — přes Focus i vypínač zvuku';

	/// Description of scenario h4_ios_critical
	@override String get description => 'Nejrušivější doručení, jaké Apple nabízí. Sleduj, že se ozve i se zařízením v tichém režimu.';

	/// Expectation caveat for scenario h4_ios_critical
	@override String get expectation => 'Vyžaduje critical-alert entitlement, který musí Apple pro aplikaci schválit. Bez něj APNs push odmítne, takže tady zůstává neodzkoušený — uvedený jen pro úplnost, ne k naplánování.';
}

// Path: scenario.h5_ios_passive
class _Translations$scenario$h5_ios_passive$cs implements Translations$scenario$h5_ios_passive$en {
	_Translations$scenario$h5_ios_passive$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario h5_ios_passive
	@override String get title => 'iOS passive — bez zvuku, bez probuzení';

	/// Description of scenario h5_ios_passive
	@override String get description => 'Nejtišší úroveň: objeví se v seznamu, aniž by na sebe upozornila. Sleduj, že se obrazovka nerozsvítí.';
}

// Path: scenario.i1_silent_no_sound
class _Translations$scenario$i1_silent_no_sound$cs implements Translations$scenario$i1_silent_no_sound$en {
	_Translations$scenario$i1_silent_no_sound$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario i1_silent_no_sound
	@override String get title => 'Viditelná, ale tichá';

	/// Description of scenario i1_silent_no_sound
	@override String get description => 'Objeví se v liště beze zvuku a bez vibrací. Sleduj, jestli je tichá, a přesto rozsvítí obrazovku, nebo ne.';
}

// Path: scenario.i2_silent_data_sync
class _Translations$scenario$i2_silent_data_sync$cs implements Translations$scenario$i2_silent_data_sync$en {
	_Translations$scenario$i2_silent_data_sync$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario i2_silent_data_sync
	@override String get title => 'Tichá synchronizace, vykreslení prázdné';

	/// Description of scenario i2_silent_data_sync
	@override String get description => 'Handler zapíše řádek; přesně o tom tenhle scénář je. V liště se i tak objeví záznam — ikona a název aplikace, bez titulku a textu — protože nic nezabrání banneru bez titulku. Sleduj stránku Doručené kvůli řádku; záznam v liště nemá co zobrazit.';
}

// Path: scenario.i3_ios_content_available
class _Translations$scenario$i3_ios_content_available$cs implements Translations$scenario$i3_ios_content_available$en {
	_Translations$scenario$i3_ios_content_available$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario i3_ios_content_available
	@override String get title => 'iOS background refresh přes content-available';

	/// Description of scenario i3_ios_content_available
	@override String get description => 'Vzbudí aplikaci, aby si stáhla data, aniž by cokoliv zobrazila. Sleduj, jak často to iOS skutečně respektuje — agresivně to omezuje (throttling).';

	/// Expectation caveat for scenario i3_ios_content_available
	@override String get expectation => 'iOS je může podle stavu baterie a používání zpozdit, nebo úplně zahodit. Chybějící push tu není nutně bug.';
}

// Path: scenario.i4_burst
class _Translations$scenario$i4_burst$cs implements Translations$scenario$i4_burst$en {
	_Translations$scenario$i4_burst$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario i4_burst
	@override String get title => 'Dvacet zpráv za deset sekund';

	/// Description of scenario i4_burst
	@override String get description => 'Sleduj rate limiting, slučování (coalescing) a limity výrobců. MIUI obvykle začne zahazovat dřív než FCM.';

	/// Manual steps for scenario i4_burst
	@override String get manual_steps => 'Pošli tohle 20krát během 10 sekund a spočítej, co dorazí. Měň tělo zprávy, aby bylo slučování vidět.';
}

// Path: scenario.j1_topic
class _Translations$scenario$j1_topic$cs implements Translations$scenario$j1_topic$en {
	_Translations$scenario$j1_topic$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario j1_topic
	@override String get title => 'Odeslání do tématu';

	/// Description of scenario j1_topic
	@override String get description => 'Přihlas zařízení k tématu a pak pošli na téma, ne na token. Sleduj, že push dorazí, aniž by odesílatel znal jakýkoli token.';

	/// Expectation caveat for scenario j1_topic
	@override String get expectation => 'Odeslání dnes funguje a FCM odpoví 200, ale nic se nedoručí, dokud aplikace neumí přihlásit se k tématu.';
}

// Path: scenario.j2_condition
class _Translations$scenario$j2_condition$cs implements Translations$scenario$j2_condition$en {
	_Translations$scenario$j2_condition$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario j2_condition
	@override String get title => 'Odeslání na booleovskou podmínku témat';

	/// Description of scenario j2_condition
	@override String get description => 'Zařízení musí být přihlášeno k oběma tématům, aby tohle dostalo. Sleduj, že přihlášení jen k jednomu ho vyloučí.';

	/// Expectation caveat for scenario j2_condition
	@override String get expectation => 'Stejně jako u j1, odeslání dnes funguje a FCM odpoví 200 — ale nic se nedoručí, dokud se aplikace neumí přihlásit k oběma tématům.';
}

// Path: scenario.j3_multicast
class _Translations$scenario$j3_multicast$cs implements Translations$scenario$j3_multicast$en {
	_Translations$scenario$j3_multicast$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario j3_multicast
	@override String get title => 'Odeslání na všechna registrovaná zařízení';

	/// Description of scenario j3_multicast
	@override String get description => 'Hlavní nástroj pro porovnání chování mezi telefony: jedno odeslání, všechna zařízení, a výsledkem jsou rozdíly mezi nimi.';

	/// Expectation caveat for scenario j3_multicast
	@override String get expectation => 'FCM nemá publikum „všechna zařízení“, takže tohle potřebuje registr tokenů, který API zatím nemá. Odeslání teď vrátí 501 s tímto důvodem, místo aby tiše doručilo na jedno zařízení.';
}

// Path: scenario.k1_payload_oversize
class _Translations$scenario$k1_payload_oversize$cs implements Translations$scenario$k1_payload_oversize$en {
	_Translations$scenario$k1_payload_oversize$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario k1_payload_oversize
	@override String get title => 'Payload nad limit FCM 4 KB';

	/// Description of scenario k1_payload_oversize
	@override String get description => 'Sleduj, že API předá chybu FCM s použitelnou zprávou, a ne holé 400.';

	/// Expectation caveat for scenario k1_payload_oversize
	@override String get expectation => 'FCM tohle odmítne s INVALID_ARGUMENT. Odeslání by mělo selhat dřív, než cokoliv dorazí na zařízení.';
}

// Path: scenario.k2_invalid_token
class _Translations$scenario$k2_invalid_token$cs implements Translations$scenario$k2_invalid_token$en {
	_Translations$scenario$k2_invalid_token$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario k2_invalid_token
	@override String get title => 'Token, který už není registrovaný';

	/// Description of scenario k2_invalid_token
	@override String get description => 'Běžná produkční chyba. Sleduj, že API to nahlásí jako UNREGISTERED, a ne jako obecné 404 — právě to řekne skutečnému backendu, že má řádek smazat.';

	/// Expectation caveat for scenario k2_invalid_token
	@override String get expectation => 'FCM odpoví UNREGISTERED, což tohle API mapuje na 404 s vlastním zněním. errorCode v error.details má přednost před stavem NOT_FOUND na nejvyšší úrovni.';
}

// Path: scenario.k3_permission_denied
class _Translations$scenario$k3_permission_denied$cs implements Translations$scenario$k3_permission_denied$en {
	_Translations$scenario$k3_permission_denied$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario k3_permission_denied
	@override String get title => 'POST_NOTIFICATIONS zamítnuto na Androidu 13+';

	/// Description of scenario k3_permission_denied
	@override String get description => 'Sleduj, že data handler stejně běží a Doručené se stejně plní, i když se nic nedá vykreslit.';

	/// Manual steps for scenario k3_permission_denied
	@override String get manual_steps => 'adb shell pm revoke cz.netglade.fcm_app android.permission.POST_NOTIFICATIONS — pak pošli a kontroluj stránku Doručené, ne lištu.';
}

// Path: scenario.k4_notifications_disabled
class _Translations$scenario$k4_notifications_disabled$cs implements Translations$scenario$k4_notifications_disabled$en {
	_Translations$scenario$k4_notifications_disabled$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario k4_notifications_disabled
	@override String get title => 'Notifikace vypnuté v systémovém nastavení';

	/// Description of scenario k4_notifications_disabled
	@override String get description => 'Jiný případ než zamítnuté oprávnění: aplikace oprávnění má, ale uživatel je vypnul. Sleduj, že doručení dat tím není ovlivněno.';

	/// Manual steps for scenario k4_notifications_disabled
	@override String get manual_steps => 'Nastavení › Aplikace › FCM Sample › Notifikace › vypnout. Pošli a ověř, že se řádek objeví na stránce Doručené.';
}

// Path: scenario.k5_battery_restricted
class _Translations$scenario$k5_battery_restricted$cs implements Translations$scenario$k5_battery_restricted$en {
	_Translations$scenario$k5_battery_restricted$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Title of scenario k5_battery_restricted
	@override String get title => 'Aplikace v omezeném režimu baterie';

	/// Description of scenario k5_battery_restricted
	@override String get description => 'Stav, do kterého se uživatel dostane tapnutím na „omezit“ v nastavení baterie. Sleduj, jestli push s prioritou HIGH aplikaci i tak vzbudí.';

	/// Manual steps for scenario k5_battery_restricted
	@override String get manual_steps => 'Nastavení › Aplikace › FCM Sample › Baterie › Omezený. Pošli a porovnej zpoždění s c1_priority_high v neomezeném stavu.';
}

// Path: channels.fcm_sample_high
class _Translations$channels$fcm_sample_high$cs implements Translations$channels$fcm_sample_high$en {
	_Translations$channels$fcm_sample_high$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name shown in system settings
	@override String get name => 'Ukázkové pushe';

	/// Android channel description shown in system settings
	@override String get description => 'Pushe přijaté ukázkovou aplikací FCM.';
}

// Path: channels.importance_high
class _Translations$channels$importance_high$cs implements Translations$channels$importance_high$en {
	_Translations$channels$importance_high$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; d1
	@override String get name => 'Důležitost: vysoká';

	/// Android channel description; d1
	@override String get description => 'Vyskočí jako banner a zazní.';
}

// Path: channels.importance_default
class _Translations$channels$importance_default$cs implements Translations$channels$importance_default$en {
	_Translations$channels$importance_default$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; d2
	@override String get name => 'Důležitost: výchozí';

	/// Android channel description; d2
	@override String get description => 'Zazní, ale nevyskočí.';
}

// Path: channels.importance_low
class _Translations$channels$importance_low$cs implements Translations$channels$importance_low$en {
	_Translations$channels$importance_low$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; d3 and i1
	@override String get name => 'Důležitost: nízká';

	/// Android channel description; d3 and i1
	@override String get description => 'Tiše. Objeví se jen v liště.';
}

// Path: channels.importance_min
class _Translations$channels$importance_min$cs implements Translations$channels$importance_min$en {
	_Translations$channels$importance_min$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; d4
	@override String get name => 'Důležitost: minimální';

	/// Android channel description; d4
	@override String get description => 'Sbalená v liště bez ikony.';
}

// Path: channels.custom_sound
class _Translations$channels$custom_sound$cs implements Translations$channels$custom_sound$en {
	_Translations$channels$custom_sound$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; d5
	@override String get name => 'Vlastní zvuk';

	/// Android channel description; d5
	@override String get description => 'Přehraje přibalený tón místo výchozího.';
}

// Path: channels.vibration_pattern
class _Translations$channels$vibration_pattern$cs implements Translations$channels$vibration_pattern$en {
	_Translations$channels$vibration_pattern$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; d6
	@override String get name => 'Vibrační vzor';

	/// Android channel description; d6
	@override String get description => 'Krátce, pauza, krátce — nastaveno při vzniku kanálu.';
}

// Path: channels.chat_v1
class _Translations$channels$chat_v1$cs implements Translations$channels$chat_v1$en {
	_Translations$channels$chat_v1$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; d7. A version tag, so the same in both
	@override String get name => 'Chat (v1)';

	/// Android channel description; d7
	@override String get description => 'První pokus. Jeho důležitost už nejde změnit.';
}

// Path: channels.chat_v2
class _Translations$channels$chat_v2$cs implements Translations$channels$chat_v2$en {
	_Translations$channels$chat_v2$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; d8. A version tag, so the same in both
	@override String get name => 'Chat (v2)';

	/// Android channel description; d8
	@override String get description => 'Náhrada — nové id je jediná cesta ke změně důležitosti.';
}

// Path: channels.dnd_bypass
class _Translations$channels$dnd_bypass$cs implements Translations$channels$dnd_bypass$en {
	_Translations$channels$dnd_bypass$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; h1
	@override String get name => 'Obejití režimu Nerušit';

	/// Android channel description; h1
	@override String get description => 'Vyžádáno. Uděleno jen s přístupem k zásadám oznámení.';
}

// Path: channels.alarms
class _Translations$channels$alarms$cs implements Translations$channels$alarms$en {
	_Translations$channels$alarms$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel name; h2
	@override String get name => 'Budíky';

	/// Android channel description; h2
	@override String get description => 'Používá zvukový kanál budíku místo oznámení.';
}

// Path: channels.group
class _Translations$channels$group$cs implements Translations$channels$group$en {
	_Translations$channels$group$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations
	@override late final _Translations$channels$group$chat$cs chat = _Translations$channels$group$chat$cs._(_root);
}

// Path: channels.group.chat
class _Translations$channels$group$chat$cs implements Translations$channels$group$chat$en {
	_Translations$channels$group$chat$cs._(this._root);

	final TranslationsCs _root; // ignore: unused_field

	// Translations

	/// Android channel group heading; d8. A product word, so the same in both
	@override String get name => 'Chat';
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
			'drawer.channels' => 'Kanály',
			'inbox.registration_token' => 'Registrační token',
			'inbox.clear_notifications' => 'Vymazat notifikace',
			'inbox.empty' => 'Zatím nedorazil žádný push.',
			'inbox.malformed_dropped' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${n} poškozený payload zahozen', few: '${n} poškozené payloady zahozeny', other: '${n} poškozených payloadů zahozeno', ), 
			'inbox.setup_error' => ({required Object error}) => 'Uložené pushe se nepodařilo načíst: ${error}',
			'message_detail.opened_by_action' => ({required Object label}) => 'Otevřeno akcí: ${label}',
			'message_detail.from' => ({required Object from}) => 'Zdroj: ${from}',
			'message_detail.replied' => ({required Object text}) => 'Odpovězeno: ${text}',
			'message_detail.sent' => 'Odesláno',
			'message_detail.payload_id' => 'ID payloadu',
			'message_detail.extra_data' => 'Extra data',
			'message_detail.no_extra_data' => 'Žádné extra klíče.',
			'reply.sending' => 'Odesílám…',
			'reply.sent' => 'Odesláno',
			'reply.not_sent' => 'Neodesláno',
			'message_tile.no_title' => '(bez titulku)',
			'message_tile.body_with_data' => ({required Object body, required Object keys}) => '${body}\ndata: ${keys}',
			'scenarios.no_token' => 'Zatím není registrační token, takže není kam posílat. Otevři Doručené, až se aplikace zaregistruje.',
			'scenario_card.needs_work' => 'potřebuje práci',
			'common.needs_killed_app' => 'Vyžaduje zabitou aplikaci',
			'common.cancel' => 'Zrušit',
			'common.schedule_ellipsis' => 'Naplánovat…',
			'common.reload' => 'Znovu načíst',
			'common.no_scenario' => 'bez scénáře',
			'common.no_device_yet' => 'zatím žádné zařízení',
			'selection_bar.select_for_batch' => 'Vybrat do dávky',
			'selection_bar.selected_count' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${n} vybrán', few: '${n} vybrány', other: '${n} vybráno', ), 
			'runs.empty' => 'Zatím nic naplánováno. Vyber scénář a zvol Naplánovat.',
			'run_timeline.title' => 'Běh',
			'run_tile.sends' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '${n} odeslání', other: '${n} odeslání', ), 
			'run_tile.next_due' => ({required Object time}) => 'další v ${time}',
			'run_item.composed_by_hand' => '(složeno ručně)',
			'run_item.due' => ({required Object time}) => 'v ${time}',
			'run_item.nothing_recorded' => 'Zatím nic nezaznamenáno.',
			'sandbox.validate_only' => 'Jen validovat',
			'sandbox.needs_banner' => ({required Object needs}) => 'Potřebuje ${needs}. Push se pošle, ale tento scénář se tady nedá pozorovat.',
			'sandbox.send_blocked.no_target' => 'Vyplň cíl doručení, nebo se přepni zpět na toto zařízení.',
			'sandbox.send_blocked.no_token' => 'Zatím není registrační token, takže není kam posílat.',
			'sandbox.send_blocked.sending' => 'Odesílám…',
			'sandbox.send_blocked.invalid_field' => 'Některé pole je neplatné. Které, poznáš podle sekcí s ikonou chyby.',
			'send.to_this_device' => 'Poslat na toto zařízení',
			'send.to_that_token' => 'Poslat na ten token',
			'send.to_topic' => ({required Object topic}) => 'Poslat do tématu „${topic}“',
			'send.to_condition' => 'Poslat na podmínku',
			'send.to_every_device' => 'Poslat na všechna zařízení',
			'send_target.label' => 'Poslat na',
			'send_target.this_device' => 'Toto zařízení',
			'send_target.token' => 'Token',
			'send_target.topic' => 'Téma',
			'send_target.condition' => 'Podmínka',
			'send_target.all_devices' => 'Všechna zařízení',
			'send_target.all_devices_warning' => 'Odeslání na všechna zařízení potřebuje registr tokenů, který API zatím nemá, takže bude odmítnuto.',
			'schedule_sheet.delay' => 'Zpoždění',
			'schedule_sheet.spacing' => 'Rozestup',
			'schedule_sheet.spacing_help' => 'Přičte se za každou zprávu po první, takže dávka dorazí rozprostřená, ne jako jeden shluk.',
			'schedule_sheet.confirm' => 'Naplánovat',
			'preset_chip.seconds' => ({required Object value}) => '${value} s',
			'not_received.button' => 'Nikdy nedorazilo',
			'not_received.reported' => 'Nahlášeno: nikdy nedorazilo',
			'send_result.validated' => ({required Object messageId, required Object traceId}) => '✓ Zvalidováno · zpráva ${messageId} · trace ${traceId} · payload byl zvalidován, ne odeslán',
			'send_result.sent' => ({required Object messageId, required Object traceId}) => '✓ Odesláno · zpráva ${messageId} · trace ${traceId} · za chvíli by se mělo objevit v Doručených',
			'send_result.scheduled' => ({required num n, required Object runId}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('cs'))(n, one: '✓ Naplánováno · běh ${runId} · ${n} zpráva · zatím nic neodesláno', few: '✓ Naplánováno · běh ${runId} · ${n} zprávy · zatím nic neodesláno', other: '✓ Naplánováno · běh ${runId} · ${n} zpráv · zatím nic neodesláno', ), 
			'countdown.seconds' => 'sekund',
			'countdown.swipe_away' => 'Teď odsuň aplikaci z posledních. Push je už naplánovaný na serveru, takže dorazí, ať aplikace běží nebo ne.',
			'countdown.dim_note' => 'Obyčejná aplikace nedokáže vypnout displej — dovede ho pouze ztlumit a přestat mu bránit v uspání, takže systém časem vypne sám.',
			'countdown.dim_screen' => 'Ztmavit displej',
			'countdown.battery_settings' => 'Nastavení baterie',
			'telemetry.tab.events' => 'Události',
			'telemetry.tab.latency' => 'Latence',
			'telemetry.events.empty' => 'Zatím nic nezaznamenáno. Pošli push ze Sandboxu a načti znovu.',
			'telemetry.event_row.request_received' => ' · (požadavek přijat)',
			'telemetry.latency.empty' => 'Zatím žádná měření. Řádek potřebuje odeslání i doručení pro stejný trace.',
			'telemetry.latency.scenario_column' => 'scénář',
			'telemetry.latency.footnote' => '`sent` je okamžik, kdy API dostalo požadavek, ne kdy odpovědělo FCM, takže každé číslo výše zahrnuje i dobu volání FCM.',
			'api.unreachable' => ({required Object baseUrl, required Object error}) => 'Nepodařilo se spojit s ${baseUrl} — běží API?\nNa fyzickém zařízení spusť: adb reverse tcp:8080 tcp:8080\n(${error})',
			'api.answered_status' => ({required Object status, required Object body}) => 'API odpovědělo ${status}: ${body}',
			'api.answered_unreadable' => ({required Object error}) => 'API odpovědělo 200 něčím nečitelným: ${error}',
			'api.answered_not_json' => ({required Object error}) => 'API odpovědělo 200 něčím, co není JSON: ${error}',
			'api.answered_wrong_shape' => ({required Object type}) => 'API odpovědělo 200 typem ${type}, kde se čekal seznam.',
			'api.answered_wrong_shape_runs' => ({required Object type}) => 'API odpovědělo 200 typem ${type}, kde se čekal seznam běhů.',
			'api.answered_unreadable_item' => ({required Object what, required Object error}) => 'API odpovědělo 200 s ${what}, co tento build neumí přečíst: ${error}',
			'api.item.event' => 'událost',
			'api.item.latency_row' => 'řádek latence',
			'api.expected_object' => ({required Object type}) => 'Byl přijat typ ${type}, kde se čekal JSON objekt.',
			'scenario.a1_notification_only.title' => 'Payload jen s notification',
			'scenario.a1_notification_only.description' => 'Sleduj, která vrstva ho vykreslila — systém, když je aplikace na pozadí, aplikace, když je na popředí — a jak vyjdou ikona a barva zvýraznění.',
			'scenario.a2_data_only.title' => 'Payload jen s daty, vykreslený lokálně',
			'scenario.a2_data_only.description' => 'Tohle nevykreslí nic jiného než aplikace. Sleduj, jestli push dorazí i se zabitou aplikací — přesně pro tenhle případ data-only doručení existuje.',
			'scenario.a2_data_only.expectation' => 'Na iOS potřebuje data-only push content-available a je omezovaný (throttling); viz i3_ios_content_available.',
			'scenario.a3_hybrid.title' => 'notification a data společně',
			'scenario.a3_hybrid.description' => 'Běžný tvar v produkci. Sleduj, jestli data mapa dorazí do handleru po tapnutí — přesně tam si deep linky berou svoje argumenty.',
			'scenario.a4_no_display.title' => 'Data zalogovaná tiše, vykreslení prázdné',
			'scenario.a4_no_display.description' => 'Tichá synchronizace: handler se spustí a zapíše řádek do logu. Banner bez titulku nic nezastaví, takže se v liště i tak objeví záznam — ikona a název aplikace, žádný text. Pozorovatelný rozdíl oproti a1 je chybějící text, ne chybějící notifikace. Sleduj Doručené kvůli řádku v logu; lišta nemá co zobrazit.',
			'scenario.b1_foreground.title' => 'Doručeno s aplikací na popředí',
			'scenario.b1_foreground.description' => 'Spustí se onMessage a systém nic nevykresluje, takže to musí zajistit aplikace. Sleduj, jestli se banner objeví vůbec.',
			'scenario.b2_background.title' => 'Aplikace na pozadí, zamčená obrazovka',
			'scenario.b2_background.description' => 'Tenhle vykreslí systém. Sleduj, jestli se dostane až na zamčenou obrazovku a kolik z něj se tam zobrazí.',
			'scenario.b2_background.manual_steps' => 'Dej aplikaci na pozadí tlačítkem home, pak zamkni obrazovku. Pošli z jiného zařízení, nebo nejdřív ověř payload přes validate-only.',
			'scenario.b3_killed.title' => 'Aplikace odsunutá z posledních',
			'scenario.b3_killed.description' => 'Nejtěžší případ, a důvod, proč existuje zpožděné odesílání: odeslání musí proběhnout až po tom, co je aplikace pryč. Sleduj, jestli se spustí data handler.',
			'scenario.b4_after_reboot.title' => 'Po restartu, aplikace nikdy neotevřená',
			'scenario.b4_after_reboot.description' => 'Dokud se aplikace po startu telefonu ani jednou neotevře, někteří výrobci jí úplně zablokují práci na pozadí. Sleduj, jestli něco dorazí.',
			'scenario.b4_after_reboot.manual_steps' => 'adb reboot — a pak aplikaci NEOTVÍREJ. Počkej na zamčenou obrazovku a pošli.',
			'scenario.b5_force_stopped.title' => 'Po Force stop',
			'scenario.b5_force_stopped.description' => 'Force stop aplikaci odebere možnost být vzbuzena. Tenhle scénář existuje, aby to dokázal, ne aby se debugoval.',
			'scenario.b5_force_stopped.expectation' => 'Očekávaný výsledek: nic. Aplikace po Force stop nedostane žádný push, dokud ji uživatel ručně nespustí. Pokud něco přesto dorazí, stojí za to to vyšetřit.',
			'scenario.b5_force_stopped.manual_steps' => 'Nastavení › Aplikace › FCM Sample › Force stop. Pak pošli a nečekej nic.',
			'scenario.b6_token_refresh.title' => 'Token obměněný přeinstalací nebo vymazáním dat',
			'scenario.b6_token_refresh.description' => 'Starý token je mrtvý a odeslání na něj musí hlasitě selhat. Sleduj stránku Doručené pro nový token a porovnej ho se starým.',
			'scenario.b6_token_refresh.manual_steps' => 'adb shell pm clear cz.netglade.fcm_app — znovu otevři aplikaci a přečti nový token ze stránky Doručené. Odeslání na starý by mělo vrátit UNREGISTERED, což je k2_invalid_token.',
			'scenario.c1_priority_high.title' => 'android.priority HIGH',
			'scenario.c1_priority_high.description' => 'Vzbudí zařízení v Doze. Sleduj, jak rychle dorazí se zhasnutou obrazovkou ve srovnání s c2.',
			'scenario.c2_priority_normal.title' => 'android.priority NORMAL',
			'scenario.c2_priority_normal.description' => 'Může počkat na další údržbové okno. Sleduj zpoždění se zhasnutou obrazovkou — to je obvyklá příčina „chybějícího“ pushe.',
			'scenario.c3_ttl_zero.title' => 'android.ttl 0s — teď, nebo nikdy',
			'scenario.c3_ttl_zero.description' => 'FCM to zkusí jednou a zprávu zahodí, pokud zařízení není dostupné. Sleduj, že offline zařízení zprávu nikdy nedostane.',
			'scenario.c4_ttl_long.title' => 'android.ttl 86400s — den opakovaných pokusů',
			'scenario.c4_ttl_long.description' => 'Držena 24 hodin. Sleduj, jak dorazí, až se vrátí síť — dlouho po odeslání.',
			'scenario.c5_collapse_key.title' => 'Pět odeslání se stejným collapse_key, offline',
			'scenario.c5_collapse_key.description' => 'Přežít by mělo jen to poslední. Sleduj, že se po návratu sítě objeví jedna notifikace, ne pět.',
			'scenario.c5_collapse_key.manual_steps' => 'Přepni zařízení do režimu letadlo. Pošli pětkrát, pokaždé se změněným textem těla. Obnov síť: měla by se objevit přesně jedna notifikace s posledním textem.',
			'scenario.c6_doze_test.title' => 'Doručení, když je zařízení v Doze',
			'scenario.c6_doze_test.description' => 'Skutečné chování Doze, ne simulace. Sleduj, které priority se prosadí a které se pozdrží.',
			'scenario.c6_doze_test.manual_steps' => 'adb shell dumpsys deviceidle force-idle — pošli, pak obnov pomocí adb shell dumpsys deviceidle unforce.',
			'scenario.c7_standby_bucket.title' => 'Aplikace v omezeném standby bucketu',
			'scenario.c7_standby_bucket.description' => 'Nejtvrdší stav, který Android uvalí na nevyužívanou aplikaci. Sleduj, jestli push s prioritou HIGH i tak dorazí.',
			'scenario.c7_standby_bucket.manual_steps' => 'adb shell am set-standby-bucket cz.netglade.fcm_app restricted — ověř pomocí adb shell am get-standby-bucket cz.netglade.fcm_app.',
			'scenario.d1_importance_high.title' => 'IMPORTANCE_HIGH — plovoucí (heads-up) banner',
			'scenario.d1_importance_high.description' => 'Sleduj banner, který se objeví nad aktuální aplikací, se zvukem.',
			'scenario.d2_importance_default.title' => 'IMPORTANCE_DEFAULT — zvuk, bez banneru',
			'scenario.d2_importance_default.description' => 'Sleduj zvuk a záznam v liště, ale nic plovoucího.',
			'scenario.d3_importance_low.title' => 'IMPORTANCE_LOW — tichá',
			'scenario.d3_importance_low.description' => 'Viditelná, ale beze zvuku a bez vibrací. Sleduj, že je opravdu tichá, ne jen potichlejší.',
			'scenario.d4_importance_min.title' => 'IMPORTANCE_MIN — jen stavový řádek',
			'scenario.d4_importance_min.description' => 'Na některých verzích žádná ikona ve stavovém řádku; jen v rozbalovací liště. Sleduj, kde se vůbec objeví.',
			'scenario.d5_custom_sound.title' => 'Vlastní zvuk na kanálu',
			'scenario.d5_custom_sound.description' => 'Zvuk je vlastnost kanálu, takže jeho změna vyžaduje nový kanál. Sleduj, že se přehraje vlastní zvuk, a ne výchozí.',
			'scenario.d5_custom_sound.expectation' => 'Pojmenovaný zdroj musí existovat v android/app/src/main/res/raw. Chybějící soubor se tiše přepne na výchozí zvuk.',
			'scenario.d6_vibration_pattern.title' => 'Vlastní vibrační vzor',
			'scenario.d6_vibration_pattern.description' => 'Střídání délek vibrace a pauzy. Sleduj, že se použije požadovaný vzor, a ne výchozí hodnota kanálu.',
			'scenario.d7_channel_immutability.title' => 'Změna existujícího kanálu — Android to ignoruje',
			'scenario.d7_channel_immutability.description' => 'Znovu vytvoř chat_v1 s jinou importance a sleduj, že to Android úplně ignoruje. Tohle je ukázka toho, proč mají kanály ve svém id verzi.',
			'scenario.d7_channel_immutability.expectation' => 'Importance zobrazená na obrazovce kanálu zůstane na své původní hodnotě. Jediná oprava je nový kanál — chat_v2 — a přesně ten používá d8.',
			'scenario.d8_channel_group.title' => 'Kanály sdružené do skupiny',
			'scenario.d8_channel_group.description' => 'Sleduj systémová nastavení notifikací: kanály by se měly zobrazit vnořené pod pojmenovanou skupinou, ne jako plochý seznam.',
			'scenario.e1_long_text.title' => 'BigTextStyle s ~800 znaky',
			'scenario.e1_long_text.description' => 'Sleduj, kde se text zkrátí ve sbaleném zobrazení a jestli rozbalení ukáže celý text. Diakritika je součástí záměrně, protože limity na délku v bajtech a v znacích se chovají jinak.',
			'scenario.e2_image_remote.title' => 'notification.image — stažený platformou',
			'scenario.e2_image_remote.description' => 'FCM předá URL a platforma ho stáhne. Sleduj, že se zobrazí v rozbaleném stavu, a jak dlouho to trvá na pomalém připojení.',
			'scenario.e2_image_remote.expectation' => 'Android to umí nativně. iOS potřebuje Notification Service Extension, kterou tahle aplikace neobsahuje, takže se tam nic nezobrazí.',
			'scenario.e3_image_local.title' => 'Obrázek stažený data handlerem',
			'scenario.e3_image_local.description' => 'Aplikace si URL stáhne sama a sestaví BigPictureStyle. Porovnej výsledek a časování s e2.',
			'scenario.e4_image_huge.title' => 'Obrázek 4000×3000',
			'scenario.e4_image_huge.description' => 'Sleduj zmenšení, pád na out-of-memory, nebo tichý neúspěch, kdy dorazí text, ale obrázek ne.',
			'scenario.e5_image_404.title' => 'URL obrázku, které nejde načíst',
			'scenario.e5_image_404.description' => 'Důležitá otázka je, jestli text i tak dorazí. Push, který zmizí, protože jeho obrázek vrátí 404, je špatný způsob selhání.',
			'scenario.e6_large_icon.title' => 'Velká ikona vedle textu',
			'scenario.e6_large_icon.description' => 'Kulatý slot pro avatar, odlišný od malé ikony ve stavovém řádku. Sleduj, že je kulatý a není roztažený.',
			'scenario.e7_inbox_style.title' => 'InboxStyle se sedmi řádky',
			'scenario.e7_inbox_style.description' => 'Sleduj, kolik řádků se po rozbalení skutečně zobrazí — Android to omezuje, a limit je nižší, než většina lidí čeká.',
			'scenario.e8_messaging_style.title' => 'MessagingStyle s několika odesílateli',
			'scenario.e8_messaging_style.description' => 'Chatové rozvržení, se jménem a avatarem u každé zprávy. Sleduj seskupování a pořadí.',
			'scenario.e9_progress.title' => 'Ukazatel průběhu, aktualizovaný na místě',
			'scenario.e9_progress.description' => 'Několik pushů aktualizujících jednu notifikaci. Sleduj, že se aktualizuje, a ne hromadí, a co se stane po dokončení.',
			'scenario.e10_color_and_icon.title' => 'Barva zvýraznění a monochromatická ikona',
			'scenario.e10_color_and_icon.description' => 'Klasický Xiaomi bug s bílým čtverečkem: malá ikona, která není plochá monochromatická alpha maska, se vykreslí jako vyplněný blok. Sleduj stavový řádek.',
			'scenario.e10_color_and_icon.expectation' => 'Ikona musí být monochromatický drawable s průhledností. Bílý čtvereček vzniká právě z plnobarevné ikony launcheru.',
			'scenario.e11_emoji_rtl.title' => 'Emoji, text zprava doleva a nezalomitelná slova',
			'scenario.e11_emoji_rtl.description' => 'Sleduj směr textu u arabského řádku, jestli se emoji vykreslí barevně, a kde se zlomí slovo bez mezer.',
			'scenario.f1_actions.title' => 'Dvě nebo tři akční tlačítka',
			'scenario.f1_actions.description' => 'Sleduj, jestli tlačítka přežijí restart notifikační lišty, a co se stane s notifikací po stisknutí jednoho z nich.',
			'scenario.f1_actions.expectation' => 'Záměrně jen data: záznam vykreslený přímo FCM nemůže nést akční tlačítka, takže tenhle si aplikace vykresluje sama, a to v každém stavu. Jen Android — akce na iOS pocházejí z kategorie registrované při startu.',
			'scenario.f2_inline_reply.title' => 'Inline odpověď přes RemoteInput',
			'scenario.f2_inline_reply.description' => 'Napiš odpověď bez otevření aplikace. Sleduj, že notifikace zobrazí stav odesílání a pak se aktualizuje.',
			'scenario.f2_inline_reply.expectation' => 'Jen data, takže si ji vykresluje aplikace a tlačítko existuje v každém stavu. Odpověď aplikaci nikdy neotevře: zpracuje se ve vlastním isolate, který notifikaci aktualizuje na místě a text předá aplikaci při dalším spuštění nebo obnovení. Žádný server neexistuje — pauza mezi „Sending…“ a „Sent“ je simulovaná. Neuloží se žádná událost `opened`, protože se nic neotevřelo. Jen Android.',
			'scenario.f3_deeplink_foreground.title' => 'Tap, když aplikace běží',
			'scenario.f3_deeplink_foreground.description' => 'Routing z onMessage, s aplikací už na obrazovce. Sleduj, že se neztratí aktuální obrazovka.',
			'scenario.f3_deeplink_foreground.expectation' => 'Otevře stránku Telemetrie.',
			'scenario.f4_deeplink_background.title' => 'Tap, když je aplikace na pozadí',
			'scenario.f4_deeplink_background.description' => 'Routing z onMessageOpenedApp. Sleduj, že se aplikace obnoví na provázané obrazovce, a ne tam, kde skončila.',
			'scenario.f4_deeplink_background.expectation' => 'Otevře Sandbox.',
			'scenario.f5_deeplink_killed.title' => 'Tap se zabitou aplikací',
			'scenario.f5_deeplink_killed.description' => 'Routing z getInitialMessage, který se spustí jednou při startu a je nejčastějším zdrojem chyb v deep linkách — snadno se na něj zapomene a selhává právě jen v tom jednom stavu, který nikdo ručně netestuje.',
			'scenario.f5_deeplink_killed.expectation' => 'Otevře stránku Běhy.',
			'scenario.f6_delete_intent.title' => 'Detekce odsunutí (swipe-away)',
			'scenario.f6_delete_intent.description' => 'Delete intent se spustí, když uživatel notifikaci zavře bez tapnutí. Sleduj, že to lze rozlišit od tapnutí.',
			'scenario.f6_delete_intent.expectation' => 'Zjistí se jen tehdy, když je aplikace na obrazovce, protože jen tehdy notifikaci vykreslila sama aplikace přes plugin. Na pozadí vykresluje záznam v liště přímo FCM a odsunutí u něj nic nenahlásí; se zabitou aplikací už nezbyl žádný isolate, kterému by se to nahlásilo. Je to omezení Androidu, ne mezera v aplikaci.',
			'scenario.f7_ongoing.title' => 'Trvalá notifikace, kterou nelze zavřít',
			'scenario.f7_ongoing.description' => 'Sleduj, že ji nelze odsunout, a ověř, že existuje způsob, jak ji zrušit — trvalá notifikace bez úniku je jistý tiket na podporu.',
			'scenario.f7_ongoing.expectation' => 'Jde čistě o data — notifikaci kreslí sama aplikace a příznak ongoing platí ve všech stavech, protože FCM pro něj žádné pole nemá. Příznak říká Androidu, ať uživateli nedovolí notifikaci odsunout; od Androidu 14 to platforma dovolí jen hovorům, notifikacím zásad zařízení a médiím, jinak si uživatel trvalou notifikaci stejně zavřít může. Cestou ven je v obou případech tlačítko Vymazat notifikace na stránce Doručené, které vyčistí lištu a Doručené nechá netknuté — trvalá notifikace bez úniku je jistý tiket na podporu, takže ta cesta ven patří ke scénáři.',
			'scenario.f8_full_screen_intent.title' => 'Full-screen intent jako příchozí hovor',
			'scenario.f8_full_screen_intent.description' => 'Žádá o převzetí celé zamčené obrazovky. Sleduj, jestli je to vůbec povoleno, a na co se to degraduje, když je žádost zamítnuta.',
			'scenario.f8_full_screen_intent.expectation' => 'Jde čistě o data, takže aplikace notifikaci nejen kreslí, ale díky tomu si vůbec může o full-screen intent říct — FCM pro něj žádné pole nemá. Aplikace deklaruje USE_FULL_SCREEN_INTENT, což Android 14 a novější povoluje jen telefonním a budíkovým aplikacím, takže tady čekej degradovanou heads-up notifikaci místo převzetí obrazovky. Ukázkou je právě to zamítnutí. Sleduj to s aplikací na pozadí a se zamčenou nebo vypnutou obrazovkou: full-screen intent totiž zobrazí heads-up notifikaci i na telefonu, který se už používá, i tam, kde bylo oprávnění uděleno, takže na odemčeném telefonu ty dva případy nejde rozlišit. Zařízení, které oprávnění udělí, obrazovku místo toho převezme, a to je stejně platné pozorování.',
			'scenario.f9_trampoline.title' => 'Notification trampoline, který má selhat',
			'scenario.f9_trampoline.description' => 'Spuštění activity ze service nebo broadcast receiveru po tapnutí, místo přímo z notifikace. Android 12 tenhle vzorec rovnou zakázal — aplikaci, která by to takhle dělala, by tap zmizel beze stopy a activity by se nikdy neotevřela.',
			'scenario.f9_trampoline.expectation' => 'Není postaveno. Ukázat ten zákaz v praxi znamená spustit activity z broadcast receiveru nebo service, což vyžaduje nativní kód, který tenhle čistě dartový katalog záměrně nemá — to chybí schválně, ne z nedopatření.',
			'scenario.g1_group_summary.title' => 'Pět notifikací se souhrnem',
			'scenario.g1_group_summary.description' => 'Sleduj, že se sbalí pod jeden souhrnný řádek, a co souhrn říká, když dorazí pátá.',
			'scenario.g1_group_summary.expectation' => 'Jde čistě o data, takže souhrn ve všech stavech vykresluje a odesílá sama aplikace — FCM nemá pole `group`, takže payload s blokem notification by kód souhrnu nechal nedosažitelný, kdykoli je aplikace na pozadí. Souhrn si aplikace posílá sama a s příchodem každé další notifikace mu aktualizuje počet — payload jen pojmenuje skupinu. Pošli ho víckrát za sebou a sleduj, jak počet roste.',
			'scenario.g2_update_same_id.title' => 'Nahrazení notifikace na místě',
			'scenario.g2_update_same_id.description' => 'Pošli dvakrát se stejným tagem. Sleduj, že druhá nahradí první, a ne že se hromadí, a jestli znovu upozorní.',
			'scenario.g2_update_same_id.expectation' => 'FCM samo respektuje android.notification.tag, když kreslí záznam v liště, a aplikace teď svoje vlastní kreslení klíčuje na stejný tag — takže druhé odeslání nahradí první bez ohledu na to, kdo z nich ho nakreslil.',
			'scenario.g3_badge.title' => 'Číslo na ikoně launcheru',
			'scenario.g3_badge.description' => 'Nejméně přenositelná věc z celého katalogu. Sleduj, jestli launcher zobrazí číslo, tečku, nebo vůbec nic.',
			'scenario.g3_badge.expectation' => 'Chování se liší podle výrobce: One UI, MIUI a Pixel launcher se v tom neshodnou, a několik z nich navíc vyžaduje, aby uživatel odznaky povolil pro každou aplikaci zvlášť.',
			'scenario.g4_badge_ios.title' => 'Odznak na iOS přes aps.badge',
			'scenario.g4_badge_ios.description' => 'Jedno jasně definované číslo, nastavené odesílatelem. Sleduj, že se nahradí, a ne přičte — iOS nesčítá.',
			'scenario.h1_dnd_bypass.title' => 'Kanál, který obchází Nerušit',
			'scenario.h1_dnd_bypass.description' => 'Sleduj, že se ozve i s aktivním Nerušit. Nastavení flagu nestačí — uživatel musí navíc udělit přístup k notification policy.',
			'scenario.h1_dnd_bypass.expectation' => 'Vyžaduje Notification Policy Access, který uživatel udělí v systémovém nastavení. Bez něj se flag přijme, ale tiše se ignoruje.',
			'scenario.h2_category_alarm.title' => 'CATEGORY_ALARM',
			'scenario.h2_category_alarm.description' => 'Nerušit zachází s alarmy jako se speciální třídou. Sleduj, jestli samotná kategorie něco změní i bez přístupu k policy.',
			'scenario.h2_category_alarm.expectation' => 'FCM nemá pole pro kategorii notifikace — nastavuje ji klient při sestavování lokální notifikace, a proto je potřeba práce s kanály.',
			'scenario.h3_ios_time_sensitive.title' => 'iOS time-sensitive — proniká přes Focus',
			'scenario.h3_ios_time_sensitive.description' => 'Sleduj, že dorazí i během režimu Focus, který by běžnou notifikaci zadržel.',
			'scenario.h4_ios_critical.title' => 'iOS critical — přes Focus i vypínač zvuku',
			'scenario.h4_ios_critical.description' => 'Nejrušivější doručení, jaké Apple nabízí. Sleduj, že se ozve i se zařízením v tichém režimu.',
			'scenario.h4_ios_critical.expectation' => 'Vyžaduje critical-alert entitlement, který musí Apple pro aplikaci schválit. Bez něj APNs push odmítne, takže tady zůstává neodzkoušený — uvedený jen pro úplnost, ne k naplánování.',
			'scenario.h5_ios_passive.title' => 'iOS passive — bez zvuku, bez probuzení',
			'scenario.h5_ios_passive.description' => 'Nejtišší úroveň: objeví se v seznamu, aniž by na sebe upozornila. Sleduj, že se obrazovka nerozsvítí.',
			'scenario.i1_silent_no_sound.title' => 'Viditelná, ale tichá',
			'scenario.i1_silent_no_sound.description' => 'Objeví se v liště beze zvuku a bez vibrací. Sleduj, jestli je tichá, a přesto rozsvítí obrazovku, nebo ne.',
			'scenario.i2_silent_data_sync.title' => 'Tichá synchronizace, vykreslení prázdné',
			'scenario.i2_silent_data_sync.description' => 'Handler zapíše řádek; přesně o tom tenhle scénář je. V liště se i tak objeví záznam — ikona a název aplikace, bez titulku a textu — protože nic nezabrání banneru bez titulku. Sleduj stránku Doručené kvůli řádku; záznam v liště nemá co zobrazit.',
			'scenario.i3_ios_content_available.title' => 'iOS background refresh přes content-available',
			'scenario.i3_ios_content_available.description' => 'Vzbudí aplikaci, aby si stáhla data, aniž by cokoliv zobrazila. Sleduj, jak často to iOS skutečně respektuje — agresivně to omezuje (throttling).',
			'scenario.i3_ios_content_available.expectation' => 'iOS je může podle stavu baterie a používání zpozdit, nebo úplně zahodit. Chybějící push tu není nutně bug.',
			'scenario.i4_burst.title' => 'Dvacet zpráv za deset sekund',
			'scenario.i4_burst.description' => 'Sleduj rate limiting, slučování (coalescing) a limity výrobců. MIUI obvykle začne zahazovat dřív než FCM.',
			'scenario.i4_burst.manual_steps' => 'Pošli tohle 20krát během 10 sekund a spočítej, co dorazí. Měň tělo zprávy, aby bylo slučování vidět.',
			'scenario.j1_topic.title' => 'Odeslání do tématu',
			'scenario.j1_topic.description' => 'Přihlas zařízení k tématu a pak pošli na téma, ne na token. Sleduj, že push dorazí, aniž by odesílatel znal jakýkoli token.',
			'scenario.j1_topic.expectation' => 'Odeslání dnes funguje a FCM odpoví 200, ale nic se nedoručí, dokud aplikace neumí přihlásit se k tématu.',
			'scenario.j2_condition.title' => 'Odeslání na booleovskou podmínku témat',
			'scenario.j2_condition.description' => 'Zařízení musí být přihlášeno k oběma tématům, aby tohle dostalo. Sleduj, že přihlášení jen k jednomu ho vyloučí.',
			'scenario.j2_condition.expectation' => 'Stejně jako u j1, odeslání dnes funguje a FCM odpoví 200 — ale nic se nedoručí, dokud se aplikace neumí přihlásit k oběma tématům.',
			'scenario.j3_multicast.title' => 'Odeslání na všechna registrovaná zařízení',
			'scenario.j3_multicast.description' => 'Hlavní nástroj pro porovnání chování mezi telefony: jedno odeslání, všechna zařízení, a výsledkem jsou rozdíly mezi nimi.',
			'scenario.j3_multicast.expectation' => 'FCM nemá publikum „všechna zařízení“, takže tohle potřebuje registr tokenů, který API zatím nemá. Odeslání teď vrátí 501 s tímto důvodem, místo aby tiše doručilo na jedno zařízení.',
			'scenario.k1_payload_oversize.title' => 'Payload nad limit FCM 4 KB',
			'scenario.k1_payload_oversize.description' => 'Sleduj, že API předá chybu FCM s použitelnou zprávou, a ne holé 400.',
			'scenario.k1_payload_oversize.expectation' => 'FCM tohle odmítne s INVALID_ARGUMENT. Odeslání by mělo selhat dřív, než cokoliv dorazí na zařízení.',
			'scenario.k2_invalid_token.title' => 'Token, který už není registrovaný',
			'scenario.k2_invalid_token.description' => 'Běžná produkční chyba. Sleduj, že API to nahlásí jako UNREGISTERED, a ne jako obecné 404 — právě to řekne skutečnému backendu, že má řádek smazat.',
			'scenario.k2_invalid_token.expectation' => 'FCM odpoví UNREGISTERED, což tohle API mapuje na 404 s vlastním zněním. errorCode v error.details má přednost před stavem NOT_FOUND na nejvyšší úrovni.',
			'scenario.k3_permission_denied.title' => 'POST_NOTIFICATIONS zamítnuto na Androidu 13+',
			'scenario.k3_permission_denied.description' => 'Sleduj, že data handler stejně běží a Doručené se stejně plní, i když se nic nedá vykreslit.',
			'scenario.k3_permission_denied.manual_steps' => 'adb shell pm revoke cz.netglade.fcm_app android.permission.POST_NOTIFICATIONS — pak pošli a kontroluj stránku Doručené, ne lištu.',
			'scenario.k4_notifications_disabled.title' => 'Notifikace vypnuté v systémovém nastavení',
			'scenario.k4_notifications_disabled.description' => 'Jiný případ než zamítnuté oprávnění: aplikace oprávnění má, ale uživatel je vypnul. Sleduj, že doručení dat tím není ovlivněno.',
			'scenario.k4_notifications_disabled.manual_steps' => 'Nastavení › Aplikace › FCM Sample › Notifikace › vypnout. Pošli a ověř, že se řádek objeví na stránce Doručené.',
			'scenario.k5_battery_restricted.title' => 'Aplikace v omezeném režimu baterie',
			'scenario.k5_battery_restricted.description' => 'Stav, do kterého se uživatel dostane tapnutím na „omezit“ v nastavení baterie. Sleduj, jestli push s prioritou HIGH aplikaci i tak vzbudí.',
			'scenario.k5_battery_restricted.manual_steps' => 'Nastavení › Aplikace › FCM Sample › Baterie › Omezený. Pošli a porovnej zpoždění s c1_priority_high v neomezeném stavu.',
			'scenario_group.a' => 'A — Základní doručení',
			'scenario_group.b' => 'B — Stavy aplikace',
			'scenario_group.c' => 'C — Priorita a doručovací okno',
			'scenario_group.d' => 'D — Kanály a důležitost',
			'scenario_group.e' => 'E — Vzhled',
			'scenario_group.f' => 'F — Interakce',
			'scenario_group.g' => 'G — Skupiny, odznak, aktualizace',
			'scenario_group.h' => 'H — Rušivost a priorita',
			'scenario_group.i' => 'I — Tiché a datové',
			'scenario_group.j' => 'J — Cílení',
			'scenario_group.k' => 'K — Krajní případy a chyby',
			'scenario_need.badge' => 'odznak na ikoně aplikace',
			'scenario_need.targeting' => 'registr zařízení',
			'scenario_need.manual_step' => 'manuální krok',
			'scenario_need.external_approval' => 'externí schválení',
			'scenario_need.native_code' => 'nativní kód',
			'form_section.message' => 'Zpráva FCM v1 bez cíle doručení, který nastavuje server.',
			'form_section.notification' => 'Zobrazuje se na všech platformách, pokud ho nepřebije blok konkrétní platformy.',
			'form_section.android' => 'Možnosti doručení a zobrazení pro Android.',
			'form_section.android_notification' => 'Vše, co umí panel oznámení Androidu navíc oproti sdílenému bloku.',
			'form_section.apns' => 'Možnosti doručení a zobrazení pro iOS a macOS.',
			'form_section.apns_fcm_options' => 'Možnosti doručení, včetně obrázku, který přijímá jen APNs.',
			'form_section.webpush' => 'Možnosti doručení a zobrazení pro prohlížeče.',
			'form_section.webpush_fcm_options' => 'Možnosti doručení, včetně odkazu, který se otevře po kliknutí.',
			'form_section.fcm_options' => 'Možnosti doručení, které FCM uplatňuje na všech platformách.',
			'form_section.light_settings' => 'Jakmile je tento blok přítomen, FCM vyžaduje všechna jeho pole.',
			'form_field.remove_row' => 'Odebrat tento řádek',
			'form_field.add_row' => 'Přidat',
			'form_field.not_set' => 'Nenastaveno',
			'form_field.not_sent' => 'Neodesláno',
			'channels.fcm_sample_high.name' => 'Ukázkové pushe',
			'channels.fcm_sample_high.description' => 'Pushe přijaté ukázkovou aplikací FCM.',
			'channels.importance_high.name' => 'Důležitost: vysoká',
			'channels.importance_high.description' => 'Vyskočí jako banner a zazní.',
			'channels.importance_default.name' => 'Důležitost: výchozí',
			'channels.importance_default.description' => 'Zazní, ale nevyskočí.',
			'channels.importance_low.name' => 'Důležitost: nízká',
			'channels.importance_low.description' => 'Tiše. Objeví se jen v liště.',
			'channels.importance_min.name' => 'Důležitost: minimální',
			'channels.importance_min.description' => 'Sbalená v liště bez ikony.',
			'channels.custom_sound.name' => 'Vlastní zvuk',
			'channels.custom_sound.description' => 'Přehraje přibalený tón místo výchozího.',
			'channels.vibration_pattern.name' => 'Vibrační vzor',
			'channels.vibration_pattern.description' => 'Krátce, pauza, krátce — nastaveno při vzniku kanálu.',
			'channels.chat_v1.name' => 'Chat (v1)',
			'channels.chat_v1.description' => 'První pokus. Jeho důležitost už nejde změnit.',
			'channels.chat_v2.name' => 'Chat (v2)',
			'channels.chat_v2.description' => 'Náhrada — nové id je jediná cesta ke změně důležitosti.',
			'channels.dnd_bypass.name' => 'Obejití režimu Nerušit',
			'channels.dnd_bypass.description' => 'Vyžádáno. Uděleno jen s přístupem k zásadám oznámení.',
			'channels.alarms.name' => 'Budíky',
			'channels.alarms.description' => 'Používá zvukový kanál budíku místo oznámení.',
			'channels.group.chat.name' => 'Chat',
			'channels.title' => 'Kanály oznámení',
			'channels.requested' => 'Vyžádáno',
			'channels.reported' => 'Hlášeno systémem',
			'channels.not_registered' => 'Neregistrováno',
			'channels.importance' => 'Důležitost',
			'channels.sound' => 'Zvuk',
			'channels.default_sound' => 'Výchozí',
			'channels.vibration' => 'Vibrace',
			'channels.bypass_dnd' => 'Obchází Nerušit',
			'channels.group_label' => 'Skupina',
			'channels.badge' => 'Zobrazuje odznak',
			'channels.try_lower' => 'Zkusit snížit',
			'channels.immutability_hint' => 'Důležitost se zmrazí při vzniku kanálu. Zmáčkni a sleduj, že se hlášená hodnota nehne — stisknutím se ale zruší i oznámení, které pro tento kanál právě visí v liště.',
			'channels.refresh' => 'Načíst znovu',
			_ => null,
		};
	}
}
