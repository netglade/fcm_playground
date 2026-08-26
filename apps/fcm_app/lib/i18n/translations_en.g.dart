///
/// Generated file. Do not edit.
///
// coverage:ignore-file
// ignore_for_file: type=lint, unused_import
// dart format off

part of 'translations.g.dart';

// Path: <root>
typedef TranslationsEn = Translations; // ignore: unused_element
class Translations with BaseTranslations<AppLocale, Translations> {
	/// Returns the current translations of the given [context].
	///
	/// Usage:
	/// final t = Translations.of(context);
	static Translations of(BuildContext context) => InheritedLocaleData.of<AppLocale, Translations>(context).translations;

	/// You can call this constructor and build your own translation instance of this locale.
	/// Constructing via the enum [AppLocale.build] is preferred.
	Translations({Map<String, Node>? overrides, PluralResolver? cardinalResolver, PluralResolver? ordinalResolver, TranslationMetadata<AppLocale, Translations>? meta})
		: assert(overrides == null, 'Set "translation_overrides: true" in order to enable this feature.'),
		  $meta = meta ?? TranslationMetadata(
		    locale: AppLocale.en,
		    overrides: overrides ?? {},
		    cardinalResolver: cardinalResolver,
		    ordinalResolver: ordinalResolver,
		  ) {
		$meta.setFlatMapFunction(_flatMapFunction);
	}

	/// Metadata for the translations of <en>.
	@override final TranslationMetadata<AppLocale, Translations> $meta;

	/// Access flat map
	dynamic operator[](String key) => $meta.getTranslation(key);

	late final Translations _root = this; // ignore: unused_field

	Translations $copyWith({TranslationMetadata<AppLocale, Translations>? meta}) => Translations(meta: meta ?? this.$meta);

	// Translations
	late final Translations$app$en app = Translations$app$en._(_root);
	late final Translations$language$en language = Translations$language$en._(_root);
	late final Translations$shell$en shell = Translations$shell$en._(_root);
	late final Translations$drawer$en drawer = Translations$drawer$en._(_root);
	late final Translations$inbox$en inbox = Translations$inbox$en._(_root);
	late final Translations$message_detail$en message_detail = Translations$message_detail$en._(_root);
	late final Translations$reply$en reply = Translations$reply$en._(_root);
	late final Translations$message_tile$en message_tile = Translations$message_tile$en._(_root);
	late final Translations$scenarios$en scenarios = Translations$scenarios$en._(_root);
	late final Translations$scenario_card$en scenario_card = Translations$scenario_card$en._(_root);
	late final Translations$common$en common = Translations$common$en._(_root);
	late final Translations$selection_bar$en selection_bar = Translations$selection_bar$en._(_root);
	late final Translations$runs$en runs = Translations$runs$en._(_root);
	late final Translations$run_timeline$en run_timeline = Translations$run_timeline$en._(_root);
	late final Translations$run_tile$en run_tile = Translations$run_tile$en._(_root);
	late final Translations$run_item$en run_item = Translations$run_item$en._(_root);
	late final Translations$sandbox$en sandbox = Translations$sandbox$en._(_root);
	late final Translations$send$en send = Translations$send$en._(_root);
	late final Translations$send_target$en send_target = Translations$send_target$en._(_root);
	late final Translations$schedule_sheet$en schedule_sheet = Translations$schedule_sheet$en._(_root);
	late final Translations$preset_chip$en preset_chip = Translations$preset_chip$en._(_root);
	late final Translations$not_received$en not_received = Translations$not_received$en._(_root);
	late final Translations$send_result$en send_result = Translations$send_result$en._(_root);
	late final Translations$countdown$en countdown = Translations$countdown$en._(_root);
	late final Translations$telemetry$en telemetry = Translations$telemetry$en._(_root);
	late final Translations$api$en api = Translations$api$en._(_root);
	late final Translations$scenario$en scenario = Translations$scenario$en._(_root);
	late final Translations$scenario_group$en scenario_group = Translations$scenario_group$en._(_root);
	late final Translations$scenario_need$en scenario_need = Translations$scenario_need$en._(_root);
	late final Translations$channels$en channels = Translations$channels$en._(_root);
}

// Path: app
class Translations$app$en {
	Translations$app$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// MaterialApp title and drawer header; a product name, so the same in both
	///
	/// en: 'FCM Sample'
	String get title => 'FCM Sample';
}

// Path: language
class Translations$language$en {
	Translations$language$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// AppBar action tooltip for the language switcher
	///
	/// en: 'Language'
	String get tooltip => 'Language';

	/// Language choice that follows the device
	///
	/// en: 'System'
	String get system => 'System';

	/// Language choice; each language names itself
	///
	/// en: 'English'
	String get english => 'English';

	/// Language choice; each language names itself
	///
	/// en: 'Čeština'
	String get czech => 'Čeština';
}

// Path: shell
class Translations$shell$en {
	Translations$shell$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$shell$title$en title = Translations$shell$title$en._(_root);
}

// Path: drawer
class Translations$drawer$en {
	Translations$drawer$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Drawer destination; shorter than the AppBar title
	///
	/// en: 'Inbox'
	String get inbox => 'Inbox';

	/// Drawer destination
	///
	/// en: 'Scenarios'
	String get scenarios => 'Scenarios';

	/// Drawer destination
	///
	/// en: 'Sandbox'
	String get sandbox => 'Sandbox';

	/// Drawer destination
	///
	/// en: 'Runs'
	String get runs => 'Runs';

	/// Drawer destination
	///
	/// en: 'Telemetry'
	String get telemetry => 'Telemetry';

	/// Drawer destination
	///
	/// en: 'Channels'
	String get channels => 'Channels';
}

// Path: inbox
class Translations$inbox$en {
	Translations$inbox$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Tile above the FCM token
	///
	/// en: 'Registration token'
	String get registration_token => 'Registration token';

	/// Empty state
	///
	/// en: 'No pushes received yet.'
	String get empty => 'No pushes received yet.';

	/// en: '(one) {$n malformed payload dropped} (few) {$n malformed payloads dropped} (other) {$n malformed payloads dropped}'
	String malformed_dropped({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} malformed payload dropped',
		few: '${n} malformed payloads dropped',
		other: '${n} malformed payloads dropped',
	);
}

// Path: message_detail
class Translations$message_detail$en {
	Translations$message_detail$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Detail line naming the action button that opened the app
	///
	/// en: 'Opened by action: $label'
	String opened_by_action({required Object label}) => 'Opened by action: ${label}';

	/// Detail line naming which surface the press came from
	///
	/// en: 'from: $from'
	String from({required Object from}) => 'from: ${from}';

	/// Detail line showing an inline reply
	///
	/// en: 'Replied: $text'
	String replied({required Object text}) => 'Replied: ${text}';

	/// Label above the send timestamp
	///
	/// en: 'Sent'
	String get sent => 'Sent';

	/// Label above the message id
	///
	/// en: 'Payload id'
	String get payload_id => 'Payload id';

	/// Label above the data map
	///
	/// en: 'Extra data'
	String get extra_data => 'Extra data';

	/// Shown when the data map is empty
	///
	/// en: 'No extra data keys.'
	String get no_extra_data => 'No extra data keys.';
}

// Path: reply
class Translations$reply$en {
	Translations$reply$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of the notification shown while an inline reply is in flight
	///
	/// en: 'Sending…'
	String get sending => 'Sending…';

	/// Title of the notification once the reply went out
	///
	/// en: 'Sent'
	String get sent => 'Sent';

	/// Title of the notification when the reply failed
	///
	/// en: 'Not sent'
	String get not_sent => 'Not sent';
}

// Path: message_tile
class Translations$message_tile$en {
	Translations$message_tile$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Stand-in headline for a message with an empty title
	///
	/// en: '(no title)'
	String get no_title => '(no title)';

	/// Tile subtitle when the message carries a data map
	///
	/// en: '$body data: $keys'
	String body_with_data({required Object body, required Object keys}) => '${body}\ndata: ${keys}';
}

// Path: scenarios
class Translations$scenarios$en {
	Translations$scenarios$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Banner when the device has not registered
	///
	/// en: 'No registration token yet, so there is nowhere to send. Open the Inbox once the app has registered.'
	String get no_token => 'No registration token yet, so there is nowhere to send. Open the Inbox once the app has registered.';
}

// Path: scenario_card
class Translations$scenario_card$en {
	Translations$scenario_card$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Chip on a scenario whose needs are unmet
	///
	/// en: 'needs work'
	String get needs_work => 'needs work';
}

// Path: common
class Translations$common$en {
	Translations$common$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Badge on a scenario that only means something with the app killed; used on the card and in the Sandbox
	///
	/// en: 'Needs the app killed'
	String get needs_killed_app => 'Needs the app killed';

	/// Dismisses a sheet or leaves selection mode; used in several places
	///
	/// en: 'Cancel'
	String get cancel => 'Cancel';

	/// Opens the schedule sheet; used on the selection bar and the send footer
	///
	/// en: 'Schedule…'
	String get schedule_ellipsis => 'Schedule…';

	/// Refresh action; used on the run timeline and on Telemetry
	///
	/// en: 'Reload'
	String get reload => 'Reload';

	/// Stands in for a trace with no scenario id; used on the matrix and the trace card
	///
	/// en: 'no scenario'
	String get no_scenario => 'no scenario';

	/// Stands in for a trace with no device id
	///
	/// en: 'no device yet'
	String get no_device_yet => 'no device yet';
}

// Path: selection_bar
class Translations$selection_bar$en {
	Translations$selection_bar$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Button that enters multi-select
	///
	/// en: 'Select for a batch'
	String get select_for_batch => 'Select for a batch';

	/// en: '(one) {$n selected} (few) {$n selected} (other) {$n selected}'
	String selected_count({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} selected',
		few: '${n} selected',
		other: '${n} selected',
	);
}

// Path: runs
class Translations$runs$en {
	Translations$runs$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Empty state on the Runs page
	///
	/// en: 'Nothing scheduled yet. Pick a scenario and choose Schedule.'
	String get empty => 'Nothing scheduled yet. Pick a scenario and choose Schedule.';
}

// Path: run_timeline
class Translations$run_timeline$en {
	Translations$run_timeline$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// AppBar title of a single run's timeline
	///
	/// en: 'Run'
	String get title => 'Run';
}

// Path: run_tile
class Translations$run_tile$en {
	Translations$run_tile$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// en: '(one) {$n send} (other) {$n sends}'
	String sends({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '${n} send',
		other: '${n} sends',
	);

	/// When the run's next message goes out
	///
	/// en: 'next due $time'
	String next_due({required Object time}) => 'next due ${time}';
}

// Path: run_item
class Translations$run_item$en {
	Translations$run_item$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Stands in for a run item with no scenario id
	///
	/// en: '(composed by hand)'
	String get composed_by_hand => '(composed by hand)';

	/// When one run item goes out
	///
	/// en: 'due $time'
	String due({required Object time}) => 'due ${time}';

	/// Empty state for a run item's events
	///
	/// en: 'Nothing recorded yet.'
	String get nothing_recorded => 'Nothing recorded yet.';
}

// Path: sandbox
class Translations$sandbox$en {
	Translations$sandbox$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Switch that asks FCM to validate without delivering
	///
	/// en: 'Validate only'
	String get validate_only => 'Validate only';

	/// Banner listing what a scenario is missing; under sandbox.* rather than scenario_needs.* so it cannot be confused with the scenario_need.* labels it interpolates
	///
	/// en: 'Needs $needs. The push will still be sent, but this scenario cannot be observed yet.'
	String needs_banner({required Object needs}) => 'Needs ${needs}. The push will still be sent, but this scenario cannot be observed yet.';
}

// Path: send
class Translations$send$en {
	Translations$send$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Send button label
	///
	/// en: 'Send to this device'
	String get to_this_device => 'Send to this device';

	/// Send button label
	///
	/// en: 'Send to that token'
	String get to_that_token => 'Send to that token';

	/// Send button label
	///
	/// en: 'Send to topic "$topic"'
	String to_topic({required Object topic}) => 'Send to topic "${topic}"';

	/// Send button label
	///
	/// en: 'Send to the condition'
	String get to_condition => 'Send to the condition';

	/// Send button label
	///
	/// en: 'Send to every device'
	String get to_every_device => 'Send to every device';
}

// Path: send_target
class Translations$send_target$en {
	Translations$send_target$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Label of the delivery-target dropdown
	///
	/// en: 'Send to'
	String get label => 'Send to';

	/// Delivery-target choice
	///
	/// en: 'This device'
	String get this_device => 'This device';

	/// Delivery-target choice; the FCM term
	///
	/// en: 'Token'
	String get token => 'Token';

	/// Delivery-target choice
	///
	/// en: 'Topic'
	String get topic => 'Topic';

	/// Delivery-target choice
	///
	/// en: 'Condition'
	String get condition => 'Condition';

	/// Delivery-target choice
	///
	/// en: 'All devices'
	String get all_devices => 'All devices';

	/// Warning under the all-devices choice
	///
	/// en: 'Sending to every device needs a token registry the API does not have yet, so this will be refused.'
	String get all_devices_warning => 'Sending to every device needs a token registry the API does not have yet, so this will be refused.';
}

// Path: schedule_sheet
class Translations$schedule_sheet$en {
	Translations$schedule_sheet$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Section heading in the schedule sheet
	///
	/// en: 'Delay'
	String get delay => 'Delay';

	/// Section heading in the schedule sheet
	///
	/// en: 'Spacing'
	String get spacing => 'Spacing';

	/// Help text under Spacing
	///
	/// en: 'Added again for each message after the first, so a batch arrives spread out rather than as one burst.'
	String get spacing_help => 'Added again for each message after the first, so a batch arrives spread out rather than as one burst.';

	/// Confirm button in the schedule sheet; no ellipsis because this one acts
	///
	/// en: 'Schedule'
	String get confirm => 'Schedule';
}

// Path: preset_chip
class Translations$preset_chip$en {
	Translations$preset_chip$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Delay preset chip
	///
	/// en: '$value s'
	String seconds({required Object value}) => '${value} s';
}

// Path: not_received
class Translations$not_received$en {
	Translations$not_received$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Button reporting a push that did not show up
	///
	/// en: 'It never arrived'
	String get button => 'It never arrived';

	/// The same button once pressed; echoes the unpressed label deliberately
	///
	/// en: 'Reported as never arrived'
	String get reported => 'Reported as never arrived';
}

// Path: send_result
class Translations$send_result$en {
	Translations$send_result$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Result card after a validate-only send
	///
	/// en: '✓ Validated · message $messageId · trace $traceId · the payload was validated, not sent'
	String validated({required Object messageId, required Object traceId}) => '✓ Validated · message ${messageId} · trace ${traceId} · the payload was validated, not sent';

	/// Result card after a send
	///
	/// en: '✓ Sent · message $messageId · trace $traceId · it should appear in the Inbox shortly'
	String sent({required Object messageId, required Object traceId}) => '✓ Sent · message ${messageId} · trace ${traceId} · it should appear in the Inbox shortly';

