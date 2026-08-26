import 'package:fcm_app/pages/shell/deep_link_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('deepLinkDestination', () {
    test('maps each drawer path to its destination index', () {
      expect(
        (deepLinkDestination('/inbox')! as ShellDestination).index,
        inboxDestination,
      );
      expect(
        (deepLinkDestination('/scenarios')! as ShellDestination).index,
        scenariosDestination,
      );
      expect(
        (deepLinkDestination('/sandbox')! as ShellDestination).index,
        sandboxDestination,
      );
      expect(
        (deepLinkDestination('/runs')! as ShellDestination).index,
        runsDestination,
      );
      expect(
        (deepLinkDestination('/telemetry')! as ShellDestination).index,
        telemetryDestination,
      );
      expect(
        (deepLinkDestination('/channels')! as ShellDestination).index,
        channelsDestination,
      );
    });

    test('maps /runs/<id> to that run timeline', () {
      final destination = deepLinkDestination('/runs/abc123');

      expect(destination, isA<RunTimelineDestination>());
      expect((destination! as RunTimelineDestination).runId, 'abc123');
    });

    test('tolerates one trailing slash', () {
      expect(
        (deepLinkDestination('/telemetry/')! as ShellDestination).index,
        telemetryDestination,
      );
      expect(
        (deepLinkDestination('/runs/abc123/')! as RunTimelineDestination).runId,
        'abc123',
      );
    });

    test('reads /runs/ as the Runs page, not a timeline with a blank id', () {
      final destination = deepLinkDestination('/runs/');

      expect(
        destination,
        isA<ShellDestination>(),
        reason:
            'a blank id would fetch a run that cannot exist and show an error '
            'the user did not ask for',
      );
    });

    test('ignores a query string rather than rejecting the link', () {
      expect(
        (deepLinkDestination('/telemetry?tab=events')! as ShellDestination)
            .index,
        telemetryDestination,
      );
      expect(
        (deepLinkDestination('/runs/abc123?from=push')!
                as RunTimelineDestination)
            .runId,
        'abc123',
        reason:
            'the query names no destination this app has, and rejecting an '
            'otherwise valid link would send it to the fallback for a reason '
            'the user cannot see',
      );
    });

    test('recognises nothing else', () {
      expect(deepLinkDestination('/builds/128'), isNull);
      expect(deepLinkDestination('inbox'), isNull);
      expect(deepLinkDestination('/Inbox'), isNull);
      expect(deepLinkDestination('/'), isNull);
      expect(deepLinkDestination(''), isNull);
      expect(deepLinkDestination('   '), isNull);
      expect(deepLinkDestination(null), isNull);
    });

    test('never throws on a link typed by hand in the Sandbox', () {
      for (final link in ['//', '/runs//abc', '/runs/a/b/c', '?', '/%%']) {
        expect(
          () => deepLinkDestination(link),
          returnsNormally,
          reason:
              'the Sandbox accepts any payload; a bad link must cost the '
              'link, not the tap',
        );
      }
    });
  });
}
