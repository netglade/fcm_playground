import 'package:fcm_gallery_shared/fcm_gallery_shared.dart';

/// Where a send has got to. Sealed, so the view switches over it exhaustively
/// instead of reading booleans that could contradict each other.
sealed class SandboxSendState {
  const SandboxSendState();
}

/// Nothing has been sent yet, or the form has been edited since.
final class SandboxIdle extends SandboxSendState {
  const SandboxIdle();
}

final class SandboxSending extends SandboxSendState {
  const SandboxSending();
}

final class SandboxSent extends SandboxSendState {
  const SandboxSent(this.response);

  final SendMessageResponse response;
}

final class SandboxFailed extends SandboxSendState {
  const SandboxFailed(this.message);

  /// Safe to show as-is.
  final String message;
}
