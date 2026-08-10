import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';
import 'package:flutter/material.dart';

/// What happened to the last send.
///
/// Reports the payload id on success, because that is the value about to show up
/// in the inbox — it is what turns "it said sent" into something checkable.
class SendResultCard extends StatelessWidget {
  const SendResultCard({
    required this.response,
    required this.error,
    super.key,
  });

  final SendNotificationResponse? response;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    if (error case final failure?) {
      return Card(
        color: colors.errorContainer,
        child: ListTile(
          leading: Icon(Icons.error_outline, color: colors.onErrorContainer),
          title: const Text('Send failed'),
          subtitle: Text(failure),
        ),
      );
    }

    if (response case final sent?) {
      return Card(
        color: colors.secondaryContainer,
        child: ListTile(
          leading: const Icon(Icons.check),
          title: Text('Sent · id ${sent.payloadId}'),
          subtitle: const Text('It should appear in the Inbox shortly.'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