	/// en: '(one) {✓ Scheduled · run $runId · $n message · nothing has been sent yet} (few) {✓ Scheduled · run $runId · $n messages · nothing has been sent yet} (other) {✓ Scheduled · run $runId · $n messages · nothing has been sent yet}'
	String scheduled({required num n, required Object runId}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n,
		one: '✓ Scheduled · run ${runId} · ${n} message · nothing has been sent yet',
		few: '✓ Scheduled · run ${runId} · ${n} messages · nothing has been sent yet',
		other: '✓ Scheduled · run ${runId} · ${n} messages · nothing has been sent yet',
	);
}

// Path: countdown
class Translations$countdown$en {
	Translations$countdown$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Unit under the countdown's number
	///
	/// en: 'seconds'
	String get seconds => 'seconds';

	/// Instruction on the countdown screen
	///
	/// en: 'Swipe the app away from recents now. The push is already scheduled on the server, so it will arrive whether this app is running or not.'
	String get swipe_away => 'Swipe the app away from recents now. The push is already scheduled on the server, so it will arrive whether this app is running or not.';

	/// Explains why the button dims rather than switches off
	///
	/// en: 'An ordinary app cannot switch the display off — only dim it and let go of the wakelock, so the system times out on its own.'
	String get dim_note => 'An ordinary app cannot switch the display off — only dim it and let go of the wakelock, so the system times out on its own.';

	/// Button on the countdown screen
	///
	/// en: 'Dim the screen'
	String get dim_screen => 'Dim the screen';

	/// Opens the OS battery settings
	///
	/// en: 'Battery settings'
	String get battery_settings => 'Battery settings';
}

// Path: telemetry
class Translations$telemetry$en {
	Translations$telemetry$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$telemetry$tab$en tab = Translations$telemetry$tab$en._(_root);
	late final Translations$telemetry$events$en events = Translations$telemetry$events$en._(_root);
	late final Translations$telemetry$event_row$en event_row = Translations$telemetry$event_row$en._(_root);
	late final Translations$telemetry$latency$en latency = Translations$telemetry$latency$en._(_root);
}

// Path: api
class Translations$api$en {
	Translations$api$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Shown when the local API is not answering; identical in all three data sources
	///
	/// en: 'Could not reach $baseUrl — is the API running? On a physical device, run: adb reverse tcp:8080 tcp:8080 ($error)'
	String unreachable({required Object baseUrl, required Object error}) => 'Could not reach ${baseUrl} — is the API running?\nOn a physical device, run: adb reverse tcp:8080 tcp:8080\n(${error})';

	/// Shown for a non-200; the body is the server's own text and stays as sent
	///
	/// en: 'The API answered $status: $body'
	String answered_status({required Object status, required Object body}) => 'The API answered ${status}: ${body}';

	/// A 200 whose body is not JSON
	///
	/// en: 'The API answered 200 with something unreadable: $error'
	String answered_unreadable({required Object error}) => 'The API answered 200 with something unreadable: ${error}';

	/// A 200 whose body is not JSON
	///
	/// en: 'The API answered 200 with something that is not JSON: $error'
	String answered_not_json({required Object error}) => 'The API answered 200 with something that is not JSON: ${error}';

	/// A 200 whose body parses but is the wrong shape
	///
	/// en: 'The API answered 200 with $type where a list was expected.'
	String answered_wrong_shape({required Object type}) => 'The API answered 200 with ${type} where a list was expected.';

	/// A 200 whose body parses but is the wrong shape
	///
	/// en: 'The API answered 200 with $type where a list of runs was expected.'
	String answered_wrong_shape_runs({required Object type}) => 'The API answered 200 with ${type} where a list of runs was expected.';

	/// A 200 carrying an item this build's model rejects
	///
	/// en: 'The API answered 200 with $what this build cannot read: $error'
	String answered_unreadable_item({required Object what, required Object error}) => 'The API answered 200 with ${what} this build cannot read: ${error}';

	late final Translations$api$item$en item = Translations$api$item$en._(_root);

	/// A decoded JSON value used as a map that is not one. All THREE throw sites take this key, http_notification_sender.dart included: its local `on FormatException` does not discard the message, it forwards error.message into api.answered_unreadable, so a bare literal there would surface as an English fragment inside a Czech sentence
	///
	/// en: 'Expected a JSON object, got $type.'
	String expected_object({required Object type}) => 'Expected a JSON object, got ${type}.';
}

// Path: scenario
class Translations$scenario$en {
	Translations$scenario$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$scenario$a1_notification_only$en a1_notification_only = Translations$scenario$a1_notification_only$en._(_root);
	late final Translations$scenario$a2_data_only$en a2_data_only = Translations$scenario$a2_data_only$en._(_root);
	late final Translations$scenario$a3_hybrid$en a3_hybrid = Translations$scenario$a3_hybrid$en._(_root);
	late final Translations$scenario$a4_no_display$en a4_no_display = Translations$scenario$a4_no_display$en._(_root);
	late final Translations$scenario$b1_foreground$en b1_foreground = Translations$scenario$b1_foreground$en._(_root);
	late final Translations$scenario$b2_background$en b2_background = Translations$scenario$b2_background$en._(_root);
	late final Translations$scenario$b3_killed$en b3_killed = Translations$scenario$b3_killed$en._(_root);
	late final Translations$scenario$b4_after_reboot$en b4_after_reboot = Translations$scenario$b4_after_reboot$en._(_root);
	late final Translations$scenario$b5_force_stopped$en b5_force_stopped = Translations$scenario$b5_force_stopped$en._(_root);
	late final Translations$scenario$b6_token_refresh$en b6_token_refresh = Translations$scenario$b6_token_refresh$en._(_root);
	late final Translations$scenario$c1_priority_high$en c1_priority_high = Translations$scenario$c1_priority_high$en._(_root);
	late final Translations$scenario$c2_priority_normal$en c2_priority_normal = Translations$scenario$c2_priority_normal$en._(_root);
	late final Translations$scenario$c3_ttl_zero$en c3_ttl_zero = Translations$scenario$c3_ttl_zero$en._(_root);
	late final Translations$scenario$c4_ttl_long$en c4_ttl_long = Translations$scenario$c4_ttl_long$en._(_root);
	late final Translations$scenario$c5_collapse_key$en c5_collapse_key = Translations$scenario$c5_collapse_key$en._(_root);
	late final Translations$scenario$c6_doze_test$en c6_doze_test = Translations$scenario$c6_doze_test$en._(_root);
	late final Translations$scenario$c7_standby_bucket$en c7_standby_bucket = Translations$scenario$c7_standby_bucket$en._(_root);
	late final Translations$scenario$d1_importance_high$en d1_importance_high = Translations$scenario$d1_importance_high$en._(_root);
	late final Translations$scenario$d2_importance_default$en d2_importance_default = Translations$scenario$d2_importance_default$en._(_root);
	late final Translations$scenario$d3_importance_low$en d3_importance_low = Translations$scenario$d3_importance_low$en._(_root);
	late final Translations$scenario$d4_importance_min$en d4_importance_min = Translations$scenario$d4_importance_min$en._(_root);
	late final Translations$scenario$d5_custom_sound$en d5_custom_sound = Translations$scenario$d5_custom_sound$en._(_root);
	late final Translations$scenario$d6_vibration_pattern$en d6_vibration_pattern = Translations$scenario$d6_vibration_pattern$en._(_root);
	late final Translations$scenario$d7_channel_immutability$en d7_channel_immutability = Translations$scenario$d7_channel_immutability$en._(_root);
	late final Translations$scenario$d8_channel_group$en d8_channel_group = Translations$scenario$d8_channel_group$en._(_root);
	late final Translations$scenario$e1_long_text$en e1_long_text = Translations$scenario$e1_long_text$en._(_root);
	late final Translations$scenario$e2_image_remote$en e2_image_remote = Translations$scenario$e2_image_remote$en._(_root);
	late final Translations$scenario$e3_image_local$en e3_image_local = Translations$scenario$e3_image_local$en._(_root);
	late final Translations$scenario$e4_image_huge$en e4_image_huge = Translations$scenario$e4_image_huge$en._(_root);
	late final Translations$scenario$e5_image_404$en e5_image_404 = Translations$scenario$e5_image_404$en._(_root);
	late final Translations$scenario$e6_large_icon$en e6_large_icon = Translations$scenario$e6_large_icon$en._(_root);
	late final Translations$scenario$e7_inbox_style$en e7_inbox_style = Translations$scenario$e7_inbox_style$en._(_root);
	late final Translations$scenario$e8_messaging_style$en e8_messaging_style = Translations$scenario$e8_messaging_style$en._(_root);
	late final Translations$scenario$e9_progress$en e9_progress = Translations$scenario$e9_progress$en._(_root);
	late final Translations$scenario$e10_color_and_icon$en e10_color_and_icon = Translations$scenario$e10_color_and_icon$en._(_root);
	late final Translations$scenario$e11_emoji_rtl$en e11_emoji_rtl = Translations$scenario$e11_emoji_rtl$en._(_root);
	late final Translations$scenario$f1_actions$en f1_actions = Translations$scenario$f1_actions$en._(_root);
	late final Translations$scenario$f2_inline_reply$en f2_inline_reply = Translations$scenario$f2_inline_reply$en._(_root);
	late final Translations$scenario$f3_deeplink_foreground$en f3_deeplink_foreground = Translations$scenario$f3_deeplink_foreground$en._(_root);
	late final Translations$scenario$f4_deeplink_background$en f4_deeplink_background = Translations$scenario$f4_deeplink_background$en._(_root);
	late final Translations$scenario$f5_deeplink_killed$en f5_deeplink_killed = Translations$scenario$f5_deeplink_killed$en._(_root);
	late final Translations$scenario$f6_delete_intent$en f6_delete_intent = Translations$scenario$f6_delete_intent$en._(_root);
	late final Translations$scenario$f7_ongoing$en f7_ongoing = Translations$scenario$f7_ongoing$en._(_root);
	late final Translations$scenario$f8_full_screen_intent$en f8_full_screen_intent = Translations$scenario$f8_full_screen_intent$en._(_root);
	late final Translations$scenario$f9_trampoline$en f9_trampoline = Translations$scenario$f9_trampoline$en._(_root);
	late final Translations$scenario$g1_group_summary$en g1_group_summary = Translations$scenario$g1_group_summary$en._(_root);
	late final Translations$scenario$g2_update_same_id$en g2_update_same_id = Translations$scenario$g2_update_same_id$en._(_root);
	late final Translations$scenario$g3_badge$en g3_badge = Translations$scenario$g3_badge$en._(_root);
	late final Translations$scenario$g4_badge_ios$en g4_badge_ios = Translations$scenario$g4_badge_ios$en._(_root);
	late final Translations$scenario$h1_dnd_bypass$en h1_dnd_bypass = Translations$scenario$h1_dnd_bypass$en._(_root);
	late final Translations$scenario$h2_category_alarm$en h2_category_alarm = Translations$scenario$h2_category_alarm$en._(_root);
	late final Translations$scenario$h3_ios_time_sensitive$en h3_ios_time_sensitive = Translations$scenario$h3_ios_time_sensitive$en._(_root);
	late final Translations$scenario$h4_ios_critical$en h4_ios_critical = Translations$scenario$h4_ios_critical$en._(_root);
	late final Translations$scenario$h5_ios_passive$en h5_ios_passive = Translations$scenario$h5_ios_passive$en._(_root);
	late final Translations$scenario$i1_silent_no_sound$en i1_silent_no_sound = Translations$scenario$i1_silent_no_sound$en._(_root);
	late final Translations$scenario$i2_silent_data_sync$en i2_silent_data_sync = Translations$scenario$i2_silent_data_sync$en._(_root);
	late final Translations$scenario$i3_ios_content_available$en i3_ios_content_available = Translations$scenario$i3_ios_content_available$en._(_root);
	late final Translations$scenario$i4_burst$en i4_burst = Translations$scenario$i4_burst$en._(_root);
	late final Translations$scenario$j1_topic$en j1_topic = Translations$scenario$j1_topic$en._(_root);
	late final Translations$scenario$j2_condition$en j2_condition = Translations$scenario$j2_condition$en._(_root);
	late final Translations$scenario$j3_multicast$en j3_multicast = Translations$scenario$j3_multicast$en._(_root);
	late final Translations$scenario$k1_payload_oversize$en k1_payload_oversize = Translations$scenario$k1_payload_oversize$en._(_root);
	late final Translations$scenario$k2_invalid_token$en k2_invalid_token = Translations$scenario$k2_invalid_token$en._(_root);
	late final Translations$scenario$k3_permission_denied$en k3_permission_denied = Translations$scenario$k3_permission_denied$en._(_root);
	late final Translations$scenario$k4_notifications_disabled$en k4_notifications_disabled = Translations$scenario$k4_notifications_disabled$en._(_root);
	late final Translations$scenario$k5_battery_restricted$en k5_battery_restricted = Translations$scenario$k5_battery_restricted$en._(_root);
}

// Path: scenario_group
class Translations$scenario_group$en {
	Translations$scenario_group$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Display name of scenario group A
	///
	/// en: 'A — Basic delivery'
	String get a => 'A — Basic delivery';

	/// Display name of scenario group B
	///
	/// en: 'B — Application states'
	String get b => 'B — Application states';

	/// Display name of scenario group C
	///
	/// en: 'C — Priority and delivery window'
	String get c => 'C — Priority and delivery window';

	/// Display name of scenario group D
	///
	/// en: 'D — Channels and importance'
	String get d => 'D — Channels and importance';

	/// Display name of scenario group E
	///
	/// en: 'E — Appearance'
	String get e => 'E — Appearance';

	/// Display name of scenario group F
	///
	/// en: 'F — Interaction'
	String get f => 'F — Interaction';

	/// Display name of scenario group G
	///
	/// en: 'G — Groups, badge, updates'
	String get g => 'G — Groups, badge, updates';

	/// Display name of scenario group H
	///
	/// en: 'H — Intrusive and priority'
	String get h => 'H — Intrusive and priority';

	/// Display name of scenario group I
	///
	/// en: 'I — Silent and data'
	String get i => 'I — Silent and data';

	/// Display name of scenario group J
	///
	/// en: 'J — Targeting'
	String get j => 'J — Targeting';

	/// Display name of scenario group K
	///
	/// en: 'K — Edge cases and errors'
	String get k => 'K — Edge cases and errors';
}

// Path: scenario_need
class Translations$scenario_need$en {
	Translations$scenario_need$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Label for the channels scenario need
	///
	/// en: 'notification channels'
	String get channels => 'notification channels';

	/// Label for the styles scenario need
	///
	/// en: 'notification styles'
	String get styles => 'notification styles';

	/// Label for the interaction scenario need
	///
	/// en: 'notification actions'
	String get interaction => 'notification actions';

	/// Label for the badge scenario need
	///
	/// en: 'launcher badge'
	String get badge => 'launcher badge';

