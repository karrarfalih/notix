import 'package:flutter/material.dart';
import 'package:notix/src/models/enums.dart';

/// Represents a notification channel configuration.
///
/// A [NotixChannel] defines how notifications will be displayed to the user.
/// You can customize various aspects of notifications such as the channel's
/// name, description, sound, and more using this configuration.
///
/// Example usage:
///
/// ```dart
/// NotixChannel channel = NotixChannel(
///   id: 'channel_id',
///   name: 'Channel Name',
///   description: 'Channel Description',
///   playSound: true,
///   showBadge: true,
///   enableVibration: true,
///   enableLights: true,
///   ledColor: Colors.blue,
///   sound: 'custom_sound.mp3',
///   importance: NotixImportance.high,
/// );
/// ```
class NotixChannel {
  /// The unique identifier for this notification channel.
  final String id;

  /// The group identifier for this channel. Notifications in the same group
  /// are grouped together in the notification tray.
  final String? groupId;

  /// The user-visible name of the notification channel.
  final String name;

  /// The user-visible description of the notification channel.
  final String? description;

  /// Determines whether notifications in this channel should play a sound.
  final bool? playSound;

  /// Determines whether notifications in this channel should show a badge.
  final bool? showBadge;

  /// Determines whether notifications in this channel should enable vibration.
  final bool? enableVibration;

  /// Determines whether notifications in this channel should enable lights.
  final bool? enableLights;

  /// The LED color for notifications in this channel.
  final Color? ledColor;

  /// The custom sound file to be played for notifications in this channel.
  final String? sound;

  /// The importance level of this notification channel.
  final NotixImportance? importance;

  /// Creates a new [NotixChannel] instance with the specified configurations.
  ///
  /// The [id] parameter must be a unique identifier for the channel.
  /// The [name] parameter is the user-visible name of the channel.
  /// The [description] parameter is the user-visible description of the channel.
  /// The [playSound] parameter determines whether notifications in the channel should play a sound.
  /// The [showBadge] parameter determines whether notifications in the channel should show a badge.
  /// The [enableVibration] parameter determines whether notifications in the channel should enable vibration.
  /// The [enableLights] parameter determines whether notifications in the channel should enable lights.
  /// The [ledColor] parameter specifies the LED color for notifications in the channel.
  /// The [sound] parameter specifies a custom sound file for notifications in the channel.
  /// The [NotixImportance] parameter defines the importance level of the channel.
  ///
  /// Example:
  ///
  /// ```dart
  /// NotixChannel channel = NotixChannel(
  ///   id: 'channel_id',
  ///   name: 'Channel Name',
  ///   description: 'Channel Description',
  ///   playSound: true,
  ///   showBadge: true,
  ///   enableVibration: true,
  ///   enableLights: true,
  ///   ledColor: Colors.blue,
  ///   sound: 'custom_sound.mp3',
  ///   importance: NotixImportance.high,
  /// );
  /// ```
  NotixChannel({
    required this.id,
    this.groupId,
    required this.name,
    this.description,
    this.playSound,
    this.showBadge,
    this.enableVibration,
    this.enableLights,
    this.ledColor,
    this.sound,
    this.importance,
  });

  /// Creates a new [NotixChannel] instance from a map representation.
  ///
  /// This constructor is used to deserialize a [NotixChannel] object from a map.
  /// The map should contain keys that correspond to the field names of the class.
  ///
  /// Example:
  ///
  /// ```dart
  /// Map<String, dynamic> channelMap = {
  ///   'id': 'channel_id',
  ///   'groupId': 'group_id',
  ///   'name': 'Channel Name',
  ///   'description': 'Channel Description',
  ///   'playSound': true,
  ///   'showBadge': true,
  ///   'enableVibration': true,
  ///   'enableLights': true,
  ///   'ledColor': Colors.blue.value,
  ///   'sound': 'custom_sound.mp3',
  ///   'importance': 'high',
  /// };
  ///
  /// NotixChannel channel = NotixChannel.fromMap(channelMap);
  /// ```
  NotixChannel.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        groupId = map['groupId'],
        name = map['name'],
        description = map['description'],
        playSound = map['playSound'],
        showBadge = map['showBadge'],
        enableVibration = map['enableVibration'],
        enableLights = map['enableLights'],
        ledColor = map['ledColor'] == null ? null : Color(map['ledColor']),
        sound = map['sound'],
        importance = map['importance'] == null
            ? null
            : NotixImportance.values.firstWhere(
                (element) => element.name == map['importance'],
              );

  /// Converts this [NotixChannel] object to a map representation.
  ///
  /// This method is used to serialize a [NotixChannel] object into a map.
  /// The resulting map can be used for storage or transmission purposes.
  ///
  /// Example:
  ///
  /// ```dart
  /// NotixChannel channel = NotixChannel(
  ///   id: 'channel_id',
  ///   name: 'Channel Name',
  ///   description: 'Channel Description',
  ///   playSound: true,
  ///   showBadge: true,
  ///   enableVibration: true,
  ///   enableLights: true,
  ///   ledColor: Colors.blue,
  ///   sound: 'custom_sound.mp3',
  ///   importance: NotixImportance.high,
  /// );
  ///
  /// Map<String, dynamic> channelMap = channel.toJson;
  /// ```
  Map<String, dynamic> get toJson => {
        'id': id,
        'groupId': groupId,
        'name': name,
        'description': description,
        'playSound': playSound,
        'showBadge': showBadge,
        'enableVibration': enableVibration,
        'enableLights': enableLights,
        'ledColor': ledColor?.value,
        'sound': sound,
        'importance': importance?.name,
      }..removeWhere((key, value) => value == null);

  /// Creates a copy of this [NotixChannel] with optional field updates.
  ///
  /// This method creates a new [NotixChannel] instance with the same field
  /// values as this instance. You can provide new values for optional fields
  /// to create a modified copy.
  ///
  /// Example:
  ///
  /// ```dart
  /// NotixChannel originalChannel = NotixChannel(
  ///   id: 'channel_id',
  ///   name: 'Channel Name',
  ///   description: 'Channel Description',
  /// );
  ///
  /// NotixChannel updatedChannel = originalChannel.copyWith(
  ///   playSound: true,
  ///   showBadge: true,
  ///   enableVibration: true,
  ///   enableLights: true,
  /// );
  /// ```
  NotixChannel copyWith({
    bool? playSound,
    bool? showBadge,
    bool? enableVibration,
    bool? enableLights,
    Color? ledColor,
    String? sound,
    NotixImportance? importance,
  }) {
    return NotixChannel(
      id: id,
      name: name,
      description: description,
      playSound: playSound ?? this.playSound,
      showBadge: showBadge ?? this.showBadge,
      enableVibration: enableVibration ?? this.enableVibration,
      enableLights: enableLights ?? this.enableLights,
      ledColor: ledColor ?? this.ledColor,
      sound: sound ?? this.sound,
      importance: importance ?? this.importance,
    );
  }

  /// Creates a new [NotixChannel] instance with default configurations.
  NotixChannel.defaults()
      : id = 'general',
        name = 'General',
        groupId = null,
        description = 'General Notifications',
        playSound = null,
        showBadge = null,
        enableVibration = null,
        enableLights = null,
        ledColor = null,
        sound = null,
        importance = null;
}
