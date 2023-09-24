import 'dart:math';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:notix/src/utils/uuid.dart';

/// An object representing a notification to be sent or received by the Notix framework.
///
/// A [NotixMessage] instance encapsulates information about a notification, including its
/// unique [id] unique [notificationId], [channel], [type], [title], [body], [imageUrl],
///  [senders], [clientNotificationId], [payload], [importance], [playSound], and [createdAt].
/// This class is used for both sending and receiving notifications.
class NotixMessage {
  /// The unique identifier for the notification.
  final String id;

  /// A unique identifier for the notification used by the Android/iOS system
  final int notificationId;

  /// A client-specific identifier for the notification.
  final String? clientNotificationId;

  // The user ID of the target user for the notification.
  final String? targetedUserId;

  /// A list of sender identifiers associated with the notification.
  final List<String> senders;

  /// The channel through which the notification is delivered.
  final String? channel;

  /// The type of notification, which can be [NotixType.target] or [NotixType.topic].
  final NotixType type;

  /// The title of the notification.
  final String title;

  /// The main content or body of the notification.
  final String body;

  /// The URL of an optional image associated with the notification.
  final String? imageUrl;

  /// Additional payload data associated with the notification.
  final Map<String, dynamic>? payload;

  /// The importance level of the notification, which can be [Importance.min], [Importance.low],
  /// [Importance.defaultImportance], [Importance.high], or [Importance.max].
  final Importance? importance;

  /// A flag indicating whether the notification should play a sound when received.
  final bool? playSound;

  /// The date and time when the notification was created.
  final DateTime createdAt;

  /// A flag indicating whether the notification has been seen.
  final bool isSeen;

  /// Creates a new [NotixMessage] instance with the specified parameters.
  NotixMessage({
    String? id,
    int? notificationId,
    required this.clientNotificationId,
    this.senders = const [],
    this.targetedUserId,
    this.channel,
    this.type = NotixType.target,
    required this.body,
    required this.title,
    this.payload,
    this.imageUrl,
    this.importance,
    DateTime? createdAt,
    this.playSound,
    bool? isSeen,
  })  : id = id ?? GUIDGen.generate(),
        notificationId = notificationId ?? Random().nextInt(1 << 16),
        createdAt = createdAt ?? DateTime.now(),
        isSeen = isSeen ?? false;

  /// Converts the [NotixMessage] object to a JSON-encodable map.
  Map<String, dynamic> get toMap => {
        'id': id,
        'notificationId': notificationId,
        'channel': channel,
        'type': type.name,
        'title': title,
        'body': body,
        'clientNotificationId': clientNotificationId,
        'imageUrl': imageUrl,
        'importance': importance?.name,
        'createdAt': createdAt.millisecondsSinceEpoch,
        'senders': senders,
        'playSound': playSound,
        'isSeen': isSeen,
        ...payload ?? {},
      }..removeWhere((key, value) => value == null);

  /// Creates a [NotixMessage] instance from a map representation.
  ///
  /// This constructor is useful for deserializing a JSON representation of a
  /// [NotixMessage] object received from a remote source.
  NotixMessage.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        notificationId = map['notificationId'],
        clientNotificationId = map['clientNotificationId'],
        targetedUserId = map['targetedUserId'],
        senders = List.from(map['senders'] ?? []),
        channel = map['channel'],
        type = NotixType.values.firstWhere(
          (element) => element.name == map['type'],
          orElse: () => NotixType.target,
        ),
        title = map['title'],
        body = map['body'],
        payload = map,
        imageUrl = map['imageUrl'],
        importance = Importance.values.firstWhere(
          (element) => element.name == map['importance'],
          orElse: () => Importance.max,
        ),
        createdAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
        playSound = map['playSound'] ?? true,
        isSeen = map['isSeen'] ?? false;

  /// Creates a copy of this [NotixMessage] instance with the specified parameters.
  /// This method creates a new [NotixMessage] instance with the same field
  /// values as this object, except for the specified parameters.
  /// If the parameters are null, then the corresponding field values are copied
  /// from this object.
  NotixMessage copyWith({
    String? id,
    int? notificationId,
    String? channel,
    NotixType? type,
    String? title,
    String? body,
    String? clientNotificationId,
    Map<String, dynamic>? payload,
    String? imageUrl,
    Importance? importance,
    DateTime? createdAt,
    List<String>? senders,
    bool? playSound,
    bool? isSeen,
  }) {
    return NotixMessage(
      id: id ?? this.id,
      notificationId: notificationId ?? this.notificationId,
      channel: channel ?? this.channel,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      clientNotificationId: clientNotificationId ?? this.clientNotificationId,
      payload: payload ?? this.payload,
      imageUrl: imageUrl ?? this.imageUrl,
      importance: importance ?? this.importance,
      createdAt: createdAt ?? this.createdAt,
      senders: senders ?? this.senders,
      playSound: playSound ?? this.playSound,
      isSeen: isSeen ?? this.isSeen,
    );
  }
}

/// An enumeration representing the type of a notification.
enum NotixType {
  /// A notification sent to a specific target.
  target,

  /// A notification sent to a topic or group.
  topic,
}