	/// Label for the targeting scenario need
	///
	/// en: 'a device registry'
	String get targeting => 'a device registry';

	/// en: 'a manual step'
	String get manual_step => 'a manual step';

	/// en: 'external approval'
	String get external_approval => 'external approval';
}

// Path: channels
class Translations$channels$en {
	Translations$channels$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$channels$fcm_sample_high$en fcm_sample_high = Translations$channels$fcm_sample_high$en._(_root);
	late final Translations$channels$importance_high$en importance_high = Translations$channels$importance_high$en._(_root);
	late final Translations$channels$importance_default$en importance_default = Translations$channels$importance_default$en._(_root);
	late final Translations$channels$importance_low$en importance_low = Translations$channels$importance_low$en._(_root);
	late final Translations$channels$importance_min$en importance_min = Translations$channels$importance_min$en._(_root);
	late final Translations$channels$custom_sound$en custom_sound = Translations$channels$custom_sound$en._(_root);
	late final Translations$channels$vibration_pattern$en vibration_pattern = Translations$channels$vibration_pattern$en._(_root);
	late final Translations$channels$chat_v1$en chat_v1 = Translations$channels$chat_v1$en._(_root);
	late final Translations$channels$chat_v2$en chat_v2 = Translations$channels$chat_v2$en._(_root);
	late final Translations$channels$dnd_bypass$en dnd_bypass = Translations$channels$dnd_bypass$en._(_root);
	late final Translations$channels$alarms$en alarms = Translations$channels$alarms$en._(_root);
	late final Translations$channels$group$en group = Translations$channels$group$en._(_root);

	/// AppBar title on the Channels page
	///
	/// en: 'Notification channels'
	String get title => 'Notification channels';

	/// Column heading: what the app asked Android for
	///
	/// en: 'Requested'
	String get requested => 'Requested';

	/// Column heading: what Android answered
	///
	/// en: 'Reported by the system'
	String get reported => 'Reported by the system';

	/// Shown when the system holds no channel with this id
	///
	/// en: 'Not registered'
	String get not_registered => 'Not registered';

	/// Row label on a channel card
	///
	/// en: 'Importance'
	String get importance => 'Importance';

	/// Row label on a channel card
	///
	/// en: 'Sound'
	String get sound => 'Sound';

	/// Row label on a channel card
	///
	/// en: 'Vibration'
	String get vibration => 'Vibration';

	/// Row label on a channel card
	///
	/// en: 'Bypasses Do Not Disturb'
	String get bypass_dnd => 'Bypasses Do Not Disturb';

	/// Row label on a channel card; not channels.group.chat.name, which already exists as a nested key for the group heading
	///
	/// en: 'Group'
	String get group_label => 'Group';

	/// Row label on a channel card
	///
	/// en: 'Shows a badge'
	String get badge => 'Shows a badge';

	/// Button on chat_v1; performs d7 by asking Android to change a frozen importance
	///
	/// en: 'Try to lower it'
	String get try_lower => 'Try to lower it';

	/// Explains what the d7 button does
	///
	/// en: 'Importance is frozen when a channel is created. Press this and watch the reported value stay put.'
	String get immutability_hint => 'Importance is frozen when a channel is created. Press this and watch the reported value stay put.';

	/// AppBar action on the Channels page
	///
	/// en: 'Refresh'
	String get refresh => 'Refresh';
}

// Path: shell.title
class Translations$shell$title$en {
	Translations$shell$title$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// AppBar title for the inbox destination
	///
	/// en: 'Push inbox'
	String get inbox => 'Push inbox';

	/// AppBar title
	///
	/// en: 'Scenarios'
	String get scenarios => 'Scenarios';

	/// AppBar title; the product's own term
	///
	/// en: 'Sandbox'
	String get sandbox => 'Sandbox';

	/// AppBar title
	///
	/// en: 'Runs'
	String get runs => 'Runs';

	/// AppBar title
	///
	/// en: 'Telemetry'
	String get telemetry => 'Telemetry';
}

// Path: telemetry.tab
class Translations$telemetry$tab$en {
	Translations$telemetry$tab$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Tab on the Telemetry page
	///
	/// en: 'Events'
	String get events => 'Events';

	/// Tab on the Telemetry page
	///
	/// en: 'Latency'
	String get latency => 'Latency';
}

// Path: telemetry.events
class Translations$telemetry$events$en {
	Translations$telemetry$events$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Empty state on the Events tab
	///
	/// en: 'Nothing recorded yet. Send a push from the Sandbox, then reload.'
	String get empty => 'Nothing recorded yet. Send a push from the Sandbox, then reload.';
}

// Path: telemetry.event_row
class Translations$telemetry$event_row$en {
	Translations$telemetry$event_row$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Caveat appended to a stamp taken before the request was handled
	///
	/// en: ' · (request received)'
	String get request_received => ' · (request received)';
}

// Path: telemetry.latency
class Translations$telemetry$latency$en {
	Translations$telemetry$latency$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Empty state on the Latency tab
	///
	/// en: 'No measurements yet. A row needs both a send and an arrival for the same trace.'
	String get empty => 'No measurements yet. A row needs both a send and an arrival for the same trace.';

	/// Column header on the latency table
	///
	/// en: 'scenario'
	String get scenario_column => 'scenario';

	/// Footnote under the latency table
	///
	/// en: '`sent` is when the API received the request, not when FCM answered, so every figure above includes the time the FCM call took.'
	String get footnote => '`sent` is when the API received the request, not when FCM answered, so every figure above includes the time the FCM call took.';
}

// Path: api.item
class Translations$api$item$en {
	Translations$api$item$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Names the item kind in api.answered_unreadable_item
	///
	/// en: 'an event'
	String get event => 'an event';

	/// Names the item kind in api.answered_unreadable_item
	///
	/// en: 'a latency row'
	String get latency_row => 'a latency row';
}

// Path: scenario.a1_notification_only
class Translations$scenario$a1_notification_only$en {
	Translations$scenario$a1_notification_only$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario a1_notification_only
	///
	/// en: 'Notification-only payload'
	String get title => 'Notification-only payload';

	/// Description of scenario a1_notification_only
	///
	/// en: 'Watch which layer drew it — the system while backgrounded, the app while foregrounded — and how the icon and accent colour come out.'
	String get description => 'Watch which layer drew it — the system while backgrounded, the app while foregrounded — and how the icon and accent colour come out.';
}

// Path: scenario.a2_data_only
class Translations$scenario$a2_data_only$en {
	Translations$scenario$a2_data_only$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario a2_data_only
	///
	/// en: 'Data-only payload, drawn locally'
	String get title => 'Data-only payload, drawn locally';

	/// Description of scenario a2_data_only
	///
	/// en: 'Nothing draws this but the app. Watch whether it arrives at all with the app killed, which is the case data-only delivery exists for.'
	String get description => 'Nothing draws this but the app. Watch whether it arrives at all with the app killed, which is the case data-only delivery exists for.';

	/// Expectation caveat for scenario a2_data_only
	///
	/// en: 'On iOS a data-only push needs content-available and is throttled; see i3_ios_content_available.'
	String get expectation => 'On iOS a data-only push needs content-available and is throttled; see i3_ios_content_available.';
}

// Path: scenario.a3_hybrid
class Translations$scenario$a3_hybrid$en {
	Translations$scenario$a3_hybrid$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario a3_hybrid
	///
	/// en: 'notification and data together'
	String get title => 'notification and data together';

	/// Description of scenario a3_hybrid
	///
	/// en: 'The common shape in production. Watch whether the data map reaches the handler after a tap, which is where deep links get their arguments.'
	String get description => 'The common shape in production. Watch whether the data map reaches the handler after a tap, which is where deep links get their arguments.';
}

// Path: scenario.a4_no_display
class Translations$scenario$a4_no_display$en {
	Translations$scenario$a4_no_display$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario a4_no_display
	///
	/// en: 'Data logged silently, drawn blank'
	String get title => 'Data logged silently, drawn blank';

	/// Description of scenario a4_no_display
	///
	/// en: 'A silent synchronisation: the handler runs and writes a log line. Nothing suppresses a titleless banner, so a tray entry still appears — icon and app name, no text. The observable difference from a1 is the missing text, not a missing notification. Watch the inbox for the log line; the tray has nothing to read.'
	String get description => 'A silent synchronisation: the handler runs and writes a log line. Nothing suppresses a titleless banner, so a tray entry still appears — icon and app name, no text. The observable difference from a1 is the missing text, not a missing notification. Watch the inbox for the log line; the tray has nothing to read.';
}

// Path: scenario.b1_foreground
class Translations$scenario$b1_foreground$en {
	Translations$scenario$b1_foreground$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario b1_foreground
	///
	/// en: 'Delivered with the app in the foreground'
	String get title => 'Delivered with the app in the foreground';

	/// Description of scenario b1_foreground
	///
	/// en: 'onMessage fires and nothing is drawn by the system, so the app must draw it. Watch that a banner appears at all.'
	String get description => 'onMessage fires and nothing is drawn by the system, so the app must draw it. Watch that a banner appears at all.';
}

// Path: scenario.b2_background
class Translations$scenario$b2_background$en {
	Translations$scenario$b2_background$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario b2_background
	///
	/// en: 'App backgrounded, screen locked'
	String get title => 'App backgrounded, screen locked';

	/// Description of scenario b2_background
	///
	/// en: 'The system draws this one. Watch whether it reaches the lock screen and how much of it is shown there.'
	String get description => 'The system draws this one. Watch whether it reaches the lock screen and how much of it is shown there.';

	/// Manual steps for scenario b2_background
	///
	/// en: 'Background the app with the home button, then lock the screen. Send from another machine, or use validate-only first to check the payload.'
	String get manual_steps => 'Background the app with the home button, then lock the screen. Send from another machine, or use validate-only first to check the payload.';
}

// Path: scenario.b3_killed
class Translations$scenario$b3_killed$en {
	Translations$scenario$b3_killed$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario b3_killed
	///
	/// en: 'App swiped out of recents'
	String get title => 'App swiped out of recents';

	/// Description of scenario b3_killed
	///
	/// en: 'The hardest case, and the reason delayed sending exists: the send has to happen after the app is gone. Watch whether the data handler runs.'
	String get description => 'The hardest case, and the reason delayed sending exists: the send has to happen after the app is gone. Watch whether the data handler runs.';
}

// Path: scenario.b4_after_reboot
class Translations$scenario$b4_after_reboot$en {
	Translations$scenario$b4_after_reboot$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario b4_after_reboot
	///
	/// en: 'After a reboot, app never opened'
	String get title => 'After a reboot, app never opened';

	/// Description of scenario b4_after_reboot
	///
	/// en: 'Until the app is opened once after boot, some manufacturers hold its background work entirely. Watch whether anything arrives.'
	String get description => 'Until the app is opened once after boot, some manufacturers hold its background work entirely. Watch whether anything arrives.';

	/// Manual steps for scenario b4_after_reboot
	///
	/// en: 'adb reboot — then do NOT open the app. Wait for the lock screen and send.'
	String get manual_steps => 'adb reboot — then do NOT open the app. Wait for the lock screen and send.';
}

// Path: scenario.b5_force_stopped
class Translations$scenario$b5_force_stopped$en {
	Translations$scenario$b5_force_stopped$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario b5_force_stopped
	///
	/// en: 'After Force stop'
	String get title => 'After Force stop';

	/// Description of scenario b5_force_stopped
	///
	/// en: 'Force stop revokes the app's ability to be woken. This scenario exists to prove we know that, rather than to be debugged.'
	String get description => 'Force stop revokes the app\'s ability to be woken. This scenario exists to prove we know that, rather than to be debugged.';

	/// Expectation caveat for scenario b5_force_stopped
	///
	/// en: 'Expected to arrive: nothing. A force-stopped app receives no pushes at all until it is launched by hand. If something does arrive, that is the surprise worth investigating.'
	String get expectation => 'Expected to arrive: nothing. A force-stopped app receives no pushes at all until it is launched by hand. If something does arrive, that is the surprise worth investigating.';

	/// Manual steps for scenario b5_force_stopped
	///
	/// en: 'Settings › Apps › FCM Sample › Force stop. Then send, and expect nothing.'
	String get manual_steps => 'Settings › Apps › FCM Sample › Force stop. Then send, and expect nothing.';
}

// Path: scenario.b6_token_refresh
class Translations$scenario$b6_token_refresh$en {
	Translations$scenario$b6_token_refresh$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario b6_token_refresh
	///
	/// en: 'Token rotated by a reinstall or clear-data'
	String get title => 'Token rotated by a reinstall or clear-data';

	/// Description of scenario b6_token_refresh
	///
	/// en: 'The old token is dead and sending to it must fail loudly. Watch the Inbox page for the new token, and compare it with the old one.'
	String get description => 'The old token is dead and sending to it must fail loudly. Watch the Inbox page for the new token, and compare it with the old one.';

	/// Manual steps for scenario b6_token_refresh
	///
	/// en: 'adb shell pm clear cz.netglade.fcm_app — reopen the app and read the new token off the Inbox page. Sending to the old one should give UNREGISTERED, which is k2_invalid_token.'
	String get manual_steps => 'adb shell pm clear cz.netglade.fcm_app — reopen the app and read the new token off the Inbox page. Sending to the old one should give UNREGISTERED, which is k2_invalid_token.';
}

// Path: scenario.c1_priority_high
class Translations$scenario$c1_priority_high$en {
	Translations$scenario$c1_priority_high$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario c1_priority_high
	///
	/// en: 'android.priority HIGH'
	String get title => 'android.priority HIGH';

	/// Description of scenario c1_priority_high
	///
	/// en: 'Wakes a dozing device. Watch how quickly it lands with the screen off compared with c2.'
	String get description => 'Wakes a dozing device. Watch how quickly it lands with the screen off compared with c2.';
}

// Path: scenario.c2_priority_normal
class Translations$scenario$c2_priority_normal$en {
	Translations$scenario$c2_priority_normal$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario c2_priority_normal
	///
	/// en: 'android.priority NORMAL'
	String get title => 'android.priority NORMAL';

	/// Description of scenario c2_priority_normal
	///
	/// en: 'May wait for the next maintenance window. Watch for a delay with the screen off — this is the usual cause of a "missing" push.'
	String get description => 'May wait for the next maintenance window. Watch for a delay with the screen off — this is the usual cause of a "missing" push.';
}

// Path: scenario.c3_ttl_zero
class Translations$scenario$c3_ttl_zero$en {
	Translations$scenario$c3_ttl_zero$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario c3_ttl_zero
	///
	/// en: 'android.ttl 0s — now or never'
	String get title => 'android.ttl 0s — now or never';

	/// Description of scenario c3_ttl_zero
	///
	/// en: 'FCM makes one attempt and discards the message if the device is not reachable. Watch that an offline device never receives it.'
	String get description => 'FCM makes one attempt and discards the message if the device is not reachable. Watch that an offline device never receives it.';
}

// Path: scenario.c4_ttl_long
class Translations$scenario$c4_ttl_long$en {
	Translations$scenario$c4_ttl_long$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario c4_ttl_long
	///
	/// en: 'android.ttl 86400s — a day of retries'
	String get title => 'android.ttl 86400s — a day of retries';

