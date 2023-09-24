/// `Notix_config.dart` - Configuration options for the Notix package.
///
/// This file defines the `NotixConfig` class, which allows developers to
/// customize the behavior of the Notix package according to their project's
/// requirements.
///
/// The `NotixConfig` class provides configuration options for various aspects
/// of the Notix package, including notification channels, log settings,
/// retry behavior, and notification handling callbacks.
///
/// Usage:
///
/// To use the Notix package with custom configuration, create an instance of
/// the `NotixConfig` class with the desired settings and pass it to the `init`
/// method when initializing the Notix package.
///
/// Example:
///
/// ```dart
/// final config = NotixConfig(
///   firebaseMessagingKey: 'your_firebase_messaging_key',
///   icon: 'your_notification_icon',
///   maxRetries: 5,
///   enableLog: true,
///   defaultChannel: yourDefaultChannel,
///   // Other configuration options...
/// );
///
/// Notix.init(
///   configs: config,
///   // Additional initialization parameters...
/// );
/// ```
///
/// This allows you to tailor the Notix package to your application's needs,
/// such as specifying custom notification channels, handling received
/// notifications, and controlling whether to show notifications based on
/// specific criteria.
///
/// See the `NotixConfig` class documentation for a complete list of available
/// configuration options and their descriptions.

import 'package:notix/src/datasource/datasource.dart';
import 'package:notix/src/models/models.dart';

/// Configuration options for the Notix package.
class NotixConfig {
  /// The Firebase Cloud Messaging (FCM) server key for sending notifications.
  final String firebaseMessagingKey;

  /// The icon to be displayed in notifications.
  final String icon;

  /// The maximum number of retry attempts for sending notifications.
  final int maxRetries;

  /// Indicates whether logging is enabled for the Notix package.
  final bool enableLog;

  /// A list of [NotixGroupChannel] instances for grouping notifications.
  final List<NotixGroupChannel> groupChannels;

  /// A list of individual [NotixChannel] instances for configuring specific channels.
  final List<NotixChannel> _channels;

  /// The identifier of the default notification channel.
  final NotixChannel defaultChannel;

  /// A callback function that returns the current signed-in user's ID.
  final String? Function()? currentUserId;

  /// Configuration for the data source used to store notifications.
  final NotixFirestore datasourceConfig;

  /// A callback function for handling received notifications.
  Function(NotixMessage)? onRecievedNotification;

  /// A callback function for handling selected notifications.
  Function(NotixMessage)? onSelectNotification;

  Function(String)? onTokenRefresh;

  /// A callback function for determining whether to show a notification.
  bool Function(NotixMessage notification)? canShowNotification;

  /// Creates a new instance of `NotixConfig` with the specified configuration options.
  ///
  /// The `firebaseMessagingKey` and `icon` parameters are required, and other
  /// parameters have default values that can be overridden.
  ///
  /// If not specified, the `maxRetries` defaults to 3, `enableLog` defaults to true,
  /// and `defaultChannel` defaults to a predefined channel with default settings.
  ///
  /// The `_channels` parameter allows you to define custom notification channels,
  /// and the `currentUser` parameter provides the current user's ID for notification
  /// handling. You can also configure a custom data source with the `datasourceConfig`
  /// parameter.
  NotixConfig({
    required this.firebaseMessagingKey,
    required this.icon,
    this.maxRetries = 3,
    this.enableLog = true,
    List<NotixChannel> channels = const [],
    this.groupChannels = const [],
    NotixChannel? defaultChannel,
    this.currentUserId,
    this.datasourceConfig = const NotixFirestore(),
    this.onRecievedNotification,
    this.onSelectNotification,
    this.canShowNotification,
  })  : _channels = channels,
        defaultChannel = defaultChannel ?? NotixChannel.defaults();

  /// Creates an instance of `NotixConfig` with default values.
  ///
  /// Use this constructor when you want to create a configuration object with
  /// default settings and then customize it further.
  NotixConfig.defaults()
      : this(
          firebaseMessagingKey: '',
          icon: '',
        );

  /// Returns a list of notification channels based on channel-specific settings
  /// and the default channel settings.
  ///
  /// This method ensures that channel-specific settings override default values
  /// where necessary.
  List<NotixChannel> get channels => _channels
      .map((e) => e.copyWith(
            playSound: e.playSound ?? defaultChannel.playSound,
            showBadge: e.showBadge ?? defaultChannel.showBadge,
            enableVibration:
                e.enableVibration ?? defaultChannel.enableVibration,
            enableLights: e.enableLights ?? defaultChannel.enableLights,
            ledColor: e.ledColor ?? defaultChannel.ledColor,
            sound: e.sound ?? defaultChannel.sound,
            importance: e.importance ?? defaultChannel.importance,
          ))
      .toList();
}
