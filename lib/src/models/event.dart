import 'package:notix/src/models/models.dart';

/// Enum representing different types of Notix events.
enum EventType {
  /// Event type indicating the reception of a single notification.
  receiveNotification,

  /// Event type indicating a user tap on a notification.
  notificationTap,

  /// Event type indicating the addition of a notification to the system.
  notificationAdd,
}

/// A class representing an event that occurs within the Notix framework.
///
/// The [NotixEvent] class encapsulates information about various events that
/// can be triggered by Notix, including the event type and, optionally, a
/// [NotixMessage] object representing a notification associated with the event.
///
/// Example usage:
///
/// ```dart
/// // Create a Notix event indicating the reception of a single notification.
/// NotixEvent notificationReceivedEvent = NotixEvent(
///   type: EventType.receiveNotification,
///   notification: myNotification,
/// );
///
/// // Check the event type and handle it accordingly.
/// switch (notificationReceivedEvent.type) {
///   case EventType.receiveNotification:
///     // Handle single notification reception event.
///     break;
///   case EventType.notificationTap:
///     // Handle notification tap event.
///     break;
///   case EventType.notificationAdd:
///     // Handle notification addition event.
///     break;
/// }
/// ```
class NotixEvent {
  /// The type of the Notix event.
  final EventType type;

  /// The notification associated with the event, if applicable.
  final NotixMessage? notification;

  /// Creates a new [NotixEvent] with the specified event type and optional notification.
  ///
  /// The [type] parameter specifies the type of the Notix event, such as
  /// [EventType.receiveNotification] or [EventType.notificationTap]. The
  /// [notification] parameter, if provided, represents a [NotixMessage] object
  /// associated with the event, such as the received notification itself.
  ///
  /// Example:
  ///
  /// ```dart
  /// NotixEvent notificationReceivedEvent = NotixEvent(
  ///   type: EventType.receiveNotification,
  ///   notification: myNotification,
  /// );
  /// ```
  NotixEvent({
    required this.type,
    this.notification,
  });
}
