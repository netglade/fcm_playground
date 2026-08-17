import 'dart:convert';
import 'dart:io';

import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:http/http.dart' as http;

/// Sends every catalogue scenario through the local API with `validate_only`, and
/// reports which ones Google refuses.
///
/// The one check the test suite cannot make: the gallery round-trip test proves each
/// template agrees with our typed model, but only Google knows which field
/// combinations it rejects.
///
/// The two scenarios in [_expectedFailures] are reported as EXPECTED rather than
/// counted as failures. Anything else that is not a 200 names a template to fix.
///
/// Usage, with the API already running:
///
/// ```
/// fvm dart run apps/fcm_api/bin/validate_sweep.dart <device-token> [base-url]
/// ```
///
/// The device token comes off the app's Inbox page and stands in for the 62
/// scenarios that target "this device". Pass `-` to skip those and sweep only the
/// four that name their own audience.
Future<void> main(List<String> arguments) async {
  if (arguments.isEmpty) {
    stderr.writeln(
      'Usage: validate_sweep.dart <device-token|-> [base-url]\n'
      'The token is on the app\'s Inbox page. "-" sweeps only the scenarios '
      'that carry their own target.',
    );
    exitCode = 64;

    return;
  }

  final token = arguments.first == '-' ? null : arguments.first;
  final baseUrl = arguments.length > 1 ? arguments[1] : 'http://127.0.0.1:8080';

  final client = http.Client();
  try {
    exitCode = await _sweep(client, baseUrl: baseUrl, deviceToken: token);
  } finally {
    client.close();
  }
}

Future<int> _sweep(
  http.Client client, {
  required String baseUrl,
  required String? deviceToken,
}) async {
  final failures = <String>[];
  var unreachable = false;
  var passed = 0;
  var expected = 0;
  var skipped = 0;

  for (final scenario in scenarioGallery) {
    final target =
        scenario.target ??
        (deviceToken == null ? null : TokenTarget(deviceToken));
    if (target == null) {
      skipped++;
      continue;
    }

    final outcome = await _send(client, baseUrl, target, scenario);
    stdout.writeln(outcome.line);
    if (outcome.failed) {
      failures.add(scenario.id);
      unreachable |= outcome.unreachable;
    } else if (outcome.expected) {
      expected++;
    } else {
      passed++;
    }
  }

  stdout.writeln(
    '\n$passed passed, $expected expected non-200, ${failures.length} FAILED, '
    '$skipped skipped (no device token).',
  );
  if (unreachable) {
    // Saying "FCM refused these" when nothing reached FCM would send someone
    // hunting through templates for what is a stopped server.
    stdout.writeln(
      'The API was unreachable, so nothing was actually validated. Start it '
      'with melos run api:serve and check http://127.0.0.1:8080/health.',
    );
  } else if (failures.isNotEmpty) {
    stdout.writeln('Templates FCM refused: ${failures.join(', ')}');
  }

  return failures.isEmpty ? 0 : 1;
}

/// Posts one scenario and classifies the response.
///
/// Returns a record rather than declaring a result type, because a private class
/// or enum here would be the file's first declaration and trip DCM's
/// `prefer-match-file-name`.
Future<({bool failed, bool expected, bool unreachable, String line})> _send(
  http.Client client,
  String baseUrl,
  SendTarget target,
  Scenario scenario,
) async {
  final body = {
    ...target.toJson(),
    'validate_only': true,
    'message': scenario.payloadTemplate,
  };

  final http.Response response;
  try {
    response = await client.post(
      Uri.parse('$baseUrl/send'),
      headers: const {'content-type': 'application/json'},
      body: jsonEncode(body),
    );
  } on Object {
    // A dead socket is a setup problem, not a bad template, and saying so beats
    // reporting 66 identical failures.
    return (
      failed: true,
      expected: false,
      unreachable: true,
      line: 'FAIL     ${scenario.id}  (could not reach $baseUrl)',
    );
  }

  if (response.statusCode == 200) {
    return (
      failed: false,
      expected: false,
      unreachable: false,
      line: 'ok       ${scenario.id}',
    );
  }

  final wasExpected = _expectedFailures.containsKey(scenario.id);
  final note = _expectedFailures[scenario.id] ?? response.body;

  return (
    failed: !wasExpected,
    expected: wasExpected,
    unreachable: false,
    line:
        '${wasExpected ? 'expected' : 'FAIL    '} '
        '${scenario.id}  ${response.statusCode}  $note',
  );
}

/// The scenarios whose whole purpose is to be refused, and why.
const _expectedFailures = {
  'j3_multicast': 'FCM has no all-devices audience; the API answers 501',
  'k2_invalid_token': 'the token was never real; UNREGISTERED is the point',
};