	/// Description of scenario c4_ttl_long
	///
	/// en: 'Held for 24 hours. Watch it arrive when the network comes back, long after it was sent.'
	String get description => 'Held for 24 hours. Watch it arrive when the network comes back, long after it was sent.';
}

// Path: scenario.c5_collapse_key
class Translations$scenario$c5_collapse_key$en {
	Translations$scenario$c5_collapse_key$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario c5_collapse_key
	///
	/// en: 'Five sends sharing a collapse_key, offline'
	String get title => 'Five sends sharing a collapse_key, offline';

	/// Description of scenario c5_collapse_key
	///
	/// en: 'Only the last should survive. Watch that one notification appears, not five, once the network returns.'
	String get description => 'Only the last should survive. Watch that one notification appears, not five, once the network returns.';

	/// Manual steps for scenario c5_collapse_key
	///
	/// en: 'Put the device in airplane mode. Send five times, changing the body each time. Restore the network: exactly one notification should appear, carrying the last body.'
	String get manual_steps => 'Put the device in airplane mode. Send five times, changing the body each time. Restore the network: exactly one notification should appear, carrying the last body.';
}

// Path: scenario.c6_doze_test
class Translations$scenario$c6_doze_test$en {
	Translations$scenario$c6_doze_test$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario c6_doze_test
	///
	/// en: 'Delivery while the device is in Doze'
	String get title => 'Delivery while the device is in Doze';

	/// Description of scenario c6_doze_test
	///
	/// en: 'Real Doze behaviour, not a simulation. Watch which priorities break through and which are held.'
	String get description => 'Real Doze behaviour, not a simulation. Watch which priorities break through and which are held.';

	/// Manual steps for scenario c6_doze_test
	///
	/// en: 'adb shell dumpsys deviceidle force-idle — send, then adb shell dumpsys deviceidle unforce to restore.'
	String get manual_steps => 'adb shell dumpsys deviceidle force-idle — send, then adb shell dumpsys deviceidle unforce to restore.';
}

// Path: scenario.c7_standby_bucket
class Translations$scenario$c7_standby_bucket$en {
	Translations$scenario$c7_standby_bucket$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario c7_standby_bucket
	///
	/// en: 'App in the restricted standby bucket'
	String get title => 'App in the restricted standby bucket';

	/// Description of scenario c7_standby_bucket
	///
	/// en: 'The harshest state Android imposes on an unused app. Watch whether a HIGH priority push still arrives.'
	String get description => 'The harshest state Android imposes on an unused app. Watch whether a HIGH priority push still arrives.';

	/// Manual steps for scenario c7_standby_bucket
	///
	/// en: 'adb shell am set-standby-bucket cz.netglade.fcm_app restricted — check with adb shell am get-standby-bucket cz.netglade.fcm_app.'
	String get manual_steps => 'adb shell am set-standby-bucket cz.netglade.fcm_app restricted — check with adb shell am get-standby-bucket cz.netglade.fcm_app.';
}

// Path: scenario.d1_importance_high
class Translations$scenario$d1_importance_high$en {
	Translations$scenario$d1_importance_high$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario d1_importance_high
	///
	/// en: 'IMPORTANCE_HIGH — heads-up banner'
	String get title => 'IMPORTANCE_HIGH — heads-up banner';

	/// Description of scenario d1_importance_high
	///
	/// en: 'Watch for a banner that floats over the current app, with sound.'
	String get description => 'Watch for a banner that floats over the current app, with sound.';
}

// Path: scenario.d2_importance_default
class Translations$scenario$d2_importance_default$en {
	Translations$scenario$d2_importance_default$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario d2_importance_default
	///
	/// en: 'IMPORTANCE_DEFAULT — sound, no banner'
	String get title => 'IMPORTANCE_DEFAULT — sound, no banner';

	/// Description of scenario d2_importance_default
	///
	/// en: 'Watch for a sound and a tray entry, but nothing floating.'
	String get description => 'Watch for a sound and a tray entry, but nothing floating.';
}

// Path: scenario.d3_importance_low
class Translations$scenario$d3_importance_low$en {
	Translations$scenario$d3_importance_low$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario d3_importance_low
	///
	/// en: 'IMPORTANCE_LOW — silent'
	String get title => 'IMPORTANCE_LOW — silent';

	/// Description of scenario d3_importance_low
	///
	/// en: 'Visible but with no sound and no vibration. Watch that it is genuinely silent rather than quiet.'
	String get description => 'Visible but with no sound and no vibration. Watch that it is genuinely silent rather than quiet.';
}

// Path: scenario.d4_importance_min
class Translations$scenario$d4_importance_min$en {
	Translations$scenario$d4_importance_min$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario d4_importance_min
	///
	/// en: 'IMPORTANCE_MIN — status bar only'
	String get title => 'IMPORTANCE_MIN — status bar only';

	/// Description of scenario d4_importance_min
	///
	/// en: 'No icon in the status bar on some versions; only in the shade. Watch where it appears at all.'
	String get description => 'No icon in the status bar on some versions; only in the shade. Watch where it appears at all.';
}

// Path: scenario.d5_custom_sound
class Translations$scenario$d5_custom_sound$en {
	Translations$scenario$d5_custom_sound$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario d5_custom_sound
	///
	/// en: 'A custom sound on the channel'
	String get title => 'A custom sound on the channel';

	/// Description of scenario d5_custom_sound
	///
	/// en: 'The sound is a channel property, so changing it needs a new channel. Watch that the custom sound plays rather than the default.'
	String get description => 'The sound is a channel property, so changing it needs a new channel. Watch that the custom sound plays rather than the default.';

	/// Expectation caveat for scenario d5_custom_sound
	///
	/// en: 'The named resource must exist in android/app/src/main/res/raw. A missing file falls back to the default sound silently.'
	String get expectation => 'The named resource must exist in android/app/src/main/res/raw. A missing file falls back to the default sound silently.';
}

// Path: scenario.d6_vibration_pattern
class Translations$scenario$d6_vibration_pattern$en {
	Translations$scenario$d6_vibration_pattern$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario d6_vibration_pattern
	///
	/// en: 'A custom vibration pattern'
	String get title => 'A custom vibration pattern';

	/// Description of scenario d6_vibration_pattern
	///
	/// en: 'Alternating vibrate and pause durations. Watch that the pattern is the one asked for rather than the channel default.'
	String get description => 'Alternating vibrate and pause durations. Watch that the pattern is the one asked for rather than the channel default.';
}

// Path: scenario.d7_channel_immutability
class Translations$scenario$d7_channel_immutability$en {
	Translations$scenario$d7_channel_immutability$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario d7_channel_immutability
	///
	/// en: 'Changing an existing channel — Android will ignore it'
	String get title => 'Changing an existing channel — Android will ignore it';

	/// Description of scenario d7_channel_immutability
	///
	/// en: 'Re-create chat_v1 with a different importance and watch Android ignore the change completely. This is the demonstration of why channels carry a version in their id.'
	String get description => 'Re-create chat_v1 with a different importance and watch Android ignore the change completely. This is the demonstration of why channels carry a version in their id.';

	/// Expectation caveat for scenario d7_channel_immutability
	///
	/// en: 'The importance shown on the channel screen stays at its original value. The only fix is a new channel — chat_v2 — which is what d8 uses.'
	String get expectation => 'The importance shown on the channel screen stays at its original value. The only fix is a new channel — chat_v2 — which is what d8 uses.';
}

// Path: scenario.d8_channel_group
class Translations$scenario$d8_channel_group$en {
	Translations$scenario$d8_channel_group$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario d8_channel_group
	///
	/// en: 'Channels collected into a group'
	String get title => 'Channels collected into a group';

	/// Description of scenario d8_channel_group
	///
	/// en: 'Watch the system notification settings: the channels should appear nested under a named group rather than as a flat list.'
	String get description => 'Watch the system notification settings: the channels should appear nested under a named group rather than as a flat list.';
}

// Path: scenario.e1_long_text
class Translations$scenario$e1_long_text$en {
	Translations$scenario$e1_long_text$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e1_long_text
	///
	/// en: 'BigTextStyle with ~800 characters'
	String get title => 'BigTextStyle with ~800 characters';

	/// Description of scenario e1_long_text
	///
	/// en: 'Watch where the text is cut in the collapsed view, and whether expanding shows all of it. Diacritics are included because byte-length and character-length limits behave differently.'
	String get description => 'Watch where the text is cut in the collapsed view, and whether expanding shows all of it. Diacritics are included because byte-length and character-length limits behave differently.';
}

// Path: scenario.e2_image_remote
class Translations$scenario$e2_image_remote$en {
	Translations$scenario$e2_image_remote$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e2_image_remote
	///
	/// en: 'notification.image — fetched by the platform'
	String get title => 'notification.image — fetched by the platform';

	/// Description of scenario e2_image_remote
	///
	/// en: 'FCM passes a URL and the platform downloads it. Watch that it appears expanded, and how long it takes on a slow connection.'
	String get description => 'FCM passes a URL and the platform downloads it. Watch that it appears expanded, and how long it takes on a slow connection.';

	/// Expectation caveat for scenario e2_image_remote
	///
	/// en: 'Android does this natively. iOS requires a Notification Service Extension, which this app does not ship, so nothing will render there.'
	String get expectation => 'Android does this natively. iOS requires a Notification Service Extension, which this app does not ship, so nothing will render there.';
}

// Path: scenario.e3_image_local
class Translations$scenario$e3_image_local$en {
	Translations$scenario$e3_image_local$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e3_image_local
	///
	/// en: 'Image downloaded by the data handler'
	String get title => 'Image downloaded by the data handler';

	/// Description of scenario e3_image_local
	///
	/// en: 'The app fetches the URL itself and builds a BigPictureStyle. Compare the result and the timing against e2.'
	String get description => 'The app fetches the URL itself and builds a BigPictureStyle. Compare the result and the timing against e2.';
}

// Path: scenario.e4_image_huge
class Translations$scenario$e4_image_huge$en {
	Translations$scenario$e4_image_huge$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e4_image_huge
	///
	/// en: 'A 4000×3000 image'
	String get title => 'A 4000×3000 image';

	/// Description of scenario e4_image_huge
	///
	/// en: 'Watch for a resize, an out-of-memory kill, or a silent failure where the text arrives and the picture does not.'
	String get description => 'Watch for a resize, an out-of-memory kill, or a silent failure where the text arrives and the picture does not.';
}

// Path: scenario.e5_image_404
class Translations$scenario$e5_image_404$en {
	Translations$scenario$e5_image_404$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e5_image_404
	///
	/// en: 'An image URL that does not resolve'
	String get title => 'An image URL that does not resolve';

	/// Description of scenario e5_image_404
	///
	/// en: 'The important question is whether the text still arrives. A push that vanishes because its picture 404s is a bad failure mode.'
	String get description => 'The important question is whether the text still arrives. A push that vanishes because its picture 404s is a bad failure mode.';
}

// Path: scenario.e6_large_icon
class Translations$scenario$e6_large_icon$en {
	Translations$scenario$e6_large_icon$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e6_large_icon
	///
	/// en: 'A large icon beside the text'
	String get title => 'A large icon beside the text';

	/// Description of scenario e6_large_icon
	///
	/// en: 'The round avatar slot, distinct from the small status-bar icon. Watch that it is circular and not stretched.'
	String get description => 'The round avatar slot, distinct from the small status-bar icon. Watch that it is circular and not stretched.';
}

// Path: scenario.e7_inbox_style
class Translations$scenario$e7_inbox_style$en {
	Translations$scenario$e7_inbox_style$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e7_inbox_style
	///
	/// en: 'InboxStyle with seven lines'
	String get title => 'InboxStyle with seven lines';

	/// Description of scenario e7_inbox_style
	///
	/// en: 'Watch how many lines are actually shown when expanded — Android caps it, and the cap is lower than most people expect.'
	String get description => 'Watch how many lines are actually shown when expanded — Android caps it, and the cap is lower than most people expect.';
}

// Path: scenario.e8_messaging_style
class Translations$scenario$e8_messaging_style$en {
	Translations$scenario$e8_messaging_style$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e8_messaging_style
	///
	/// en: 'MessagingStyle with several senders'
	String get title => 'MessagingStyle with several senders';

	/// Description of scenario e8_messaging_style
	///
	/// en: 'The chat layout, with a name and avatar per message. Watch the grouping and the ordering.'
	String get description => 'The chat layout, with a name and avatar per message. Watch the grouping and the ordering.';
}

// Path: scenario.e9_progress
class Translations$scenario$e9_progress$en {
	Translations$scenario$e9_progress$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e9_progress
	///
	/// en: 'A progress bar, updated in place'
	String get title => 'A progress bar, updated in place';

	/// Description of scenario e9_progress
	///
	/// en: 'Several pushes updating one notification. Watch that it updates rather than stacking, and what happens when it completes.'
	String get description => 'Several pushes updating one notification. Watch that it updates rather than stacking, and what happens when it completes.';
}

// Path: scenario.e10_color_and_icon
class Translations$scenario$e10_color_and_icon$en {
	Translations$scenario$e10_color_and_icon$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e10_color_and_icon
	///
	/// en: 'Accent colour and a monochrome icon'
	String get title => 'Accent colour and a monochrome icon';

	/// Description of scenario e10_color_and_icon
	///
	/// en: 'The classic Xiaomi white-square bug: a small icon that is not a flat monochrome alpha mask renders as a filled block. Watch the status bar.'
	String get description => 'The classic Xiaomi white-square bug: a small icon that is not a flat monochrome alpha mask renders as a filled block. Watch the status bar.';

	/// Expectation caveat for scenario e10_color_and_icon
	///
	/// en: 'The icon must be a monochrome drawable with transparency. A full-colour launcher icon is what produces the white square.'
	String get expectation => 'The icon must be a monochrome drawable with transparency. A full-colour launcher icon is what produces the white square.';
}

// Path: scenario.e11_emoji_rtl
class Translations$scenario$e11_emoji_rtl$en {
	Translations$scenario$e11_emoji_rtl$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario e11_emoji_rtl
	///
	/// en: 'Emoji, right-to-left text and unbreakable words'
	String get title => 'Emoji, right-to-left text and unbreakable words';

	/// Description of scenario e11_emoji_rtl
	///
	/// en: 'Watch the text direction of the Arabic line, whether the emoji render in colour, and where a word with no spaces is broken.'
	String get description => 'Watch the text direction of the Arabic line, whether the emoji render in colour, and where a word with no spaces is broken.';
}

// Path: scenario.f1_actions
class Translations$scenario$f1_actions$en {
	Translations$scenario$f1_actions$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario f1_actions
	///
	/// en: 'Two or three action buttons'
	String get title => 'Two or three action buttons';

