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
	late final Translations$scenario_needs$en scenario_needs = Translations$scenario_needs$en._(_root);
	late final Translations$send_result$en send_result = Translations$send_result$en._(_root);
	late final Translations$countdown$en countdown = Translations$countdown$en._(_root);
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

	/// The same button once pressed
	///
	/// en: 'Reported as never arrived'
	String get reported => 'Reported as never arrived';
}

// Path: scenario_needs
class Translations$scenario_needs$en {
	Translations$scenario_needs$en._(this._root);

	final Translations _root; // ignore: unused_field

	// Translations

	/// Banner listing what a scenario is missing
	///
	/// en: 'Needs $needs. The push will still be sent, but this scenario cannot be observed yet.'
	String banner({required Object needs}) => 'Needs ${needs}. The push will still be sent, but this scenario cannot be observed yet.';
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
			'message_tile.no_title' => '(no title)',
			'message_tile.body_with_data' => ({required Object body, required Object keys}) => '${body}\ndata: ${keys}',
			'scenarios.no_token' => 'No registration token yet, so there is nowhere to send. Open the Inbox once the app has registered.',
			'scenario_card.needs_work' => 'needs work',
			'common.needs_killed_app' => 'Needs the app killed',
			'common.cancel' => 'Cancel',
			'common.schedule_ellipsis' => 'Schedule…',
			'common.reload' => 'Reload',
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
			'scenario_needs.banner' => ({required Object needs}) => 'Needs ${needs}. The push will still be sent, but this scenario cannot be observed yet.',
			'send_result.validated' => ({required Object messageId, required Object traceId}) => '✓ Validated · message ${messageId} · trace ${traceId} · the payload was validated, not sent',
			'send_result.sent' => ({required Object messageId, required Object traceId}) => '✓ Sent · message ${messageId} · trace ${traceId} · it should appear in the Inbox shortly',
			'send_result.scheduled' => ({required num n, required Object runId}) => (_root.$meta.cardinalResolver ?? PluralResolvers.cardinal('en'))(n, one: '✓ Scheduled · run ${runId} · ${n} message · nothing has been sent yet', few: '✓ Scheduled · run ${runId} · ${n} messages · nothing has been sent yet', other: '✓ Scheduled · run ${runId} · ${n} messages · nothing has been sent yet', ), 
			'countdown.seconds' => 'seconds',
			'countdown.swipe_away' => 'Swipe the app away from recents now. The push is already scheduled on the server, so it will arrive whether this app is running or not.',
			'countdown.dim_note' => 'An ordinary app cannot switch the display off — only dim it and let go of the wakelock, so the system times out on its own.',
			'countdown.dim_screen' => 'Dim the screen',
			'countdown.battery_settings' => 'Battery settings',
			_ => null,
		};
	}
}
