import 'package:fcm_app/domains/push/repositories/push_repository.dart';
import 'package:fcm_app/pages/inbox/cubit/inbox_cubit.dart';
import 'package:fcm_app/pages/inbox/cubit/inbox_state.dart';
import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../fakes/fake_push_payload_store.dart';
import '../../../fakes/fake_push_source.dart';

Map<String, Object?> payload({String id = 'msg-1'}) => {
  'id': id,
  'title': 'Hello',
  'body': 'A message body.',
  'sentAt': '2026-08-06T09:30:00Z',
};

void main() {
  late FakePushSource source;
  late PushRepository repository;
  late InboxCubit inbox;

  setUp(() {
    source = FakePushSource();
    repository = PushRepository(source, store: FakePushPayloadStore())
      ..listen();
    inbox = InboxCubit(repository);
  });

  tearDown(() async {
    await inbox.close();
    repository.dispose();
    await source.dispose();
  });

  test('starts from what the repository already holds', () async {
    // The repository is older than the page: `main()` restores and fetches the token
    // before the first frame, and a setup error is never published at all. A blank
    // initial state would blank the banner and the token until the next push.
    final started = PushRepository(
      FakePushSource(),
      store: FakePushPayloadStore(inbox: [payload(id: 'restored')]),
      setupError: 'Firebase is not configured',
    );
    addTearDown(started.dispose);
    await started.restore();
    await started.refreshToken();

    final projection = InboxCubit(started);
    addTearDown(projection.close);

    expect(projection.state.messages.single.id, 'restored');
    expect(projection.state.token, 'fake-token');
    expect(projection.state.setupError, 'Firebase is not configured');
  });

  test('projects the repository rather than a copy of it', () async {
    await repository.refreshToken();
    source.emit(payload());
    source.emit({'id': 'broken'});
    await pumpEventQueue();

    expect(inbox.state.messages.single.id, 'msg-1');
    expect(inbox.state.rejections, hasLength(1));
    expect(inbox.state.token, 'fake-token');
    expect(inbox.state.setupError, isNull);
  });

  test('emits to the widget tree when the repository changes', () async {
    var emissions = 0;
    final watching = inbox.stream.listen((_) => emissions++);
    addTearDown(watching.cancel);

    source.emit(payload());
    await pumpEventQueue();

    expect(emissions, 1);
  });

  test('resolves a tap against what the repository holds now', () async {
    inbox.requestOpen('late', OpenedFrom.background);
    expect(
      inbox.state.hasPendingOpen,
      isTrue,
      reason: 'the tap is outstanding straight away, before its message exists',
    );
    expect(inbox.state.pendingOpen, isNull);

    source.emit(payload(id: 'late'));
    await pumpEventQueue();

    expect(inbox.state.pendingOpen?.id, 'late');
    inbox.clearPendingOpen();
    expect(inbox.state.hasPendingOpen, isFalse);
  });

  test('publishes a cleared tap rather than clearing it silently', () async {
    // Its own guard, with the emission counted: a `clearPendingOpen` that mutated
    // and stayed silent would leave the cubit claiming a tap is outstanding until
    // some unrelated push published.
    final seen = <InboxState>[];
    final watching = inbox.stream.listen(seen.add);
    addTearDown(watching.cancel);
    inbox.requestOpen('msg-1', OpenedFrom.background);
    await pumpEventQueue();
    expect(seen.single.pendingOpenId, 'msg-1');

    inbox.clearPendingOpen();
    await pumpEventQueue();

    expect(seen, hasLength(2));
    expect(seen.last.hasPendingOpen, isFalse);
  });

  test('stops emitting once closed', () async {
    // A second projection, because the one from setUp is closed in tearDown and
    // a cubit may only be closed once.
    final closed = InboxCubit(repository);
    final seen = <InboxState>[];
    final watching = closed.stream.listen(seen.add);
    addTearDown(watching.cancel);

    await closed.close();
    source.emit(payload());
    await pumpEventQueue();

    expect(
      seen,
      isEmpty,
      reason:
          'and no error either: emitting on a closed cubit throws, so the '
          'subscription onto the app-scoped repository really was cancelled '
          'rather than left to accumulate one per page',
    );
  });
}