	/// Description of scenario f1_actions
	///
	/// en: 'Watch whether the buttons survive a reboot of the notification shade, and what happens to the notification when one is pressed.'
	String get description => 'Watch whether the buttons survive a reboot of the notification shade, and what happens to the notification when one is pressed.';

	/// Expectation caveat for scenario f1_actions
	///
	/// en: 'Data-only on purpose: an FCM-drawn tray entry cannot carry action buttons, so the app draws this one itself in every state. Android only — iOS actions come from a category registered at startup.'
	String get expectation => 'Data-only on purpose: an FCM-drawn tray entry cannot carry action buttons, so the app draws this one itself in every state. Android only — iOS actions come from a category registered at startup.';
}

// Path: scenario.f2_inline_reply
class Translations$scenario$f2_inline_reply$en {
	Translations$scenario$f2_inline_reply$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario f2_inline_reply
	///
	/// en: 'Inline reply with RemoteInput'
	String get title => 'Inline reply with RemoteInput';

	/// Description of scenario f2_inline_reply
	///
	/// en: 'Type a reply without opening the app. Watch that the notification shows a sending state and then updates.'
	String get description => 'Type a reply without opening the app. Watch that the notification shows a sending state and then updates.';

	/// Expectation caveat for scenario f2_inline_reply
	///
	/// en: 'Data-only, so the app draws it and the button exists in every state. The reply never opens the app: it is handled in its own isolate, which updates the notification in place and hands the text to the app at the next launch or resume. There is no server — the pause between "Sending…" and "Sent" is simulated. No `opened` event is recorded, because nothing opened. Android only.'
	String get expectation => 'Data-only, so the app draws it and the button exists in every state. The reply never opens the app: it is handled in its own isolate, which updates the notification in place and hands the text to the app at the next launch or resume. There is no server — the pause between "Sending…" and "Sent" is simulated. No `opened` event is recorded, because nothing opened. Android only.';
}

// Path: scenario.f3_deeplink_foreground
class Translations$scenario$f3_deeplink_foreground$en {
	Translations$scenario$f3_deeplink_foreground$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario f3_deeplink_foreground
	///
	/// en: 'Tap while the app is running'
	String get title => 'Tap while the app is running';

	/// Description of scenario f3_deeplink_foreground
	///
	/// en: 'Routing from onMessage, with the app already on screen. Watch that the current screen is not lost.'
	String get description => 'Routing from onMessage, with the app already on screen. Watch that the current screen is not lost.';

	/// Expectation caveat for scenario f3_deeplink_foreground
	///
	/// en: 'Opens the Telemetry page.'
	String get expectation => 'Opens the Telemetry page.';
}

// Path: scenario.f4_deeplink_background
class Translations$scenario$f4_deeplink_background$en {
	Translations$scenario$f4_deeplink_background$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario f4_deeplink_background
	///
	/// en: 'Tap while the app is backgrounded'
	String get title => 'Tap while the app is backgrounded';

	/// Description of scenario f4_deeplink_background
	///
	/// en: 'Routing from onMessageOpenedApp. Watch that the app resumes on the linked screen rather than where it was left.'
	String get description => 'Routing from onMessageOpenedApp. Watch that the app resumes on the linked screen rather than where it was left.';

	/// Expectation caveat for scenario f4_deeplink_background
	///
	/// en: 'Opens the Sandbox.'
	String get expectation => 'Opens the Sandbox.';
}

// Path: scenario.f5_deeplink_killed
class Translations$scenario$f5_deeplink_killed$en {
	Translations$scenario$f5_deeplink_killed$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario f5_deeplink_killed
	///
	/// en: 'Tap with the app killed'
	String get title => 'Tap with the app killed';

	/// Description of scenario f5_deeplink_killed
	///
	/// en: 'Routing from getInitialMessage, which runs once at startup and is the commonest source of deep-link bugs — it is easy to forget, and it fails only in the one state nobody tests by hand.'
	String get description => 'Routing from getInitialMessage, which runs once at startup and is the commonest source of deep-link bugs — it is easy to forget, and it fails only in the one state nobody tests by hand.';

	/// Expectation caveat for scenario f5_deeplink_killed
	///
	/// en: 'Opens the Runs page.'
	String get expectation => 'Opens the Runs page.';
}

// Path: scenario.f6_delete_intent
class Translations$scenario$f6_delete_intent$en {
	Translations$scenario$f6_delete_intent$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario f6_delete_intent
	///
	/// en: 'Detecting a swipe-away'
	String get title => 'Detecting a swipe-away';

	/// Description of scenario f6_delete_intent
	///
	/// en: 'The delete intent fires when the user dismisses without tapping. Watch that it is distinguishable from a tap.'
	String get description => 'The delete intent fires when the user dismisses without tapping. Watch that it is distinguishable from a tap.';

	/// Expectation caveat for scenario f6_delete_intent
	///
	/// en: 'Detected only while the app is on screen, because only then did the app draw the notification through the plugin. Backgrounded, FCM draws the tray entry itself and a swipe on it reports nothing; killed, there is no isolate left to report to. The limit is Android's, not a gap.'
	String get expectation => 'Detected only while the app is on screen, because only then did the app draw the notification through the plugin. Backgrounded, FCM draws the tray entry itself and a swipe on it reports nothing; killed, there is no isolate left to report to. The limit is Android\'s, not a gap.';
}

// Path: scenario.f7_ongoing
class Translations$scenario$f7_ongoing$en {
	Translations$scenario$f7_ongoing$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario f7_ongoing
	///
	/// en: 'An ongoing, undismissable notification'
	String get title => 'An ongoing, undismissable notification';

	/// Description of scenario f7_ongoing
	///
	/// en: 'Watch that it cannot be swiped away, and confirm there is a way to clear it — an ongoing notification with no exit is a support ticket.'
	String get description => 'Watch that it cannot be swiped away, and confirm there is a way to clear it — an ongoing notification with no exit is a support ticket.';
}

// Path: scenario.f8_full_screen_intent
class Translations$scenario$f8_full_screen_intent$en {
	Translations$scenario$f8_full_screen_intent$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario f8_full_screen_intent
	///
	/// en: 'Full-screen intent, as an incoming call'
	String get title => 'Full-screen intent, as an incoming call';

	/// Description of scenario f8_full_screen_intent
	///
	/// en: 'Takes over the lock screen. Watch whether it is granted at all, and what it degrades to when it is refused.'
	String get description => 'Takes over the lock screen. Watch whether it is granted at all, and what it degrades to when it is refused.';

	/// Expectation caveat for scenario f8_full_screen_intent
	///
	/// en: 'Needs the USE_FULL_SCREEN_INTENT permission, which Android 14+ grants only to calling and alarm apps. Expect a degraded heads-up notification rather than a takeover here.'
	String get expectation => 'Needs the USE_FULL_SCREEN_INTENT permission, which Android 14+ grants only to calling and alarm apps. Expect a degraded heads-up notification rather than a takeover here.';
}

// Path: scenario.f9_trampoline
class Translations$scenario$f9_trampoline$en {
	Translations$scenario$f9_trampoline$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario f9_trampoline
	///
	/// en: 'A notification trampoline, which should fail'
	String get title => 'A notification trampoline, which should fail';

	/// Description of scenario f9_trampoline
	///
	/// en: 'Starting an activity from a service or broadcast receiver after a tap. Banned since Android 12. Watch for the failure and its log line.'
	String get description => 'Starting an activity from a service or broadcast receiver after a tap. Banned since Android 12. Watch for the failure and its log line.';

	/// Expectation caveat for scenario f9_trampoline
	///
	/// en: 'Expected to fail on Android 12 and later. The demonstration is the error, not a working route.'
	String get expectation => 'Expected to fail on Android 12 and later. The demonstration is the error, not a working route.';
}

// Path: scenario.g1_group_summary
class Translations$scenario$g1_group_summary$en {
	Translations$scenario$g1_group_summary$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario g1_group_summary
	///
	/// en: 'Five notifications with a summary'
	String get title => 'Five notifications with a summary';

	/// Description of scenario g1_group_summary
	///
	/// en: 'Watch that they collapse under one summary row, and what the summary says when the fifth arrives.'
	String get description => 'Watch that they collapse under one summary row, and what the summary says when the fifth arrives.';
}

// Path: scenario.g2_update_same_id
class Translations$scenario$g2_update_same_id$en {
	Translations$scenario$g2_update_same_id$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario g2_update_same_id
	///
	/// en: 'Replacing a notification in place'
	String get title => 'Replacing a notification in place';

	/// Description of scenario g2_update_same_id
	///
	/// en: 'Send twice with the same tag. Watch that the second replaces the first rather than stacking, and whether it re-alerts.'
	String get description => 'Send twice with the same tag. Watch that the second replaces the first rather than stacking, and whether it re-alerts.';
}

// Path: scenario.g3_badge
class Translations$scenario$g3_badge$en {
	Translations$scenario$g3_badge$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario g3_badge
	///
	/// en: 'A count on the launcher icon'
	String get title => 'A count on the launcher icon';

	/// Description of scenario g3_badge
	///
	/// en: 'The least portable thing here. Watch whether the launcher shows the number, a dot, or nothing at all.'
	String get description => 'The least portable thing here. Watch whether the launcher shows the number, a dot, or nothing at all.';

	/// Expectation caveat for scenario g3_badge
	///
	/// en: 'Behaviour differs per manufacturer: One UI, MIUI and the Pixel launcher all disagree, and several require the user to enable badges per app.'
	String get expectation => 'Behaviour differs per manufacturer: One UI, MIUI and the Pixel launcher all disagree, and several require the user to enable badges per app.';
}

// Path: scenario.g4_badge_ios
class Translations$scenario$g4_badge_ios$en {
	Translations$scenario$g4_badge_ios$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario g4_badge_ios
	///
	/// en: 'The iOS badge via aps.badge'
	String get title => 'The iOS badge via aps.badge';

	/// Description of scenario g4_badge_ios
	///
	/// en: 'One well-defined number, set by the sender. Watch that it replaces rather than increments — iOS does not add.'
	String get description => 'One well-defined number, set by the sender. Watch that it replaces rather than increments — iOS does not add.';
}

// Path: scenario.h1_dnd_bypass
class Translations$scenario$h1_dnd_bypass$en {
	Translations$scenario$h1_dnd_bypass$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario h1_dnd_bypass
	///
	/// en: 'A channel that bypasses Do Not Disturb'
	String get title => 'A channel that bypasses Do Not Disturb';

	/// Description of scenario h1_dnd_bypass
	///
	/// en: 'Watch that it sounds while DND is on. Setting the flag is not enough — the user must have granted notification-policy access.'
	String get description => 'Watch that it sounds while DND is on. Setting the flag is not enough — the user must have granted notification-policy access.';

	/// Expectation caveat for scenario h1_dnd_bypass
	///
	/// en: 'Requires Notification Policy Access, granted by the user in system settings. Without it the flag is accepted and silently ignored.'
	String get expectation => 'Requires Notification Policy Access, granted by the user in system settings. Without it the flag is accepted and silently ignored.';
}

// Path: scenario.h2_category_alarm
class Translations$scenario$h2_category_alarm$en {
	Translations$scenario$h2_category_alarm$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario h2_category_alarm
	///
	/// en: 'CATEGORY_ALARM'
	String get title => 'CATEGORY_ALARM';

	/// Description of scenario h2_category_alarm
	///
	/// en: 'Alarms are treated as a special class by DND. Watch whether the category alone changes anything without policy access.'
	String get description => 'Alarms are treated as a special class by DND. Watch whether the category alone changes anything without policy access.';

	/// Expectation caveat for scenario h2_category_alarm
	///
	/// en: 'FCM has no field for the notification category — it is set by the client when building the local notification, which is why this needs the channel work.'
	String get expectation => 'FCM has no field for the notification category — it is set by the client when building the local notification, which is why this needs the channel work.';
}

// Path: scenario.h3_ios_time_sensitive
class Translations$scenario$h3_ios_time_sensitive$en {
	Translations$scenario$h3_ios_time_sensitive$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario h3_ios_time_sensitive
	///
	/// en: 'iOS time-sensitive — breaks through Focus'
	String get title => 'iOS time-sensitive — breaks through Focus';

	/// Description of scenario h3_ios_time_sensitive
	///
	/// en: 'Watch that it arrives during a Focus mode that would hold an ordinary notification.'
	String get description => 'Watch that it arrives during a Focus mode that would hold an ordinary notification.';
}

// Path: scenario.h4_ios_critical
class Translations$scenario$h4_ios_critical$en {
	Translations$scenario$h4_ios_critical$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario h4_ios_critical
	///
	/// en: 'iOS critical — through Focus and the mute switch'
	String get title => 'iOS critical — through Focus and the mute switch';

	/// Description of scenario h4_ios_critical
	///
	/// en: 'The most intrusive delivery Apple offers. Watch that it sounds even when the device is muted.'
	String get description => 'The most intrusive delivery Apple offers. Watch that it sounds even when the device is muted.';

	/// Expectation caveat for scenario h4_ios_critical
	///
	/// en: 'Requires a critical-alert entitlement that Apple must approve for the app. Without it APNs rejects the push, so this stays untestable here — listed for completeness rather than scheduled.'
	String get expectation => 'Requires a critical-alert entitlement that Apple must approve for the app. Without it APNs rejects the push, so this stays untestable here — listed for completeness rather than scheduled.';
}

// Path: scenario.h5_ios_passive
class Translations$scenario$h5_ios_passive$en {
	Translations$scenario$h5_ios_passive$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario h5_ios_passive
	///
	/// en: 'iOS passive — no sound, no wake'
	String get title => 'iOS passive — no sound, no wake';

	/// Description of scenario h5_ios_passive
	///
	/// en: 'The quietest level: it appears in the list without alerting. Watch that the screen does not light up.'
	String get description => 'The quietest level: it appears in the list without alerting. Watch that the screen does not light up.';
}

// Path: scenario.i1_silent_no_sound
class Translations$scenario$i1_silent_no_sound$en {
	Translations$scenario$i1_silent_no_sound$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario i1_silent_no_sound
	///
	/// en: 'Visible but silent'
	String get title => 'Visible but silent';

	/// Description of scenario i1_silent_no_sound
	///
	/// en: 'Appears in the tray with no sound and no vibration. Watch that it is silent but still lights the screen or not.'
	String get description => 'Appears in the tray with no sound and no vibration. Watch that it is silent but still lights the screen or not.';
}

// Path: scenario.i2_silent_data_sync
class Translations$scenario$i2_silent_data_sync$en {
	Translations$scenario$i2_silent_data_sync$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario i2_silent_data_sync
	///
	/// en: 'Silent sync, drawn blank'
	String get title => 'Silent sync, drawn blank';

