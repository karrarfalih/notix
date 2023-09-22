/// Represents a notification group channel configuration.
///
/// A [NotixGroupChannel] defines a group for organizing notifications in the
/// notification tray. Notifications with the same group identifier are grouped
/// together to improve the organization of notifications.
///
/// Example usage:
///
/// ```dart
/// NotixGroupChannel groupChannel = NotixGroupChannel(
///   id: 'group_id',
///   name: 'Group Name',
///   description: 'Group Description',
/// );
/// ```
class NotixGroupChannel {
  /// The unique identifier for this notification group channel.
  final String id;

  /// The user-visible name of the notification group channel.
  final String name;

  /// The user-visible description of the notification group channel.
  final String? description;

  /// Creates a new [NotixGroupChannel] instance with the specified configurations.
  ///
  /// The [id] parameter must be a unique identifier for the group channel.
  /// The [name] parameter is the user-visible name of the group channel.
  /// The [description] parameter is the user-visible description of the group channel.
  ///
  /// Example:
  ///
  /// ```dart
  /// NotixGroupChannel groupChannel = NotixGroupChannel(
  ///   id: 'group_id',
  ///   name: 'Group Name',
  ///   description: 'Group Description',
  /// );
  /// ```
  NotixGroupChannel({
    required this.id,
    required this.name,
    this.description,
  });
}
