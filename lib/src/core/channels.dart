part of 'notix.dart';

class _ChannelsService {
  List<NotixChannel> get _channels =>
      [Notix.configs.defaultChannel, ...Notix.configs.channels];
  List<NotixGroupChannel> get _groupChannels => Notix.configs.groupChannels;

  bool get _hasSound => _channels.any((e) => e.playSound ?? false);
  bool get _hasBadge => _channels.any((e) => e.showBadge ?? false);

  List<DarwinNotificationCategory> get _iosChannels {
    return _channels
        .map((e) => DarwinNotificationCategory(
              e.id,
            ))
        .toList();
  }

  Future<void> init() async {
    try {
      for (final e in _groupChannels) {
        await _initGroupChannel(e);
      }
      for (final e in _channels) {
        await _initChannel(e);
      }
    } catch (e) {
      throw NotixChannelException('Error initializing channel: $e');
    }
    NotixLog.d('Channels added: ${_channels.map((e) => e.id).toList()}');
  }

  _initChannel(NotixChannel channel) async {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          AndroidNotificationChannel(
            channel.id,
            channel.name,
            groupId: channel.groupId,
            description: channel.description,
            playSound: channel.playSound!,
            showBadge: channel.showBadge!,
            enableVibration: channel.enableLights!,
            enableLights: channel.enableLights!,
            ledColor: channel.ledColor,
            sound: channel.sound == null
                ? null
                : RawResourceAndroidNotificationSound(
                    channel.sound!.split('.').first),
            importance: channel.importance!,
          ),
        );
  }

  _initGroupChannel(NotixGroupChannel channel) {
    final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannelGroup(
          AndroidNotificationChannelGroup(
            channel.id,
            channel.name,
            description: channel.description,
          ),
        );
  }
}