	/// Description of scenario i2_silent_data_sync
	///
	/// en: 'The handler writes a row; that is the effect this scenario is about. A tray entry still appears — icon and app name, no title or body — since nothing suppresses a titleless banner. Watch the Inbox page for the row; the tray entry has no text to read.'
	String get description => 'The handler writes a row; that is the effect this scenario is about. A tray entry still appears — icon and app name, no title or body — since nothing suppresses a titleless banner. Watch the Inbox page for the row; the tray entry has no text to read.';
}

// Path: scenario.i3_ios_content_available
class Translations$scenario$i3_ios_content_available$en {
	Translations$scenario$i3_ios_content_available$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario i3_ios_content_available
	///
	/// en: 'iOS background refresh via content-available'
	String get title => 'iOS background refresh via content-available';

	/// Description of scenario i3_ios_content_available
	///
	/// en: 'Wakes the app to fetch without showing anything. Watch how often iOS actually honours it — it throttles this aggressively.'
	String get description => 'Wakes the app to fetch without showing anything. Watch how often iOS actually honours it — it throttles this aggressively.';

	/// Expectation caveat for scenario i3_ios_content_available
	///
	/// en: 'iOS may delay or drop these entirely depending on battery and usage. A missed one is not necessarily a bug.'
	String get expectation => 'iOS may delay or drop these entirely depending on battery and usage. A missed one is not necessarily a bug.';
}

// Path: scenario.i4_burst
class Translations$scenario$i4_burst$en {
	Translations$scenario$i4_burst$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario i4_burst
	///
	/// en: 'Twenty messages in ten seconds'
	String get title => 'Twenty messages in ten seconds';

	/// Description of scenario i4_burst
	///
	/// en: 'Watch for rate limiting, coalescing, and manufacturer caps. MIUI will usually start dropping before FCM does.'
	String get description => 'Watch for rate limiting, coalescing, and manufacturer caps. MIUI will usually start dropping before FCM does.';

	/// Manual steps for scenario i4_burst
	///
	/// en: 'Send this 20 times within 10 seconds and count what arrives. Vary the body so collapsing is visible.'
	String get manual_steps => 'Send this 20 times within 10 seconds and count what arrives. Vary the body so collapsing is visible.';
}

// Path: scenario.j1_topic
class Translations$scenario$j1_topic$en {
	Translations$scenario$j1_topic$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario j1_topic
	///
	/// en: 'Send to a topic'
	String get title => 'Send to a topic';

	/// Description of scenario j1_topic
	///
	/// en: 'Subscribe the device, then send to the topic rather than the token. Watch that it arrives without the sender knowing any token at all.'
	String get description => 'Subscribe the device, then send to the topic rather than the token. Watch that it arrives without the sender knowing any token at all.';

	/// Expectation caveat for scenario j1_topic
	///
	/// en: 'Sending works now and FCM answers 200, but nothing is delivered until the app can subscribe to a topic.'
	String get expectation => 'Sending works now and FCM answers 200, but nothing is delivered until the app can subscribe to a topic.';
}

// Path: scenario.j2_condition
class Translations$scenario$j2_condition$en {
	Translations$scenario$j2_condition$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario j2_condition
	///
	/// en: 'Send to a boolean topic condition'
	String get title => 'Send to a boolean topic condition';

	/// Description of scenario j2_condition
	///
	/// en: 'A device must be in both topics to receive this. Watch that subscribing to only one excludes it.'
	String get description => 'A device must be in both topics to receive this. Watch that subscribing to only one excludes it.';

	/// Expectation caveat for scenario j2_condition
	///
	/// en: 'Like j1, sending works now and FCM answers 200 — but nothing is delivered until the app can subscribe to both topics.'
	String get expectation => 'Like j1, sending works now and FCM answers 200 — but nothing is delivered until the app can subscribe to both topics.';
}

// Path: scenario.j3_multicast
class Translations$scenario$j3_multicast$en {
	Translations$scenario$j3_multicast$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario j3_multicast
	///
	/// en: 'Send to every registered device'
	String get title => 'Send to every registered device';

	/// Description of scenario j3_multicast
	///
	/// en: 'The main tool for comparing behaviour across handsets: one send, every device, and the differences are the result.'
	String get description => 'The main tool for comparing behaviour across handsets: one send, every device, and the differences are the result.';

	/// Expectation caveat for scenario j3_multicast
	///
	/// en: 'FCM has no "all devices" audience, so this needs a token registry the API does not have. Sending it now returns 501 with that reason rather than quietly delivering to one device.'
	String get expectation => 'FCM has no "all devices" audience, so this needs a token registry the API does not have. Sending it now returns 501 with that reason rather than quietly delivering to one device.';
}

// Path: scenario.k1_payload_oversize
class Translations$scenario$k1_payload_oversize$en {
	Translations$scenario$k1_payload_oversize$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario k1_payload_oversize
	///
	/// en: 'A payload over FCM's 4 KB limit'
	String get title => 'A payload over FCM\'s 4 KB limit';

	/// Description of scenario k1_payload_oversize
	///
	/// en: 'Watch that the API surfaces FCM's error with a usable message rather than a bare 400.'
	String get description => 'Watch that the API surfaces FCM\'s error with a usable message rather than a bare 400.';

	/// Expectation caveat for scenario k1_payload_oversize
	///
	/// en: 'FCM rejects this with INVALID_ARGUMENT. The send should fail before anything reaches the device.'
	String get expectation => 'FCM rejects this with INVALID_ARGUMENT. The send should fail before anything reaches the device.';
}

// Path: scenario.k2_invalid_token
class Translations$scenario$k2_invalid_token$en {
	Translations$scenario$k2_invalid_token$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario k2_invalid_token
	///
	/// en: 'A token that is no longer registered'
	String get title => 'A token that is no longer registered';

	/// Description of scenario k2_invalid_token
	///
	/// en: 'The everyday production failure. Watch that the API reports it as UNREGISTERED rather than a generic 404, which is what tells a real backend to delete the row.'
	String get description => 'The everyday production failure. Watch that the API reports it as UNREGISTERED rather than a generic 404, which is what tells a real backend to delete the row.';

	/// Expectation caveat for scenario k2_invalid_token
	///
	/// en: 'FCM answers with UNREGISTERED, which this API maps to 404 with its own wording. The errorCode in error.details takes precedence over the top-level NOT_FOUND status.'
	String get expectation => 'FCM answers with UNREGISTERED, which this API maps to 404 with its own wording. The errorCode in error.details takes precedence over the top-level NOT_FOUND status.';
}

// Path: scenario.k3_permission_denied
class Translations$scenario$k3_permission_denied$en {
	Translations$scenario$k3_permission_denied$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario k3_permission_denied
	///
	/// en: 'POST_NOTIFICATIONS denied on Android 13+'
	String get title => 'POST_NOTIFICATIONS denied on Android 13+';

	/// Description of scenario k3_permission_denied
	///
	/// en: 'Watch that the data handler still runs and the inbox still fills, even though nothing can be drawn.'
	String get description => 'Watch that the data handler still runs and the inbox still fills, even though nothing can be drawn.';

	/// Manual steps for scenario k3_permission_denied
	///
	/// en: 'adb shell pm revoke cz.netglade.fcm_app android.permission.POST_NOTIFICATIONS — then send, and check the Inbox page rather than the tray.'
	String get manual_steps => 'adb shell pm revoke cz.netglade.fcm_app android.permission.POST_NOTIFICATIONS — then send, and check the Inbox page rather than the tray.';
}

// Path: scenario.k4_notifications_disabled
class Translations$scenario$k4_notifications_disabled$en {
	Translations$scenario$k4_notifications_disabled$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario k4_notifications_disabled
	///
	/// en: 'Notifications switched off in system settings'
	String get title => 'Notifications switched off in system settings';

	/// Description of scenario k4_notifications_disabled
	///
	/// en: 'Distinct from a denied permission: the app has the grant and the user has turned it off. Watch that data delivery is unaffected.'
	String get description => 'Distinct from a denied permission: the app has the grant and the user has turned it off. Watch that data delivery is unaffected.';

	/// Manual steps for scenario k4_notifications_disabled
	///
	/// en: 'Settings › Apps › FCM Sample › Notifications › off. Send, then confirm the row appears in the Inbox page.'
	String get manual_steps => 'Settings › Apps › FCM Sample › Notifications › off. Send, then confirm the row appears in the Inbox page.';
}

// Path: scenario.k5_battery_restricted
class Translations$scenario$k5_battery_restricted$en {
	Translations$scenario$k5_battery_restricted$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Title of scenario k5_battery_restricted
	///
	/// en: 'App in Restricted battery mode'
	String get title => 'App in Restricted battery mode';

	/// Description of scenario k5_battery_restricted
	///
	/// en: 'The state a user reaches by tapping "restrict" in battery settings. Watch whether a HIGH priority push still wakes the app.'
	String get description => 'The state a user reaches by tapping "restrict" in battery settings. Watch whether a HIGH priority push still wakes the app.';

	/// Manual steps for scenario k5_battery_restricted
	///
	/// en: 'Settings › Apps › FCM Sample › Battery › Restricted. Send and compare the delay against c1_priority_high in the unrestricted state.'
	String get manual_steps => 'Settings › Apps › FCM Sample › Battery › Restricted. Send and compare the delay against c1_priority_high in the unrestricted state.';
}

// Path: channels.fcm_sample_high
class Translations$channels$fcm_sample_high$en {
	Translations$channels$fcm_sample_high$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name shown in system settings
	///
	/// en: 'Sample pushes'
	String get name => 'Sample pushes';

	/// Android channel description shown in system settings
	///
	/// en: 'Pushes received by the FCM sample app.'
	String get description => 'Pushes received by the FCM sample app.';
}

// Path: channels.importance_high
class Translations$channels$importance_high$en {
	Translations$channels$importance_high$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; d1
	///
	/// en: 'Importance: high'
	String get name => 'Importance: high';

	/// Android channel description; d1
	///
	/// en: 'Pops as a banner and makes a sound.'
	String get description => 'Pops as a banner and makes a sound.';
}

// Path: channels.importance_default
class Translations$channels$importance_default$en {
	Translations$channels$importance_default$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; d2
	///
	/// en: 'Importance: default'
	String get name => 'Importance: default';

	/// Android channel description; d2
	///
	/// en: 'Makes a sound but does not pop.'
	String get description => 'Makes a sound but does not pop.';
}

// Path: channels.importance_low
class Translations$channels$importance_low$en {
	Translations$channels$importance_low$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; d3 and i1
	///
	/// en: 'Importance: low'
	String get name => 'Importance: low';

	/// Android channel description; d3 and i1
	///
	/// en: 'Silent. Appears in the shade only.'
	String get description => 'Silent. Appears in the shade only.';
}

// Path: channels.importance_min
class Translations$channels$importance_min$en {
	Translations$channels$importance_min$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; d4
	///
	/// en: 'Importance: min'
	String get name => 'Importance: min';

	/// Android channel description; d4
	///
	/// en: 'Collapsed in the shade with no icon.'
	String get description => 'Collapsed in the shade with no icon.';
}

// Path: channels.custom_sound
class Translations$channels$custom_sound$en {
	Translations$channels$custom_sound$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; d5
	///
	/// en: 'Custom sound'
	String get name => 'Custom sound';

	/// Android channel description; d5
	///
	/// en: 'Plays a bundled chime instead of the default.'
	String get description => 'Plays a bundled chime instead of the default.';
}

// Path: channels.vibration_pattern
class Translations$channels$vibration_pattern$en {
	Translations$channels$vibration_pattern$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; d6
	///
	/// en: 'Vibration pattern'
	String get name => 'Vibration pattern';

	/// Android channel description; d6
	///
	/// en: 'Short, pause, short — set when the channel was created.'
	String get description => 'Short, pause, short — set when the channel was created.';
}

// Path: channels.chat_v1
class Translations$channels$chat_v1$en {
	Translations$channels$chat_v1$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; d7. A version tag, so the same in both
	///
	/// en: 'Chat (v1)'
	String get name => 'Chat (v1)';

	/// Android channel description; d7
	///
	/// en: 'The first attempt. Its importance can no longer be changed.'
	String get description => 'The first attempt. Its importance can no longer be changed.';
}

// Path: channels.chat_v2
class Translations$channels$chat_v2$en {
	Translations$channels$chat_v2$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; d8. A version tag, so the same in both
	///
	/// en: 'Chat (v2)'
	String get name => 'Chat (v2)';

	/// Android channel description; d8
	///
	/// en: 'The replacement — a new id is the only way to change importance.'
	String get description => 'The replacement — a new id is the only way to change importance.';
}

// Path: channels.dnd_bypass
class Translations$channels$dnd_bypass$en {
	Translations$channels$dnd_bypass$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; h1
	///
	/// en: 'Do Not Disturb bypass'
	String get name => 'Do Not Disturb bypass';

	/// Android channel description; h1
	///
	/// en: 'Requested. Granted only with notification-policy access.'
	String get description => 'Requested. Granted only with notification-policy access.';
}

// Path: channels.alarms
class Translations$channels$alarms$en {
	Translations$channels$alarms$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel name; h2
	///
	/// en: 'Alarms'
	String get name => 'Alarms';

