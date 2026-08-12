import 'dart:convert';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/foundation.dart';

import 'notification_send_exception.dart';
import 'notification_sender.dart';
import 'sandbox_send_state.dart';

/// Holds the Sandbox's raw payload editor and what became of the last send.
///
/// It holds the editor's *text*, not a parsed model, because the whole point
/// of the Sandbox is that what is typed is exactly what gets sent: every edit
/// re-parses immediately, so [parseError] and [parsedMessage] are always in
/// sync with [payloadText]. It asks for a token through a callback rather than
/// holding a `PushInbox`, so the Sandbox knows nothing about the receiving
/// side, and it holds no `TextEditingController` — that is view state, and
/// keeping it out is what lets these rules be tested without pumping a widget.
class SandboxController extends ChangeNotifier {
  /// Creates a controller wired to a sender and a way to read the current
  /// registration token.
  SandboxController({required this._sender, required this._token}) {
    // Opening on a preset means the page is sendable on arrival, and it makes
    // the gallery's purpose obvious without a tap.
    applyScenario(scenarioGallery.first);
  }

  /// Renders a template the same way every time, so the same scenario always
  /// produces byte-identical editor text.
  static const _encoder = JsonEncoder.withIndent('  ');

  final NotificationSender _sender;
  final String? Function() _token;

  String _payloadText = '';
  FcmMessage? _parsedMessage;
  String? _parseError;
  bool _validateOnly = false;
  Scenario? _selectedScenario;
  SandboxSendState _state = const SandboxIdle();
  int _scenarioRevision = 0;

  /// The JSON currently in the editor, exactly as typed.
  String get payloadText => _payloadText;

  /// Why [payloadText] does not parse into a message, or null when it does.
  String? get parseError => _parseError;

  /// The message [payloadText] currently parses to, or null while it does not.
  FcmMessage? get parsedMessage => _parsedMessage;

  /// Whether a send should only validate the request rather than deliver it.
  bool get validateOnly => _validateOnly;

  /// The scenario last applied to the editor, so the gallery can show which
  /// preset the current text started from.
  Scenario? get selectedScenario => _selectedScenario;

  /// Bumped every time a scenario is loaded, so the view can rebuild its text
  /// field from the new value without fighting the user's cursor.
  int get scenarioRevision => _scenarioRevision;

  /// Where the last send got to.
  SandboxSendState get state => _state;

  /// Why Send cannot be pressed, or null when it can.
  String? get sendBlockedReason {
    if (_token() == null) {
      return 'No registration token yet, so there is nowhere to send.';
    }
    if (_state is SandboxSending) {
      return 'Sending…';
    }
    // Covers both an unparseable payload and one that parsed but produced no
    // message: the editor already states the cause (via `parseError`) right
    // next to this text, so this only needs to state the consequence.
    if (_parsedMessage == null) {
      return 'Fix the payload before sending.';
    }

    return null;
  }

  /// Whether Send can be pressed right now.
  bool get canSend => sendBlockedReason == null;

  /// Sets whether a send should only validate the request.
  void setValidateOnly(bool value) {
    _validateOnly = value;
    notifyListeners();
  }

  /// Replaces the editor with [scenario]'s template, rendered as indented
  /// JSON so it reads the way it would if typed by hand.
  void applyScenario(Scenario scenario) {
    _selectedScenario = scenario;
    _scenarioRevision++;
    _setText(_encoder.convert(scenario.payloadTemplate));
  }

  /// Applies an edit typed into the editor, re-parsing it immediately.
  void editPayload(String text) {
    _setText(text);
  }

  /// Sends the parsed message to this device, using the current
  /// [validateOnly] flag.
  Future<void> send() async {
    final token = _token();
    final message = _parsedMessage;
    if (token == null || message == null) {
      return;
    }

    _state = const SandboxSending();
    notifyListeners();

    try {
      final response = await _sender.send(
        SendMessageRequest(
          token: token,
          message: message,
          validateOnly: _validateOnly,
        ),
      );
      _state = SandboxSent(response);
    } on NotificationSendException catch (error) {
      _state = SandboxFailed(error.message);
    }
    notifyListeners();
  }

  void _setText(String text) {
    _payloadText = text;
    // An edit invalidates the previous result: a stale "✓ Sent" next to
    // changed text would claim something untrue.
    _state = const SandboxIdle();
    _parse();
    notifyListeners();
  }

  void _parse() {
    try {
      final decoded = jsonDecode(_payloadText);
      _parsedMessage = FcmMessage.fromJson(_asMessageJson(decoded));
      _parseError = null;
    } on FormatException catch (error) {
      _parsedMessage = null;
      _parseError = error.message;
    }
  }

  /// Checks that a decoded payload is an object before it reaches
  /// [FcmMessage.fromJson] — text that decodes to a list or a number must
  /// produce a readable parse error rather than a cast failure.
  Map<String, Object?> _asMessageJson(Object? decoded) {
    if (decoded is Map<String, Object?>) {
      return decoded;
    }

    throw FormatException(
      'message: expected an object, got ${decoded.runtimeType}',
    );
  }
}
