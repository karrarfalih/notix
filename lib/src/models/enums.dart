import 'package:flutter_local_notifications/flutter_local_notifications.dart';

enum NotixImportance { low, min, defaultImportance, high, max }

extension ToImportance on NotixImportance? {
  toImportance() {
    switch (this) {
      case NotixImportance.low:
        return Importance.low;
      case NotixImportance.min:
        return Importance.min;
      case NotixImportance.high:
        return Importance.high;
      case NotixImportance.max:
        return Importance.max;
      default:
        return Importance.defaultImportance;
    }
  }
}
