# NotiX

Effortlessly manage and customize notifications on Android and iOS in your Flutter app with NotiX.

## Table of Contents

- [Installation](#installation)
- [Getting Started](#getting-started)
  - [Initialize NotiX](#1-initialize-notix)
  - [Send Notifications](#2-send-notifications)
  - [Receive and Handle Notifications](#3-receive-and-handle-notifications)
- [Advanced Usage](#advanced-usage)
  - [Notification Channels](#notification-channels)
  - [Firebase Integration](#firebase-integration)


## Installation

Add the following line to your `pubspec.yaml` file:

```yaml
dependencies:
  notix: ^x.y.z
```
Replace x.y.z with the latest version of NotiX from pub.dev.

# Getting Started
## 1. Initialize NotiX
Initialize NotiX with your configuration, such as Firebase Cloud Messaging (FCM) settings and notification channels. This step is essential before using NotiX in your app.

```dart
import 'package:notix/notix.dart';

void main() async {
  await NotiX.init(
    configs: NotifyConfig(
      firebaseMessagingKey: 'YOUR_FCM_API_KEY',
      icon: 'notification_icon',
      // Add more configuration options here
    ),
  );
}
```

## 2. Send Notifications
Send notifications to your app users with ease. You can customize the content, channel, and behavior of each notification.

```dart
import 'package:notix/notix.dart';

void sendNotification() {
  NotifyMessage notification = NotifyMessage(
    title: 'New Message',
    body: 'You have a new message.',
    clientNotificationId: 'unique_id',
    // Add more notification details here
  );

  NotiX.push(notification);
}
```

## 3. Receive and Handle Notifications
Handle incoming notifications and customize the behavior when a user interacts with them. You can listen to various notification events and take actions accordingly.

```dart
import 'package:notix/notix.dart';

void main() {
  NotiX.eventsStream.listen((event) {
    if (event.type == EventType.notificationTap) {
      // Handle notification tap event
    } else if (event.type == EventType.receiveNotification) {
      // Handle received notification
    }
  });
}
```

# Advanced Usage
## Notification Channels
NotiX supports the creation and management of notification channels on Android. You can define channels with different behaviors, such as sound, vibration, or LED colors.

```dart
NotifyChannel channel = NotifyChannel(
  id: 'channel_id',
  name: 'Channel Name',
  description: 'Channel Description',
  playSound: true,
  showBadge: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Colors.blue,
  sound: 'custom_sound.mp3',
  importance: Importance.high,
);

// Add the channel to the configuration
NotifyConfig configs = NotifyConfig(
  channels: [channel],
  // ...
);
```
## Firebase Integration
NotiX seamlessly integrates with Firebase for cloud messaging. You can utilize Firebase services for better notification delivery and management.

```dart
// Initialize Firebase in your app
await Firebase.initializeApp();

// Initialize NotiX with Firebase Cloud Messaging settings
await NotiX.init(
  configs: NotifyConfig(
    firebaseMessagingKey: 'YOUR_FCM_API_KEY',
    // ...
  ),
);
```