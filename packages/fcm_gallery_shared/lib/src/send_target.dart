/// Where the API should deliver a message.
///
/// The typed [FcmMessage] deliberately rejects FCM's `token`/`topic`/`condition`
/// `oneof`: a payload template must not choose its own audience, or a template
/// pasted from Google's docs could quietly broadcast. The target lives in the
/// envelope instead, as a closed set the API switches on exhaustively.
sealed class SendTarget {
  const SendTarget();

  /// Reads the one target in [json], throwing when there is none or more than one.
  /// Defaulting a missing target to this device would send a topic broadcast to a
  /// single phone and look like a success.
  static SendTarget readFrom(Map<String, Object?> json) {
    const keys = ['token', 'topic', 'condition', 'all_devices'];
    final present = keys.where(json.containsKey).toList();

    if (present.isEmpty) {
      throw FormatException(
        'a delivery target is required: one of ${keys.join(', ')}',
      );
    }
    if (present.length > 1) {
      throw FormatException(
        'only one delivery target is allowed, got ${present.join(' and ')}',
      );
    }

    final key = present.single;
    if (key == 'all_devices') {
      return const AllDevicesTarget();
    }

    final value = json[key];
    if (value is! String) {
      throw FormatException(
        '"$key" must be a String, got ${value.runtimeType}',
      );
    }
    if (value.trim().isEmpty) {
      throw FormatException('"$key" must not be blank');
    }

    return switch (key) {
      'token' => TokenTarget(value),
      'topic' => TopicTarget(value),
      _ => ConditionTarget(value),
    };
  }

  /// The single key/value this target contributes to the request body.
  Map<String, Object?> toJson();
}

/// Deliver to one device's registration token.
class TokenTarget extends SendTarget {
  const TokenTarget(this.token);

  final String token;

  @override
  Map<String, Object?> toJson() => {'token': token};

  @override
  bool operator ==(Object other) =>
      other is TokenTarget && other.token == token;

  @override
  int get hashCode => Object.hash(TokenTarget, token);

  @override
  String toString() => 'TokenTarget($token)';
}

/// Deliver to every device subscribed to a topic.
class TopicTarget extends SendTarget {
  const TopicTarget(this.topic);

  /// Without the `/topics/` prefix FCM's older API used.
  final String topic;

  @override
  Map<String, Object?> toJson() => {'topic': topic};

  @override
  bool operator ==(Object other) =>
      other is TopicTarget && other.topic == topic;

  @override
  int get hashCode => Object.hash(TopicTarget, topic);

  @override
  String toString() => 'TopicTarget($topic)';
}

/// Deliver to the devices matching a boolean topic expression such as
/// `'news' in topics`.
class ConditionTarget extends SendTarget {
  const ConditionTarget(this.condition);

  final String condition;

  @override
  Map<String, Object?> toJson() => {'condition': condition};

  @override
  bool operator ==(Object other) =>
      other is ConditionTarget && other.condition == condition;

  @override
  int get hashCode => Object.hash(ConditionTarget, condition);

  @override
  String toString() => 'ConditionTarget($condition)';
}

/// Deliver to every device this project has ever registered.
///
/// Not an FCM concept, so honouring it means keeping a registry of tokens. The API
/// refuses it with a stated reason until that registry exists, which beats falling
/// back to this device and reporting success.
class AllDevicesTarget extends SendTarget {
  const AllDevicesTarget();

  @override
  Map<String, Object?> toJson() => {'all_devices': true};

  @override
  bool operator ==(Object other) => other is AllDevicesTarget;

  // No field to hash, so the type is the whole identity.
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AllDevicesTarget()';
}