	/// Android channel description; h2
	///
	/// en: 'Uses the alarm audio stream rather than the notification one.'
	String get description => 'Uses the alarm audio stream rather than the notification one.';
}

// Path: channels.group
class Translations$channels$group$en {
	Translations$channels$group$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations
	late final Translations$channels$group$chat$en chat = Translations$channels$group$chat$en._(_root);
}

// Path: channels.group.chat
class Translations$channels$group$chat$en {
	Translations$channels$group$chat$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Android channel group heading; d8. A product word, so the same in both
	///
	/// en: 'Chat'
	String get name => 'Chat';
}

/// The flat map containing all translations for locale <en>.
/// Only for edge cases! For simple maps, use the map function of this library.
///
/// The Dart AOT compiler has issues with very large switch statements,
/// so the map is split into smaller functions (512 entries each).
extension on Translations {
	dynamic _flatMapFunction(String path) {
		return switch (path) {
			'app.title' => 'FCM Sample',
			'language.tooltip' => 'Language',
			'language.system' => 'System',
			'language.english' => 'English',
			'language.czech' => 'Čeština',
			'shell.title.inbox' => 'Push inbox',
			'shell.title.scenarios' => 'Scenarios',
			'shell.title.sandbox' => 'Sandbox',
			'shell.title.runs' => 'Runs',
			'shell.title.telemetry' => 'Telemetry',
			'drawer.inbox' => 'Inbox',
			'drawer.scenarios' => 'Scenarios',
			'drawer.sandbox' => 'Sandbox',
			'drawer.runs' => 'Runs',
			'drawer.telemetry' => 'Telemetry',
			'drawer.channels' => 'Channels',
			'inbox.registration_token' => 'Registration token',
			'inbox.empty' => 'No pushes received yet.',
			'inbox.malformed_dropped' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} malformed payload dropped', few: '${n} malformed payloads dropped', other: '${n} malformed payloads dropped', ), 
			'message_detail.opened_by_action' => ({required Object label}) => 'Opened by action: ${label}',
			'message_detail.from' => ({required Object from}) => 'from: ${from}',
			'message_detail.replied' => ({required Object text}) => 'Replied: ${text}',
			'message_detail.sent' => 'Sent',
			'message_detail.payload_id' => 'Payload id',
			'message_detail.extra_data' => 'Extra data',
			'message_detail.no_extra_data' => 'No extra data keys.',
			'reply.sending' => 'Sending…',
			'reply.sent' => 'Sent',
			'reply.not_sent' => 'Not sent',
			'message_tile.no_title' => '(no title)',
			'message_tile.body_with_data' => ({required Object body, required Object keys}) => '${body}\ndata: ${keys}',
			'scenarios.no_token' => 'No registration token yet, so there is nowhere to send. Open the Inbox once the app has registered.',
			'scenario_card.needs_work' => 'needs work',
			'common.needs_killed_app' => 'Needs the app killed',
			'common.cancel' => 'Cancel',
			'common.schedule_ellipsis' => 'Schedule…',
			'common.reload' => 'Reload',
			'common.no_scenario' => 'no scenario',
			'common.no_device_yet' => 'no device yet',
			'selection_bar.select_for_batch' => 'Select for a batch',
			'selection_bar.selected_count' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} selected', few: '${n} selected', other: '${n} selected', ), 
			'runs.empty' => 'Nothing scheduled yet. Pick a scenario and choose Schedule.',
			'run_timeline.title' => 'Run',
			'run_tile.sends' => ({required num n}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '${n} send', other: '${n} sends', ), 
			'run_tile.next_due' => ({required Object time}) => 'next due ${time}',
			'run_item.composed_by_hand' => '(composed by hand)',
			'run_item.due' => ({required Object time}) => 'due ${time}',
			'run_item.nothing_recorded' => 'Nothing recorded yet.',
			'sandbox.validate_only' => 'Validate only',
			'sandbox.needs_banner' => ({required Object needs}) => 'Needs ${needs}. The push will still be sent, but this scenario cannot be observed yet.',
			'send.to_this_device' => 'Send to this device',
			'send.to_that_token' => 'Send to that token',
			'send.to_topic' => ({required Object topic}) => 'Send to topic "${topic}"',
			'send.to_condition' => 'Send to the condition',
			'send.to_every_device' => 'Send to every device',
			'send_target.label' => 'Send to',
			'send_target.this_device' => 'This device',
			'send_target.token' => 'Token',
			'send_target.topic' => 'Topic',
			'send_target.condition' => 'Condition',
			'send_target.all_devices' => 'All devices',
			'send_target.all_devices_warning' => 'Sending to every device needs a token registry the API does not have yet, so this will be refused.',
			'schedule_sheet.delay' => 'Delay',
			'schedule_sheet.spacing' => 'Spacing',
			'schedule_sheet.spacing_help' => 'Added again for each message after the first, so a batch arrives spread out rather than as one burst.',
			'schedule_sheet.confirm' => 'Schedule',
			'preset_chip.seconds' => ({required Object value}) => '${value} s',
			'not_received.button' => 'It never arrived',
			'not_received.reported' => 'Reported as never arrived',
			'send_result.validated' => ({required Object messageId, required Object traceId}) => '✓ Validated · message ${messageId} · trace ${traceId} · the payload was validated, not sent',
			'send_result.sent' => ({required Object messageId, required Object traceId}) => '✓ Sent · message ${messageId} · trace ${traceId} · it should appear in the Inbox shortly',
			'send_result.scheduled' => ({required num n, required Object runId}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '✓ Scheduled · run ${runId} · ${n} message · nothing has been sent yet', few: '✓ Scheduled · run ${runId} · ${n} messages · nothing has been sent yet', other: '✓ Scheduled · run ${runId} · ${n} messages · nothing has been sent yet', ), 
			'countdown.seconds' => 'seconds',
			'countdown.swipe_away' => 'Swipe the app away from recents now. The push is already scheduled on the server, so it will arrive whether this app is running or not.',
			'countdown.dim_note' => 'An ordinary app cannot switch the display off — only dim it and let go of the wakelock, so the system times out on its own.',
			'countdown.dim_screen' => 'Dim the screen',
			'countdown.battery_settings' => 'Battery settings',
			'telemetry.tab.events' => 'Events',
			'telemetry.tab.latency' => 'Latency',
			'telemetry.events.empty' => 'Nothing recorded yet. Send a push from the Sandbox, then reload.',
			'telemetry.event_row.request_received' => ' · (request received)',
			'telemetry.latency.empty' => 'No measurements yet. A row needs both a send and an arrival for the same trace.',
			'telemetry.latency.scenario_column' => 'scenario',
			'telemetry.latency.footnote' => '`sent` is when the API received the request, not when FCM answered, so every figure above includes the time the FCM call took.',
			'api.unreachable' => ({required Object baseUrl, required Object error}) => 'Could not reach ${baseUrl} — is the API running?\nOn a physical device, run: adb reverse tcp:8080 tcp:8080\n(${error})',
			'api.answered_status' => ({required Object status, required Object body}) => 'The API answered ${status}: ${body}',
			'api.answered_unreadable' => ({required Object error}) => 'The API answered 200 with something unreadable: ${error}',
			'api.answered_not_json' => ({required Object error}) => 'The API answered 200 with something that is not JSON: ${error}',
			'api.answered_wrong_shape' => ({required Object type}) => 'The API answered 200 with ${type} where a list was expected.',
			'api.answered_wrong_shape_runs' => ({required Object type}) => 'The API answered 200 with ${type} where a list of runs was expected.',
			'api.answered_unreadable_item' => ({required Object what, required Object error}) => 'The API answered 200 with ${what} this build cannot read: ${error}',
			'api.item.event' => 'an event',
			'api.item.latency_row' => 'a latency row',
			'api.expected_object' => ({required Object type}) => 'Expected a JSON object, got ${type}.',
			'scenario.a1_notification_only.title' => 'Notification-only payload',
			'scenario.a1_notification_only.description' => 'Watch which layer drew it — the system while backgrounded, the app while foregrounded — and how the icon and accent colour come out.',
			'scenario.a2_data_only.title' => 'Data-only payload, drawn locally',
			'scenario.a2_data_only.description' => 'Nothing draws this but the app. Watch whether it arrives at all with the app killed, which is the case data-only delivery exists for.',
			'scenario.a2_data_only.expectation' => 'On iOS a data-only push needs content-available and is throttled; see i3_ios_content_available.',
			'scenario.a3_hybrid.title' => 'notification and data together',
			'scenario.a3_hybrid.description' => 'The common shape in production. Watch whether the data map reaches the handler after a tap, which is where deep links get their arguments.',
			'scenario.a4_no_display.title' => 'Data logged silently, drawn blank',
			'scenario.a4_no_display.description' => 'A silent synchronisation: the handler runs and writes a log line. Nothing suppresses a titleless banner, so a tray entry still appears — icon and app name, no text. The observable difference from a1 is the missing text, not a missing notification. Watch the inbox for the log line; the tray has nothing to read.',
			'scenario.b1_foreground.title' => 'Delivered with the app in the foreground',
			'scenario.b1_foreground.description' => 'onMessage fires and nothing is drawn by the system, so the app must draw it. Watch that a banner appears at all.',
			'scenario.b2_background.title' => 'App backgrounded, screen locked',
			'scenario.b2_background.description' => 'The system draws this one. Watch whether it reaches the lock screen and how much of it is shown there.',
			'scenario.b2_background.manual_steps' => 'Background the app with the home button, then lock the screen. Send from another machine, or use validate-only first to check the payload.',
			'scenario.b3_killed.title' => 'App swiped out of recents',
			'scenario.b3_killed.description' => 'The hardest case, and the reason delayed sending exists: the send has to happen after the app is gone. Watch whether the data handler runs.',
			'scenario.b4_after_reboot.title' => 'After a reboot, app never opened',
			'scenario.b4_after_reboot.description' => 'Until the app is opened once after boot, some manufacturers hold its background work entirely. Watch whether anything arrives.',
			'scenario.b4_after_reboot.manual_steps' => 'adb reboot — then do NOT open the app. Wait for the lock screen and send.',
			'scenario.b5_force_stopped.title' => 'After Force stop',
			'scenario.b5_force_stopped.description' => 'Force stop revokes the app\'s ability to be woken. This scenario exists to prove we know that, rather than to be debugged.',
			'scenario.b5_force_stopped.expectation' => 'Expected to arrive: nothing. A force-stopped app receives no pushes at all until it is launched by hand. If something does arrive, that is the surprise worth investigating.',
			'scenario.b5_force_stopped.manual_steps' => 'Settings › Apps › FCM Sample › Force stop. Then send, and expect nothing.',
			'scenario.b6_token_refresh.title' => 'Token rotated by a reinstall or clear-data',
			'scenario.b6_token_refresh.description' => 'The old token is dead and sending to it must fail loudly. Watch the Inbox page for the new token, and compare it with the old one.',
			'scenario.b6_token_refresh.manual_steps' => 'adb shell pm clear cz.netglade.fcm_app — reopen the app and read the new token off the Inbox page. Sending to the old one should give UNREGISTERED, which is k2_invalid_token.',
			'scenario.c1_priority_high.title' => 'android.priority HIGH',
			'scenario.c1_priority_high.description' => 'Wakes a dozing device. Watch how quickly it lands with the screen off compared with c2.',
			'scenario.c2_priority_normal.title' => 'android.priority NORMAL',
			'scenario.c2_priority_normal.description' => 'May wait for the next maintenance window. Watch for a delay with the screen off — this is the usual cause of a "missing" push.',
			'scenario.c3_ttl_zero.title' => 'android.ttl 0s — now or never',
			'scenario.c3_ttl_zero.description' => 'FCM makes one attempt and discards the message if the device is not reachable. Watch that an offline device never receives it.',
			'scenario.c4_ttl_long.title' => 'android.ttl 86400s — a day of retries',
			'scenario.c4_ttl_long.description' => 'Held for 24 hours. Watch it arrive when the network comes back, long after it was sent.',
			'scenario.c5_collapse_key.title' => 'Five sends sharing a collapse_key, offline',
			'scenario.c5_collapse_key.description' => 'Only the last should survive. Watch that one notification appears, not five, once the network returns.',
			'scenario.c5_collapse_key.manual_steps' => 'Put the device in airplane mode. Send five times, changing the body each time. Restore the network: exactly one notification should appear, carrying the last body.',
			'scenario.c6_doze_test.title' => 'Delivery while the device is in Doze',
			'scenario.c6_doze_test.description' => 'Real Doze behaviour, not a simulation. Watch which priorities break through and which are held.',
			'scenario.c6_doze_test.manual_steps' => 'adb shell dumpsys deviceidle force-idle — send, then adb shell dumpsys deviceidle unforce to restore.',
			'scenario.c7_standby_bucket.title' => 'App in the restricted standby bucket',
			'scenario.c7_standby_bucket.description' => 'The harshest state Android imposes on an unused app. Watch whether a HIGH priority push still arrives.',
			'scenario.c7_standby_bucket.manual_steps' => 'adb shell am set-standby-bucket cz.netglade.fcm_app restricted — check with adb shell am get-standby-bucket cz.netglade.fcm_app.',
			'scenario.d1_importance_high.title' => 'IMPORTANCE_HIGH — heads-up banner',
			'scenario.d1_importance_high.description' => 'Watch for a banner that floats over the current app, with sound.',
			'scenario.d2_importance_default.title' => 'IMPORTANCE_DEFAULT — sound, no banner',
			'scenario.d2_importance_default.description' => 'Watch for a sound and a tray entry, but nothing floating.',
			'scenario.d3_importance_low.title' => 'IMPORTANCE_LOW — silent',
			'scenario.d3_importance_low.description' => 'Visible but with no sound and no vibration. Watch that it is genuinely silent rather than quiet.',
			'scenario.d4_importance_min.title' => 'IMPORTANCE_MIN — status bar only',
			'scenario.d4_importance_min.description' => 'No icon in the status bar on some versions; only in the shade. Watch where it appears at all.',
			'scenario.d5_custom_sound.title' => 'A custom sound on the channel',
			'scenario.d5_custom_sound.description' => 'The sound is a channel property, so changing it needs a new channel. Watch that the custom sound plays rather than the default.',
			'scenario.d5_custom_sound.expectation' => 'The named resource must exist in android/app/src/main/res/raw. A missing file falls back to the default sound silently.',
			'scenario.d6_vibration_pattern.title' => 'A custom vibration pattern',
			'scenario.d6_vibration_pattern.description' => 'Alternating vibrate and pause durations. Watch that the pattern is the one asked for rather than the channel default.',
			'scenario.d7_channel_immutability.title' => 'Changing an existing channel — Android will ignore it',
			'scenario.d7_channel_immutability.description' => 'Re-create chat_v1 with a different importance and watch Android ignore the change completely. This is the demonstration of why channels carry a version in their id.',
			'scenario.d7_channel_immutability.expectation' => 'The importance shown on the channel screen stays at its original value. The only fix is a new channel — chat_v2 — which is what d8 uses.',
			'scenario.d8_channel_group.title' => 'Channels collected into a group',
			'scenario.d8_channel_group.description' => 'Watch the system notification settings: the channels should appear nested under a named group rather than as a flat list.',
			'scenario.e1_long_text.title' => 'BigTextStyle with ~800 characters',
			'scenario.e1_long_text.description' => 'Watch where the text is cut in the collapsed view, and whether expanding shows all of it. Diacritics are included because byte-length and character-length limits behave differently.',
			'scenario.e2_image_remote.title' => 'notification.image — fetched by the platform',
			'scenario.e2_image_remote.description' => 'FCM passes a URL and the platform downloads it. Watch that it appears expanded, and how long it takes on a slow connection.',
			'scenario.e2_image_remote.expectation' => 'Android does this natively. iOS requires a Notification Service Extension, which this app does not ship, so nothing will render there.',
			'scenario.e3_image_local.title' => 'Image downloaded by the data handler',
			'scenario.e3_image_local.description' => 'The app fetches the URL itself and builds a BigPictureStyle. Compare the result and the timing against e2.',
			'scenario.e4_image_huge.title' => 'A 4000×3000 image',
			'scenario.e4_image_huge.description' => 'Watch for a resize, an out-of-memory kill, or a silent failure where the text arrives and the picture does not.',
			'scenario.e5_image_404.title' => 'An image URL that does not resolve',
			'scenario.e5_image_404.description' => 'The important question is whether the text still arrives. A push that vanishes because its picture 404s is a bad failure mode.',
			'scenario.e6_large_icon.title' => 'A large icon beside the text',
			'scenario.e6_large_icon.description' => 'The round avatar slot, distinct from the small status-bar icon. Watch that it is circular and not stretched.',
			'scenario.e7_inbox_style.title' => 'InboxStyle with seven lines',
			'scenario.e7_inbox_style.description' => 'Watch how many lines are actually shown when expanded — Android caps it, and the cap is lower than most people expect.',
			'scenario.e8_messaging_style.title' => 'MessagingStyle with several senders',
			'scenario.e8_messaging_style.description' => 'The chat layout, with a name and avatar per message. Watch the grouping and the ordering.',
			'scenario.e9_progress.title' => 'A progress bar, updated in place',
			'scenario.e9_progress.description' => 'Several pushes updating one notification. Watch that it updates rather than stacking, and what happens when it completes.',
			'scenario.e10_color_and_icon.title' => 'Accent colour and a monochrome icon',
			'scenario.e10_color_and_icon.description' => 'The classic Xiaomi white-square bug: a small icon that is not a flat monochrome alpha mask renders as a filled block. Watch the status bar.',
			'scenario.e10_color_and_icon.expectation' => 'The icon must be a monochrome drawable with transparency. A full-colour launcher icon is what produces the white square.',
			'scenario.e11_emoji_rtl.title' => 'Emoji, right-to-left text and unbreakable words',
			'scenario.e11_emoji_rtl.description' => 'Watch the text direction of the Arabic line, whether the emoji render in colour, and where a word with no spaces is broken.',
			'scenario.f1_actions.title' => 'Two or three action buttons',
			'scenario.f1_actions.description' => 'Watch whether the buttons survive a reboot of the notification shade, and what happens to the notification when one is pressed.',
			'scenario.f1_actions.expectation' => 'Data-only on purpose: an FCM-drawn tray entry cannot carry action buttons, so the app draws this one itself in every state. Android only — iOS actions come from a category registered at startup.',
			'scenario.f2_inline_reply.title' => 'Inline reply with RemoteInput',
			'scenario.f2_inline_reply.description' => 'Type a reply without opening the app. Watch that the notification shows a sending state and then updates.',
			'scenario.f2_inline_reply.expectation' => 'Data-only, so the app draws it and the button exists in every state. The reply never opens the app: it is handled in its own isolate, which updates the notification in place and hands the text to the app at the next launch or resume. There is no server — the pause between "Sending…" and "Sent" is simulated. No `opened` event is recorded, because nothing opened. Android only.',
			'scenario.f3_deeplink_foreground.title' => 'Tap while the app is running',
			'scenario.f3_deeplink_foreground.description' => 'Routing from onMessage, with the app already on screen. Watch that the current screen is not lost.',
			'scenario.f3_deeplink_foreground.expectation' => 'Opens the Telemetry page.',
			'scenario.f4_deeplink_background.title' => 'Tap while the app is backgrounded',
			'scenario.f4_deeplink_background.description' => 'Routing from onMessageOpenedApp. Watch that the app resumes on the linked screen rather than where it was left.',
			'scenario.f4_deeplink_background.expectation' => 'Opens the Sandbox.',
			'scenario.f5_deeplink_killed.title' => 'Tap with the app killed',
			'scenario.f5_deeplink_killed.description' => 'Routing from getInitialMessage, which runs once at startup and is the commonest source of deep-link bugs — it is easy to forget, and it fails only in the one state nobody tests by hand.',
			'scenario.f5_deeplink_killed.expectation' => 'Opens the Runs page.',
			'scenario.f6_delete_intent.title' => 'Detecting a swipe-away',
			'scenario.f6_delete_intent.description' => 'The delete intent fires when the user dismisses without tapping. Watch that it is distinguishable from a tap.',
			'scenario.f6_delete_intent.expectation' => 'Detected only while the app is on screen, because only then did the app draw the notification through the plugin. Backgrounded, FCM draws the tray entry itself and a swipe on it reports nothing; killed, there is no isolate left to report to. The limit is Android\'s, not a gap.',
			'scenario.f7_ongoing.title' => 'An ongoing, undismissable notification',
			'scenario.f7_ongoing.description' => 'Watch that it cannot be swiped away, and confirm there is a way to clear it — an ongoing notification with no exit is a support ticket.',
			'scenario.f8_full_screen_intent.title' => 'Full-screen intent, as an incoming call',
			'scenario.f8_full_screen_intent.description' => 'Takes over the lock screen. Watch whether it is granted at all, and what it degrades to when it is refused.',
			'scenario.f8_full_screen_intent.expectation' => 'Needs the USE_FULL_SCREEN_INTENT permission, which Android 14+ grants only to calling and alarm apps. Expect a degraded heads-up notification rather than a takeover here.',
			'scenario.f9_trampoline.title' => 'A notification trampoline, which should fail',
			'scenario.f9_trampoline.description' => 'Starting an activity from a service or broadcast receiver after a tap. Banned since Android 12. Watch for the failure and its log line.',
			'scenario.f9_trampoline.expectation' => 'Expected to fail on Android 12 and later. The demonstration is the error, not a working route.',
			'scenario.g1_group_summary.title' => 'Five notifications with a summary',
			'scenario.g1_group_summary.description' => 'Watch that they collapse under one summary row, and what the summary says when the fifth arrives.',
			'scenario.g2_update_same_id.title' => 'Replacing a notification in place',
			'scenario.g2_update_same_id.description' => 'Send twice with the same tag. Watch that the second replaces the first rather than stacking, and whether it re-alerts.',
			'scenario.g3_badge.title' => 'A count on the launcher icon',
			'scenario.g3_badge.description' => 'The least portable thing here. Watch whether the launcher shows the number, a dot, or nothing at all.',
			'scenario.g3_badge.expectation' => 'Behaviour differs per manufacturer: One UI, MIUI and the Pixel launcher all disagree, and several require the user to enable badges per app.',
			'scenario.g4_badge_ios.title' => 'The iOS badge via aps.badge',
			'scenario.g4_badge_ios.description' => 'One well-defined number, set by the sender. Watch that it replaces rather than increments — iOS does not add.',
			'scenario.h1_dnd_bypass.title' => 'A channel that bypasses Do Not Disturb',
			'scenario.h1_dnd_bypass.description' => 'Watch that it sounds while DND is on. Setting the flag is not enough — the user must have granted notification-policy access.',
			'scenario.h1_dnd_bypass.expectation' => 'Requires Notification Policy Access, granted by the user in system settings. Without it the flag is accepted and silently ignored.',
			'scenario.h2_category_alarm.title' => 'CATEGORY_ALARM',
			'scenario.h2_category_alarm.description' => 'Alarms are treated as a special class by DND. Watch whether the category alone changes anything without policy access.',
			'scenario.h2_category_alarm.expectation' => 'FCM has no field for the notification category — it is set by the client when building the local notification, which is why this needs the channel work.',
			'scenario.h3_ios_time_sensitive.title' => 'iOS time-sensitive — breaks through Focus',
			'scenario.h3_ios_time_sensitive.description' => 'Watch that it arrives during a Focus mode that would hold an ordinary notification.',
			'scenario.h4_ios_critical.title' => 'iOS critical — through Focus and the mute switch',
			'scenario.h4_ios_critical.description' => 'The most intrusive delivery Apple offers. Watch that it sounds even when the device is muted.',
			'scenario.h4_ios_critical.expectation' => 'Requires a critical-alert entitlement that Apple must approve for the app. Without it APNs rejects the push, so this stays untestable here — listed for completeness rather than scheduled.',
			'scenario.h5_ios_passive.title' => 'iOS passive — no sound, no wake',
			'scenario.h5_ios_passive.description' => 'The quietest level: it appears in the list without alerting. Watch that the screen does not light up.',
			'scenario.i1_silent_no_sound.title' => 'Visible but silent',
			'scenario.i1_silent_no_sound.description' => 'Appears in the tray with no sound and no vibration. Watch that it is silent but still lights the screen or not.',
			'scenario.i2_silent_data_sync.title' => 'Silent sync, drawn blank',
			'scenario.i2_silent_data_sync.description' => 'The handler writes a row; that is the effect this scenario is about. A tray entry still appears — icon and app name, no title or body — since nothing suppresses a titleless banner. Watch the Inbox page for the row; the tray entry has no text to read.',
			'scenario.i3_ios_content_available.title' => 'iOS background refresh via content-available',
			'scenario.i3_ios_content_available.description' => 'Wakes the app to fetch without showing anything. Watch how often iOS actually honours it — it throttles this aggressively.',
			'scenario.i3_ios_content_available.expectation' => 'iOS may delay or drop these entirely depending on battery and usage. A missed one is not necessarily a bug.',
			'scenario.i4_burst.title' => 'Twenty messages in ten seconds',
			'scenario.i4_burst.description' => 'Watch for rate limiting, coalescing, and manufacturer caps. MIUI will usually start dropping before FCM does.',
			'scenario.i4_burst.manual_steps' => 'Send this 20 times within 10 seconds and count what arrives. Vary the body so collapsing is visible.',
			'scenario.j1_topic.title' => 'Send to a topic',
			'scenario.j1_topic.description' => 'Subscribe the device, then send to the topic rather than the token. Watch that it arrives without the sender knowing any token at all.',
			'scenario.j1_topic.expectation' => 'Sending works now and FCM answers 200, but nothing is delivered until the app can subscribe to a topic.',
			'scenario.j2_condition.title' => 'Send to a boolean topic condition',
			'scenario.j2_condition.description' => 'A device must be in both topics to receive this. Watch that subscribing to only one excludes it.',
			'scenario.j2_condition.expectation' => 'Like j1, sending works now and FCM answers 200 — but nothing is delivered until the app can subscribe to both topics.',
			'scenario.j3_multicast.title' => 'Send to every registered device',
			'scenario.j3_multicast.description' => 'The main tool for comparing behaviour across handsets: one send, every device, and the differences are the result.',
			'scenario.j3_multicast.expectation' => 'FCM has no "all devices" audience, so this needs a token registry the API does not have. Sending it now returns 501 with that reason rather than quietly delivering to one device.',
			'scenario.k1_payload_oversize.title' => 'A payload over FCM\'s 4 KB limit',
			'scenario.k1_payload_oversize.description' => 'Watch that the API surfaces FCM\'s error with a usable message rather than a bare 400.',
			'scenario.k1_payload_oversize.expectation' => 'FCM rejects this with INVALID_ARGUMENT. The send should fail before anything reaches the device.',
			'scenario.k2_invalid_token.title' => 'A token that is no longer registered',
			'scenario.k2_invalid_token.description' => 'The everyday production failure. Watch that the API reports it as UNREGISTERED rather than a generic 404, which is what tells a real backend to delete the row.',
			'scenario.k2_invalid_token.expectation' => 'FCM answers with UNREGISTERED, which this API maps to 404 with its own wording. The errorCode in error.details takes precedence over the top-level NOT_FOUND status.',
			'scenario.k3_permission_denied.title' => 'POST_NOTIFICATIONS denied on Android 13+',
			'scenario.k3_permission_denied.description' => 'Watch that the data handler still runs and the inbox still fills, even though nothing can be drawn.',
			'scenario.k3_permission_denied.manual_steps' => 'adb shell pm revoke cz.netglade.fcm_app android.permission.POST_NOTIFICATIONS — then send, and check the Inbox page rather than the tray.',
			'scenario.k4_notifications_disabled.title' => 'Notifications switched off in system settings',
			'scenario.k4_notifications_disabled.description' => 'Distinct from a denied permission: the app has the grant and the user has turned it off. Watch that data delivery is unaffected.',
			'scenario.k4_notifications_disabled.manual_steps' => 'Settings › Apps › FCM Sample › Notifications › off. Send, then confirm the row appears in the Inbox page.',
			'scenario.k5_battery_restricted.title' => 'App in Restricted battery mode',
			'scenario.k5_battery_restricted.description' => 'The state a user reaches by tapping "restrict" in battery settings. Watch whether a HIGH priority push still wakes the app.',
			'scenario.k5_battery_restricted.manual_steps' => 'Settings › Apps › FCM Sample › Battery › Restricted. Send and compare the delay against c1_priority_high in the unrestricted state.',
			'scenario_group.a' => 'A — Basic delivery',
			'scenario_group.b' => 'B — Application states',
			'scenario_group.c' => 'C — Priority and delivery window',
			'scenario_group.d' => 'D — Channels and importance',
			'scenario_group.e' => 'E — Appearance',
			'scenario_group.f' => 'F — Interaction',
			'scenario_group.g' => 'G — Groups, badge, updates',
			'scenario_group.h' => 'H — Intrusive and priority',
			'scenario_group.i' => 'I — Silent and data',
			'scenario_group.j' => 'J — Targeting',
			'scenario_group.k' => 'K — Edge cases and errors',
			'scenario_need.channels' => 'notification channels',
			'scenario_need.styles' => 'notification styles',
			'scenario_need.interaction' => 'notification actions',
			'scenario_need.badge' => 'launcher badge',
			'scenario_need.targeting' => 'a device registry',
			'scenario_need.manual_step' => 'a manual step',
			'scenario_need.external_approval' => 'external approval',
			'channels.fcm_sample_high.name' => 'Sample pushes',
			'channels.fcm_sample_high.description' => 'Pushes received by the FCM sample app.',
			'channels.importance_high.name' => 'Importance: high',
			'channels.importance_high.description' => 'Pops as a banner and makes a sound.',
			'channels.importance_default.name' => 'Importance: default',
			'channels.importance_default.description' => 'Makes a sound but does not pop.',
			'channels.importance_low.name' => 'Importance: low',
			'channels.importance_low.description' => 'Silent. Appears in the shade only.',
			'channels.importance_min.name' => 'Importance: min',
			'channels.importance_min.description' => 'Collapsed in the shade with no icon.',
			'channels.custom_sound.name' => 'Custom sound',
			'channels.custom_sound.description' => 'Plays a bundled chime instead of the default.',
			'channels.vibration_pattern.name' => 'Vibration pattern',
			'channels.vibration_pattern.description' => 'Short, pause, short — set when the channel was created.',
			'channels.chat_v1.name' => 'Chat (v1)',
			'channels.chat_v1.description' => 'The first attempt. Its importance can no longer be changed.',
			'channels.chat_v2.name' => 'Chat (v2)',
			'channels.chat_v2.description' => 'The replacement — a new id is the only way to change importance.',
			'channels.dnd_bypass.name' => 'Do Not Disturb bypass',
			'channels.dnd_bypass.description' => 'Requested. Granted only with notification-policy access.',
			'channels.alarms.name' => 'Alarms',
			'channels.alarms.description' => 'Uses the alarm audio stream rather than the notification one.',
			'channels.group.chat.name' => 'Chat',
			'channels.title' => 'Notification channels',
			'channels.requested' => 'Requested',
			'channels.reported' => 'Reported by the system',
			'channels.not_registered' => 'Not registered',
			'channels.importance' => 'Importance',
			'channels.sound' => 'Sound',
			'channels.vibration' => 'Vibration',
			'channels.bypass_dnd' => 'Bypasses Do Not Disturb',
			'channels.group_label' => 'Group',
			'channels.badge' => 'Shows a badge',
			'channels.try_lower' => 'Try to lower it',
			'channels.immutability_hint' => 'Importance is frozen when a channel is created. Press this and watch the reported value stay put.',
			'channels.refresh' => 'Refresh',
			_ => null,
		};
	}
}
