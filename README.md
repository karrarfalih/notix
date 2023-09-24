# Notix

Effortlessly manage and customize notifications on Android and iOS in your Flutter app with Notix.

## Table of Contents

- [Installation](#installation)
- [Getting Started](#getting-started)
  - [Initialize Notix](#1-initialize-Notix)
  - [Send Notifications](#2-send-notifications)
  - [Receive and Handle Notifications](#3-receive-and-handle-notifications)
- [Advanced Usage](#advanced-usage)
  - [Notification Channels](#notification-channels)
  - [Firebase Integration](#firebase-integration)


## Installation

Add the following line to your `pubspec.yaml` file:

```yaml
dependencies:
  Notix: ^x.y.z
```
Replace x.y.z with the latest version of Notix from pub.dev.

# Getting Started
## 1. Initialize Notix
Initialize Notix with your configuration, such as Firebase Cloud Messaging (FCM) settings and notification channels. This step is essential before using Notix in your app.

```dart
import 'package:Notix/Notix.dart';

void main() async {
  await Notix.init(
    configs: NotixConfig(
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
import 'package:Notix/Notix.dart';

void sendNotification() {
  NotixMessage notification = NotixMessage(
    title: 'New Message',
    body: 'You have a new message.',
    clientNotificationId: 'unique_id',
    // Add more notification details here
  );

  Notix.push(notification);
}
```

## 3. Receive and Handle Notifications
Handle incoming notifications and customize the behavior when a user interacts with them. You can listen to various notification events and take actions accordingly.

```dart
import 'package:Notix/Notix.dart';

void main() {
  Notix.eventsStream.listen((event) {
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
Notix supports the creation and management of notification channels on Android. You can define channels with different behaviors, such as sound, vibration, or LED colors.

```dart
NotixChannel channel = NotixChannel(
  id: 'channel_id',
  name: 'Channel Name',
  description: 'Channel Description',
  playSound: true,
  showBadge: true,
  enableVibration: true,
  enableLights: true,
  ledColor: Colors.blue,
  sound: 'custom_sound.mp3',
  importance: NotixImportance.high,
);

// Add the channel to the configuration
NotixConfig configs = NotixConfig(
  channels: [channel],
  // ...
);
```
## Firebase Integration
Notix seamlessly integrates with Firebase for cloud messaging. You can utilize Firebase services for better notification delivery and management.

```dart
// Initialize Firebase in your app
await Firebase.initializeApp();

// Initialize Notix with Firebase Cloud Messaging settings
await Notix.init(
  configs: NotixConfig(
    firebaseMessagingKey: 'YOUR_FCM_API_KEY',
    // ...
  ),
);
```