class ScheduleTime {
  final DateTime sendAt;
  final String? timeZone;

  ScheduleTime({
    required this.sendAt,
    this.timeZone,
  });

  ScheduleTime.fromMap(Map<String, dynamic> map)
      : sendAt = DateTime.parse(map['sendAt']),
        timeZone = map['timeZone'];

  Map<String, dynamic> get toMap => {
        'sendAt': sendAt.toIso8601String(),
        'timeZone': timeZone,
      }..removeWhere((key, value) => value == null);
}
