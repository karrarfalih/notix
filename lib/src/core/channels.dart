part of 'notix.dart';

class _ChannelsService {
  NotixChannel get _defaultChannel => Notix.configs.defaultChannel;
  List<NotixChannel> get _channels =>
      [_defaultChannel, ...Notix.configs.channels];
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
            playSound: channel.playSound ?? _defaultChannel.playSound ?? true,
            showBadge: channel.showBadge ?? _defaultChannel.showBadge ?? true,
            enableVibration: channel.enableVibration ??
                _defaultChannel.enableVibration ??
                true,
            enableLights:
                channel.enableLights ?? _defaultChannel.enableLights ?? false,
            ledColor: channel.ledColor ?? _defaultChannel.ledColor,
            sound: channel.sound == null && _defaultChannel.sound == null
                ? null
                : RawResourceAndroidNotificationSound(
                    (channel.sound ?? _defaultChannel.sound!).split('.').first),
            importance: (channel.importance ?? _defaultChannel.importance)
                .toImportance(),
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
