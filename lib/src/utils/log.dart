import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:notix/src/core/notix.dart';

class NotixLog {
  static void d(String message, {bool isError = false}) {
    if (isError || (Notix.configs.enableLog && kDebugMode)) {
      log(
        message,
        name: 'Notix',
      );
    }
  }
}
