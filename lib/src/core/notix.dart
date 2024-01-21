/// The [Notix] class provides functionality for managing notifications.
///
/// Use this class to send, receive, and manage notifications in your Flutter app.

import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:notix/src/models/models.dart';
import 'package:notix/src/utils/log.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

part 'channels.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Notix._recievedNotificationHandler(message);
}

abstract class Notix {
  static final _ChannelsService _channels = _ChannelsService();
  static final _messaging = FirebaseMessaging.instance;
  static bool _isInitialized = false;
  static late FlutterLocalNotificationsPlugin _plugin;
  static final List<String> _topics = [];
  static final dio = Dio(
    BaseOptions(
      receiveTimeout: const Duration(seconds: 15),
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  static NotixConfig _configs = NotixConfig.defaults();

  /// The current configuration for the Notix library.
  static NotixConfig get configs => _configs;

  /// Sets the configuration for the Notix library.
  static set configs(NotixConfig value) {
    NotixLog.d('Configs added.');
    _configs = value;
  }

  /// Streams events related to notifications.
  ///
  /// Use the `eventsStream` to listen for events related to notifications, such
  /// as when a notification is received or when a notification is tapped by the user.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// Notix.eventsStream.listen((event) {
  ///   print('Received event: ${event.type}');
  /// });
  /// ```
  static Stream<NotixEvent> get stream {
    _eventController ??= StreamController<NotixEvent>.broadcast();
    return _eventController!.stream;
  }

  static StreamController<NotixEvent>? _eventController;

  /// Initializes the Notix package with custom configurations.
  ///
  /// This method initializes the Notix package with the specified [configs],
  /// allowing you to customize various aspects of notification behavior,
  /// channels, permissions, and event handling. It should be called once during
  /// the app's initialization phase.
  ///
  /// To use custom configurations, create an instance of the [NotixConfig] class
  /// with the desired settings and pass it as the `configs` parameter when
  /// calling this method.
  ///
  /// Firestore Indexes:
  /// To ensure efficient Firestore queries and operations, you need to set up
  /// appropriate Firestore indexes. You can do this by adding the following indexes
  /// in the Firebase console:
  ///
  /// Collection: your_collection_path (by default: notix)
  /// 1- for querying notifications for the current user:
  ///   Fields:
  ///   - targetedUserId (Ascending)
  ///   - createdAt (Descending)
  ///
  /// 2- for marking notifications as seen:
  ///  Fields:
  ///   - targetedUserId (Ascending)
  ///   - isSeen (Ascending)
  ///
  /// Example:
  ///
  /// ```dart
  /// final customConfig = NotixConfig(
  ///   firebaseMessagingKey: 'your_firebase_messaging_key',
  ///   icon: 'your_notification_icon',
  ///   maxRetries: 5,
  ///   enableLog: true,
  ///   defaultChannel: yourDefaultChannel,
  ///   // Other configuration options...
  /// );
  ///
  /// await Notix.init(
  ///   configs: customConfig,
  /// );
  /// ```
  ///
  /// Parameters:
  ///
  /// - `configs`: The custom configuration for the Notix package.
  ///
  /// Throws:
  ///
  /// - [NotixInitializationException]: If the Notix failed to initialize.
  /// - [NotixPermissionException]: If notification permissions are denied.
  ///
  /// Note:
  ///
  /// - Make sure that Firebase is initialized before calling this method.
  /// - On Android, this method will also request notification permissions from the user.
  /// - On platforms other than Android, notification permissions are determined by the device's settings.
  /// - If the package is initialized multiple times, only the first initialization will take effect.
  /// - Firebase Messaging background handler is registered during initialization for handling background notifications.
  /// - Default notification settings are applied based on the provided [configs].
  /// - Notification events can be observed using the [stream].
  ///
  /// See also: [NotixConfig], [checkNotificationsPermission], [stream]
  static Future<void> init({
    required NotixConfig configs,
  }) async {
    if (_isInitialized) {
      NotixLog.d('Notix is already initialized.', isError: true);
      return;
    }
    if (Firebase.apps.isEmpty) {
      throw NotixInitializationException('You must init the firebase first.');
    }
    Notix.configs = configs;
    final isGranted = await _requestNotificationPermission();
    if (!isGranted) {
      throw NotixPermissionException('Permission denied.');
    }
    tz.initializeTimeZones();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    if (!kIsWeb) {
      _plugin = FlutterLocalNotificationsPlugin();
      await _channels.init();
      try {
        await FirebaseMessaging.instance
            .setForegroundNotificationPresentationOptions(
          alert: false,
          badge: true,
          sound: false,
        );
        _plugin.initialize(
          InitializationSettings(
            android: AndroidInitializationSettings(configs.icon),
            iOS: DarwinInitializationSettings(
              requestAlertPermission: true,
              requestBadgePermission: _channels._hasBadge,
              requestSoundPermission: _channels._hasSound,
              notificationCategories: _channels._iosChannels,
            ),
          ),
          onDidReceiveNotificationResponse: _onSelectNotificationHandler,
        );
      } catch (e) {
        throw NotixInitializationException(
            'Error initializing notifications: $e');
      }

      final lunchNots = await _plugin.getNotificationAppLaunchDetails();
      if (lunchNots != null &&
          lunchNots.didNotificationLaunchApp &&
          lunchNots.notificationResponse != null) {
        _onSelectNotificationHandler(lunchNots.notificationResponse!);
      }
    }
    _isInitialized = true;
    FirebaseMessaging.onMessage.listen(_recievedNotificationHandler);
    if (configs.onTokenRefresh != null) {
      _messaging.onTokenRefresh.listen(configs.onTokenRefresh);
    }
    NotixLog.d('Notix has been initialized');
  }

  static Future<bool> _requestNotificationPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: _channels._hasBadge,
      sound: _channels._hasSound,
    );
    NotixLog.d(
      'Notification permission status: ${settings.authorizationStatus.name}',
      isError: settings.authorizationStatus == AuthorizationStatus.denied,
    );
    return (settings.authorizationStatus == AuthorizationStatus.authorized);
  }

