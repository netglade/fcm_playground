/// Where the API should deliver a message.
///
/// FCM's `Message` carries a `oneof` of `token`, `topic` and `condition`, and
/// the typed [FcmMessage] deliberately rejects all three: a payload template
/// must not choose its own audience, or a template pasted from Google's docs
/// could quietly broadcast. The target therefore lives in the *envelope*
/// alongside `validate_only`, and this is that target as a closed set — so the
/// API switches on it exhaustively rather than testing fields for null.
sealed class SendTarget {
  const SendTarget();

  /// Reads the one target in [json], which sits at the request's top level.
  ///
  /// Throws when there is none or more than one. Neither is recoverable and
  /// both are dangerous to guess at: defaulting a missing target to this device
  /// would send a topic broadcast to a single phone and look like a success.
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
  /// Targets the device holding [token].
  const TokenTarget(this.token);

  /// The registration token to deliver to.
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
  /// Targets subscribers of [topic].
  const TopicTarget(this.topic);

  /// The topic name, without the `/topics/` prefix FCM's older API used.
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

/// Deliver to the devices matching a boolean topic expression.
class ConditionTarget extends SendTarget {
  /// Targets devices matching [condition], e.g. `'news' in topics`.
  const ConditionTarget(this.condition);

  /// FCM's condition expression.
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
/// Not an FCM concept: FCM has no "all devices" audience, so honouring this
/// means keeping a registry of tokens and sending to each. The API therefore
/// refuses it with a stated reason until that registry exists, which is better
/// than falling back to this device and reporting success.
class AllDevicesTarget extends SendTarget {
  /// Targets every registered device.
  const AllDevicesTarget();

  @override
  Map<String, Object?> toJson() => {'all_devices': true};

  @override
  bool operator ==(Object other) => other is AllDevicesTarget;

  // There is no field to hash, so every instance is the same value and the type
  // is the whole identity.
  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() => 'AllDevicesTarget()';
}
