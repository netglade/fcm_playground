import 'package:fcm_app/push/push_inbox.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_push_source.dart';

Map<String, Object?> payload({String id = 'msg-1', String title = 'Hello'}) => {
  'id': id,
  'title': title,
  'body': 'A message body.',
  'sentAt': '2026-08-06T09:30:00Z',
};

void main() {
  late FakePushSource source;
  late PushInbox inbox;

  setUp(() {
    source = FakePushSource();
    inbox = PushInbox(source)..listen();
  });

  tearDown(() async {
    inbox.dispose();
    await source.dispose();
  });

  test('starts empty', () {
    expect(inbox.messages, isEmpty);
    expect(inbox.rejections, isEmpty);
    expect(inbox.setupError, isNull);
  });

  test('exposes a received message and notifies listeners', () async {
    var notifications = 0;
    inbox.addListener(() => notifications++);

    source.emit(payload());
    await pumpEventQueue();

    expect(inbox.messages.single.title, 'Hello');
    expect(notifications, 1);
  });

  test('orders messages newest first', () async {
    source
      ..emit(payload(id: 'msg-1', title: 'First'))
      ..emit(payload(id: 'msg-2', title: 'Second'));
    await pumpEventQueue();

    expect(inbox.messages.map((m) => m.title), ['Second', 'First']);
  });

  test('drops a repeated message id', () async {
    source
      ..emit(payload(id: 'msg-1'))
      ..emit(payload(id: 'msg-1'));
    await pumpEventQueue();

    expect(inbox.messages, hasLength(1));
  });

  test('records a malformed payload instead of throwing', () async {
    source.emit({'id': 'msg-1', 'title': 'No body or timestamp'});
    await pumpEventQueue();

    expect(inbox.messages, isEmpty);
    expect(inbox.rejections.single, contains('body'));
  });

  test('refreshToken exposes the token', () async {
    await inbox.refreshToken();

    expect(inbox.token, 'fake-token');
  });

  test('refreshToken leaves the token null when the source fails', () async {
    final failing = FakePushSource(tokenThrows: true);
    final failingInbox = PushInbox(failing);
    addTearDown(failingInbox.dispose);
    addTearDown(failing.dispose);

    await failingInbox.refreshToken();

    expect(failingInbox.token, isNull);
  });
}
