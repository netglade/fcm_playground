import 'package:fcm_app/push/push_inbox.dart';
import 'package:fcm_app/push/push_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fake_push_payload_store.dart';
import '../fake_push_source.dart';

Map<String, Object?> payload({String id = 'msg-1'}) => {
  'id': id,
  'title': 'Hello',
  'body': 'A message body.',
  'sentAt': '2026-08-06T09:30:00Z',
};

void main() {
  late FakePushSource source;
  late PushRepository repository;
  late PushInbox inbox;

  setUp(() {
    source = FakePushSource();
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = PushInbox(repository);
  });

  tearDown(() async {
    inbox.dispose();
    repository.dispose();
    await source.dispose();
  });

  test('reads through to the repository rather than a copy', () async {
    await repository.refreshToken();
    source.emit(payload());
    source.emit({'id': 'broken'});
    await pumpEventQueue();

    expect(inbox.messages.single.id, 'msg-1');
    expect(inbox.rejections, hasLength(1));
    expect(inbox.token, 'fake-token');
    expect(inbox.setupError, isNull);
  });

  test('notifies the widget tree when the repository changes', () async {
    var notifications = 0;
    inbox.addListener(() => notifications++);

    source.emit(payload());
    await pumpEventQueue();

    expect(notifications, 1);
  });

  test('resolves a tap against what the repository holds now', () async {
    inbox.requestOpen('late');
    expect(
      inbox.hasPendingOpen,
      isTrue,
      reason: 'the tap is outstanding straight away, before its message exists',
    );
    expect(inbox.pendingOpen, isNull);

    source.emit(payload(id: 'late'));
    await pumpEventQueue();

    expect(inbox.pendingOpen?.id, 'late');
    inbox.clearPendingOpen();
    expect(inbox.hasPendingOpen, isFalse);
  });

  test('stops notifying once disposed', () async {
    // A second adapter, because the one from setUp is disposed in tearDown and a
    // ChangeNotifier may only be disposed once.
    final closed = PushInbox(repository);
    var notifications = 0;
    closed.addListener(() => notifications++);

    closed.dispose();
    source.emit(payload());
    await pumpEventQueue();

    expect(
      notifications,
      0,
      reason:
          'and no error either: notifying a disposed ChangeNotifier throws, so '
          'the subscription really was cancelled',
    );
  });
}