  /// Checks whether the app has notification permissions granted.
  ///
  /// Use this method to determine if the app currently has permission to display
  /// notifications. It returns `true` if notification permissions are granted,
  /// and `false` otherwise.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// bool hasPermission = await Notix.checktNotificationsPermission();
  /// if (hasPermission) {
  ///   // App has notification permissions
  /// } else {
  ///   // App does not have notification permissions
  /// }
  /// ```
  ///
  /// See also: [_requestNotificationPermission], [init]
  static Future<bool> checkNotificationsPermission() async {
    var settings = await _messaging.getNotificationSettings();
    NotixLog.d(
        'Notification permission status: ${settings.authorizationStatus.name}');
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  static void _recievedNotificationHandler(RemoteMessage message) async {
    NotixLog.d('Recieved notification: ${message.data}');
    final NotixMessage not;
    try {
      not = NotixMessage.fromMap(json.decode(message.data['content'] ?? '{}'));
    } catch (e) {
      throw NotixParsingException(
          'Error parsing notification: $e. Please make sure that you are using the latest version of Notix.');
    }
    if (configs.canShowNotification == null ||
        (configs.canShowNotification?.call(not) ?? false)) {
      await showNotification(not);
    }
    _eventController?.add(NotixEvent(
      type: EventType.receiveNotification,
      notification: not,
    ));
  }

  /// Returns the default FCM token for this device.
  ///
  /// On web, a [vapidKey] is required.
  static Future<String?> getToken({
    String? vapidKey,
  }) async {
    final token = await _messaging.getToken(vapidKey: vapidKey);
    NotixLog.d('FCM Token: $token');
    return token;
  }

  /// Fires when a new FCM token is generated.
  static Stream<String> get onTokenRefresh {
    return _messaging.onTokenRefresh.map((event) {
      NotixLog.d('Refreshed FCM token: $event');
      return event;
    });
  }

  static Future<dynamic> _onSelectNotificationHandler(
      NotificationResponse res) async {
    NotixLog.d('Selected notification: ${json.decode(res.payload ?? '{}')}');
    if (configs.onSelectNotification == null) return;
    NotixMessage not = NotixMessage.fromMap(json.decode(res.payload ?? '{}'));
    configs.onSelectNotification?.call(not);
    _eventController?.add(NotixEvent(
      type: EventType.notificationTap,
      notification: not,
    ));
  }

  /// Shows a notification with the specified parameters.
  /// Use this method to show a notification with the specified parameters locally on the current device.
  /// Usually, this method is used for the testing purposes.
  ///
  /// Example usage:
  /// ```dart
  /// Notix.showNotification(
  ///   NotixModel(
  ///     title: 'title',
  ///     body: 'body',
  ///     clientNotificationIds: ['the client notification id'],
  ///     channel: 'channel',
  ///     imageUrl: 'your image url',
  ///   ),
  /// );
  /// ```
  ///
  /// See also: [cancel], [push], [init]
  static showNotification(NotixMessage notification) async {
    NotixLog.d('Showing notification: ${notification.toMap}');
    try {
      configs.onRecievedNotification?.call(notification);
      final channel = _configs.channels.firstWhere(
        (e) => e.id == notification.channel,
        orElse: () => configs.defaultChannel,
      );

      final androidPlatformChannelSpecifics = AndroidNotificationDetails(
        channel.id,
        channel.name,
        groupKey: channel.groupId,
        channelDescription: channel.description,
        icon: _configs.icon,
        importance:
            (notification.importance ?? channel.importance).toImportance(),
        enableLights: channel.enableLights ?? false,
        channelShowBadge: channel.showBadge ?? true,
        ledColor: channel.ledColor,
        enableVibration: channel.enableVibration ?? true,
        playSound: notification.playSound ?? channel.playSound ?? true,
        sound: channel.sound == null
            ? null
            : RawResourceAndroidNotificationSound(
                channel.sound!.split('.').first),
      );

      final iosNotificationDetails = DarwinNotificationDetails(
        threadIdentifier: channel.groupId,
        presentSound: notification.playSound ?? channel.playSound,
        sound: channel.sound,
        categoryIdentifier: channel.id,
        presentBadge: channel.showBadge,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iosNotificationDetails,
      );
      if (notification.scheduleTime != null) {
        final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
            _plugin.resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        final bool? grantedNotificationPermission =
            await androidImplementation?.canScheduleExactNotifications();
        if (grantedNotificationPermission == false) {
          throw NotixPermissionException(
              'You must grant notification permissions to schedule notifications.');
        }
        NotixLog.d(
            'Scheduling notification for id ${notification.notificationId} at ${notification.scheduleTime?.sendAt} by time zone ${notification.scheduleTime?.timeZone}');
        final String currentTimeZone = notification.scheduleTime?.timeZone ??
            await FlutterTimezone.getLocalTimezone();
        await _plugin.zonedSchedule(
            notification.notificationId,
            notification.title,
            notification.body,
            tz.TZDateTime.from(notification.scheduleTime!.sendAt,
                tz.getLocation(currentTimeZone)),
            platformChannelSpecifics,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime);
      } else {
        await _plugin.show(
          notification.notificationId,
          notification.title,
          notification.body,
          platformChannelSpecifics,
          payload: json.encode(notification.toMap),
        );
        _eventController?.add(NotixEvent(
          type: EventType.notificationAdd,
          notification: notification,
        ));
      }
    } catch (e) {
      NotixLog.d('Error showing notification: $e', isError: true);
    }
    NotixLog.d(
        'Notification shown successfully for id ${notification.notificationId}');
  }

  static _checkInitialized() {
    if (!_isInitialized) {
      throw NotixInitializationException(
          'Notix is not initialized. You must call Notix.init() first.');
    }
  }

  /// Cancels all displayed notifications.
  ///
  /// Use this method to cancel and remove all currently displayed notifications
  /// from the notification tray. This action clears all active notifications
  /// regardless of their origin.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// await Notix.cancelAll();
  /// ```
  ///
  /// See also: [cancel], [push], [init]
  static Future<void> cancelAll() async {
    _checkInitialized();
    await _plugin.cancelAll();
    NotixLog.d('All notifications canceled');
  }

  /// Cancels a specific notification by its [notificationId].
  ///
  /// Use this method to cancel and remove a specific notification from the
  /// notification tray by providing its unique [notificationId]. This allows
  /// you to remove individual notifications based on their identifiers.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// int notificationId = 123; // Replace with the desired notification ID
  /// await Notix.cancel(notificationId);
  /// ```
  ///
  /// See also: [cancelAll], [push], [init]
  static Future<void> cancel(int notificationId) async {
    _checkInitialized();
    await _plugin.cancel(notificationId);
    NotixLog.d('Notification canceled for id $notificationId');
  }

  /// Subscribes the app to a specific topic for receiving notifications.
  ///
  /// Use this method to subscribe the app to a specific topic, allowing it to
  /// receive notifications related to that topic. Notifications sent to the
  /// subscribed topic will be delivered to the app.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// String topic = 'my_topic'; // Replace with the desired topic name
  /// await Notix.subscibeToTopic(topic);
  /// ```
  ///
  /// See also: [unsubscribeFromTopic], [push], [init]
  static Future<void> subscibeToTopic(String topic) async {
    _checkInitialized();
    await _messaging.subscribeToTopic(topic);
    _topics.add(topic);
    NotixLog.d('Subscribed to topic $topic');
  }

  /// Unsubscribes the app from a specific topic to stop receiving notifications.
  ///
  /// Use this method to unsubscribe the app from a specific topic, preventing
  /// it from receiving notifications related to that topic. Notifications sent
  /// to the unsubscribed topic will no longer be delivered to the app.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// String topic = 'my_topic'; // Replace with the desired topic name
  /// await Notix.unsubscribeFromTopic(topic);
  /// ```
  ///
  /// See also: [subscibeToTopic], [push], [init]
  static Future<void> unsubscribeFromTopic(String topic) async {
    _checkInitialized();
    await _messaging.unsubscribeFromTopic(topic);
    NotixLog.d('Unsubscribed from topic $topic');
  }

  /// Unsubscribes the app from all topics to stop receiving notifications.
  /// Use this method to unsubscribe the app from all topics, preventing it from
  /// receiving notifications related to any topic. Notifications sent to any
  /// unsubscribed topic will no longer be delivered to the app.
  /// Example usage:
  /// ```dart
  /// await Notix.unsubscribeFromAll();
  /// ```
  ///
  /// See also: [subscibeToTopic], [push], [init]
  static Future<void> unsubscribeFromAll() async {
    _checkInitialized();
    for (final topic in _topics) {
      await unsubscribeFromTopic(topic);
    }
    _topics.clear();
    NotixLog.d('Unsubscribed from all topics');
  }

  /// Sends a notification to the specified recipient.
  ///
  /// Use this method to send a notification to a specific recipient identified
  /// by [notification.clientNotificationIds]. The method will attempt to send
  /// the notification multiple times with retries if necessary.
  ///
  /// The notification will be sent to all the client devices of the user.
  ///
  /// If the notification is sent successfully, the [EventType.notificationAdd] event will be fired.
  ///
  /// The maximum number of retries is determined by the [configs.maxRetries] value.
  ///
  /// If the maximum number of retries is reached and the notification cannot
  /// be sent, an error will be logged.
  ///
  /// Throws an [NotixSendingException] if there are issues with the HTTP request or other errors occur.
  ///
  /// Example usage:
  ///
  /// ```dart
  /// Notix.push(
  ///   NotixModel(
  ///    title: 'title',
  ///    body: 'body',
  ///    clientNotificationId: ['the client notification id or topic'],
  ///    targetedUserId: 'the user id',
  ///    channel: 'channel',
  ///    type: NotixType.topic,
  ///    imageUrl: 'your image url',
  ///  ),
  /// );
  /// ```
  static Future<void> push(NotixMessage notification,
      {bool addToHistory = true}) async {
    _checkInitialized();
    NotixLog.d('Sending notification: ${notification.toMap}');
    if (notification.clientNotificationIds.isEmpty &&
        notification.topic == null) {
      throw NotixSendingException(
          'Client notification id is required for sending notifications.');
    }
    final res = await Future.wait(
        notification.clientNotificationIds.map((e) => _push(notification, e)));
    if (res.any((e) => e != null)) {
      NotixLog.d(
          '${res.where((e) => e == null).length} Notifications sent successfully. ${res.where((e) => e != null).length} has been failed for id ${notification.notificationId}',
          isError: true);
    } else {
      NotixLog.d(
          '${notification.clientNotificationIds.length} Notifications sent successfully for id ${notification.notificationId}');
    }

    _eventController?.add(NotixEvent(
      type: EventType.notificationAdd,
      notification: notification,
    ));
    if (addToHistory) await configs.datasourceConfig.save(notification);
  }

  static Future<String?> _push(
      NotixMessage notification, String clientNotificationId) async {
    const retryDelay = Duration(seconds: 5);
    for (int i = 0; i < _configs.maxRetries; i++) {
      if (i == _configs.maxRetries) {
        NotixLog.d(
            'Error sending notification for id ${notification.notificationId}',
            isError: true);
        break;
      }
      try {
        await _sendHttpRequest(notification, clientNotificationId);
        return null;
      } catch (e) {
        NotixLog.d('Error sending notification: $e', isError: true);
        await Future.delayed(retryDelay);
      }
    }
    return null;
  }

  static Future<void> _sendHttpRequest(
      NotixMessage notification, String clientNotificationId) async {
    String to = clientNotificationId;
    if (notification.topic != null) {
      to = '/topics/$clientNotificationId';
    }
    try {
      await dio.post(
        'https://fcm.googleapis.com/fcm/send',
        options: Options(
          headers: <String, String>{
            'Content-Type': 'application/json',
            'Authorization': 'key=${_configs.firebaseMessagingKey}'
          },
        ),
        data: json.encode({
          'to': to,
          "notification": {
            "title": notification.title,
            "body": notification.body,
          },
          "data": {
            "content": notification.toMap,
          }
        }),
      );
    } on DioException catch (e) {
      switch (e.type) {
        case DioExceptionType.connectionError:
          throw NotixSendingException('Connection error: ${e.message}');
        case DioExceptionType.connectionTimeout:
          throw NotixSendingException('Connection timeout: ${e.message}');
        case DioExceptionType.sendTimeout:
          throw NotixSendingException('Send timeout: ${e.message}');
        case DioExceptionType.receiveTimeout:
          throw NotixSendingException('Receive timeout: ${e.message}');
        case DioExceptionType.unknown:
          throw NotixSendingException('Unknown error: ${e.message}');
        default:
          throw NotixSendingException(
              'Error sending notification: ${e.message}');
      }
    } catch (e) {
      throw NotixSendingException('Error sending notification: $e');
    }
  }

  /// Retrieves a notification from Firestore by its unique identifier.
  ///
  /// Parameters:
  ///
  /// - `id`: The unique identifier of the notification to retrieve.
  ///
  /// Returns:
  ///
  /// A [Future] that resolves to the retrieved [NotixMessage] object.
  static Future<NotixMessage?> getNotificationById(String id) =>
      configs.datasourceConfig.get(id);

  /// Deletes a notification from Firestore.
  ///
  /// Parameters:
  ///
  /// - `notificationId`: The unique identifier of the notification to delete.
  ///
  /// Returns:
  ///
  /// A [Future] that completes when the notification is successfully deleted.
  static Future<void> deleteNotificationById(String notificationId) async =>
      await configs.datasourceConfig.delete(notificationId);

  /// Saves a notification to Firestore.
  ///
  /// Parameters:
  ///
  /// - `model`: The [NotixMessage] object to save in Firestore.
  ///
  /// Returns:
  ///
  /// A [Future] that completes when the notification is successfully saved.
  static Future<void> saveNotificationToFirestore(NotixMessage model) async =>
      await configs.datasourceConfig.save(model);

  /// Marks a notification as seen in Firestore.
  ///
  /// Parameters:
  ///
  /// - `notificationId`: The unique identifier of the notification to mark as seen.
  ///
  /// Returns:
  ///
  /// A [Future] that completes when the notification is successfully marked as seen.
  static Future<void> markAsSeen(String notificationId) async =>
      await configs.datasourceConfig.markAsSeen(notificationId);

  /// Marks all unseen notifications for the current user as seen.
  ///
  /// This method queries Firestore for all unseen notifications associated with
  /// the current user and marks them as seen.
  ///
  /// Firestore Indexes:
  /// To ensure efficient Firestore queries and operations, you need to set up
  /// appropriate Firestore indexes. You can do this by adding the following indexes
  /// in the Firebase console:
  ///
  /// Collection: your_collection_path (by default: notix)
  ///  Fields:
  ///   - targetedUserId (Ascending)
  ///   - isSeen (Ascending)
  ///
  /// Returns:
  ///
  /// A [Future] that completes when all unseen notifications are successfully marked as seen.
  ///
  /// Parameters:
  ///
  /// - `userId`: The user ID to mark all the associated unseen notifications as seen.
  /// If no user ID is provided, the current user ID will be tried to be retrieved from
  /// the [Notix.configs].
  ///
  static Future<void> markAllAsSeen([String? userId]) async =>
      await configs.datasourceConfig.markAllAsSeen(userId);

  /// Returns a Firestore query for fetching notifications.
  ///
  /// The query is configured to filter notifications for the current user and order them
  /// by creation date in descending order.
  ///
  /// Firestore Indexes:
  /// To ensure efficient Firestore queries and operations, you need to set up
  /// appropriate Firestore indexes. You can do this by adding the following indexes
  /// in the Firebase console:
  ///
  /// Collection: your_collection_path (by default: notix)
  ///   Fields:
  ///   - targetedUserId (Ascending)
  ///   - createdAt (Descending)
  ///
  /// Parameters:
  ///
  /// - `userId`: The user ID to mark all the associated unseen notifications as seen.
  /// If no user ID is provided, the current user ID will be tried to be retrieved from
  /// the [Notix.configs].
  ///
  /// Usage example:
  ///
  /// ```dart
  /// final query = Notix.query;
  /// final notifications = await query.get();
  /// ```
  static Query<NotixMessage> firebaseQuery([String? userId]) =>
      configs.datasourceConfig.query(userId);

  /// Returns a [Stream] that provides the count of unseen notifications.
  ///
  /// The stream emits the count whenever there are changes to the unseen notifications
  /// in Firestore.
  ///
  /// Usage example:
  ///
  /// ```dart
  /// final unseenCountStream = Notix.unseenCountStream;
  /// unseenCountStream.listen((count) {
  ///   print('Unseen notification count: $count');
  /// });
  /// ```
  static Stream<int> get unseenCountStream =>
      configs.datasourceConfig.unseenCountStream;

  /// use this method to check if all indexes are created in firestore. If not,
  /// it will throw an error with a link to create the index.
  static testQuries() {
    configs.datasourceConfig.testQuries();
  }

  /// Disposes the Notix package.
  /// Use this method to dispose the Notix package and release all resources.
  /// This method should be called when the app is no longer using the Notix package.
  ///
  /// Example usage:
  /// ```dart
  /// Notix.dispose();
  /// ```
  ///
  /// See also: [init]
  static void dispose() {
    unsubscribeFromAll();
    _eventController?.close();
    _configs = NotixConfig.defaults();
    _isInitialized = false;
  }
}
