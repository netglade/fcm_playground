import 'package:fcm_app/domains/notifications/notification_group_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('withMemberAdded', () {
    test('adds a message to a group it is not yet in', () {
      expect(
        withMemberAdded(
          {
            'builds': ['msg-1'],
          },
          'builds',
          'msg-2',
        ),
        {
          'builds': ['msg-1', 'msg-2'],
        },
      );
    });

    test('creates the group when it is the first member', () {
      expect(withMemberAdded(const {}, 'builds', 'msg-1'), {
        'builds': ['msg-1'],
      });
    });

    test('does not add a message twice', () {
      expect(
        withMemberAdded(
          {
            'builds': ['msg-1'],
          },
          'builds',
          'msg-1',
        ),
        {
          'builds': ['msg-1'],
        },
        reason:
            'a tagged notification is redrawn under the same id, and counting '
            'it again would make the summary claim more than the tray shows',
      );
    });

    test('leaves other groups alone', () {
      expect(
        withMemberAdded(
          {
            'alerts': ['msg-9'],
          },
          'builds',
          'msg-1',
        ),
        {
          'alerts': ['msg-9'],
          'builds': ['msg-1'],
        },
      );
    });
  });

  group('groupSummaryText', () {
    test('counts the members', () {
      expect(groupSummaryText(5, 'builds'), '5 builds');
    });

    test('says one without pluralising the group name', () {
      expect(
        groupSummaryText(1, 'builds'),
        '1 builds',
        reason:
            'the group name comes from the payload, so the app cannot know its '
            'singular — inventing one would be wrong more often than it is right',
      );
    });
  });
}
