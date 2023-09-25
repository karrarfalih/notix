class NotixException implements Exception {
  /// A descriptive message explaining the cause of the exception.
  final String message;

  /// Creates a [NotixException] with the provided error [message].
  NotixException(this.message);

  @override
  String toString() {
    return 'NotixException: $message';
  }
}

/// Exception thrown when an error occurs during the initialization of a Notix channel.
///
/// The [NotixChannelException] class is used to represent errors that
/// occur during the setup and initialization of Notix channels. It includes a
/// descriptive [message] to provide more information about the specific error.
class NotixChannelException extends NotixException {
  /// Creates an [NotixChannelException] with the provided error [message].
  NotixChannelException(super.message);
}

/// Exception thrown when an error occurs during the general initialization of Notix.
///
/// The [NotixInitializationException] class is used to represent errors that occur
/// during the overall initialization of the Notix framework. It includes a
/// descriptive [message] to provide more information about the specific error.
class NotixInitializationException extends NotixException {
  /// Creates an [NotixInitializationException] with the provided error [message].
  NotixInitializationException(super.message);
}

/// Exception thrown when a permission-related error occurs within Notix.
///
/// The [NotixPermissionException] class is used to represent errors related to
/// permissions, such as notification permission denied. It includes a
/// descriptive [message] to provide more information about the specific error.
class NotixPermissionException extends NotixException {
  /// Creates a [NotixPermissionException] with the provided error [message].
  NotixPermissionException(super.message);
}

/// Exception thrown when an error occurs during the process of sending a notification.
///
/// The [NotixSendingException] class is used to represent errors that occur while
/// attempting to send a notification, such as network or server-related issues.
/// It includes a descriptive [message] to provide more information about the
/// specific error.
class NotixSendingException extends NotixException {
  /// Creates a [NotixSendingException] with the provided error [message].
  NotixSendingException(super.message);
}

/// Exception thrown when an error occurs during the process of parsing a notification.
/// The [NotixParsingException] class is used to represent errors that occur while
/// attempting to parse a notification, such as malformed JSON. It includes a
/// descriptive [message] to provide more information about the specific error.
/// This exception is only used internally and should never be seen by the user.
class NotixParsingException extends NotixException {
  /// Creates a [NotixParsingException] with the provided error [message].
  NotixParsingException(super.message);
}
