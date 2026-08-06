import 'package:flutter/material.dart';

import '../push/push_inbox.dart';
import 'inbox_screen.dart';

/// Root widget. Takes the [PushInbox] as a parameter rather than creating one,
/// so widget tests can supply an inbox wired to a fake source.
class FcmSampleApp extends StatelessWidget {
  const FcmSampleApp({required this.inbox, super.key});

  final PushInbox inbox;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'FCM Sample',
    theme: ThemeData(colorSchemeSeed: Colors.indigo),
    home: InboxScreen(inbox: inbox),
  );
}
