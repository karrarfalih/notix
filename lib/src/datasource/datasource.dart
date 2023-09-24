import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notix/src/core/notix.dart';
import 'package:notix/src/datasource/disable_datasource.dart';
import 'package:notix/src/models/message.dart';
import 'package:notix/src/utils/log.dart';

/// The `NotixFirestore` class provides an integration layer for managing notifications
/// using Firestore as the data source.
///
/// You can use this class to interact with Firestore collections and perform various
/// operations such as fetching, saving, marking notifications as seen, and more.
///
/// Firestore Indexes:
/// To ensure efficient Firestore queries and operations, you need to set up
/// appropriate Firestore indexes. You can do this by adding the following indexes
/// in the Firebase console:
/// Collection: your_collection_path
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
/// Example usage:
///
/// ```dart
/// final firestoreConfig = NotixFirestore(collectionPath: 'your_custom_collection');
/// final notification = await firestoreConfig.get('notification_id');
///
/// // Mark a notification as seen
/// await firestoreConfig.markAsSeen(notification);
///
/// // Query notifications for the current user
/// final query = firestoreConfig.query;
/// final notifications = await query.get();
///
/// // Get the count of unseen notifications
/// final unseenCountStream = firestoreConfig.unseenCountStream;
/// ```
class NotixFirestore {
  /// The Firestore collection path where notifications are stored.
  final String collectionPath;

  /// Creates a new instance of `NotixFirestore` with an optional custom Firestore collection path.
  ///
  /// By default, the collection path is set to 'Notix'.
  ///
  /// Example:
  ///
  /// ```dart
  /// final firestoreConfig = NotixFirestore(collectionPath: 'custom_notifications');
  /// ```
  const NotixFirestore({this.collectionPath = 'notix'});

  /// A disabled data source in case you don't want to use Firestore.
  /// This data source is used by default if you don't configure Firestore.
  /// It throws an error when you try to perform any operation.
  /// You can use it as follows:
  /// ```dart
  /// final firestoreConfig = NotixFirestore.disabled;
  /// ```
  /// or
  /// ```dart
  /// final firestoreConfig = NotixDisabledDatasource();
  /// ```
  static NotixFirestore get disabled => const NotixDisabledDatasource();

  CollectionReference<NotixMessage> get _reference => FirebaseFirestore.instance
      .collection(collectionPath)
      .withConverter<NotixMessage>(
        fromFirestore: (snapshot, _) => NotixMessage.fromMap(snapshot.data()!),
        toFirestore: (model, _) => model.toMap,
      );

  /// Retrieves a notification from Firestore by its unique identifier.
  ///
  /// Parameters:
  ///
  /// - `id`: The unique identifier of the notification to retrieve.
  ///
  /// Returns:
  ///
  /// A [Future] that resolves to the retrieved [NotixMessage] object.
  Future<NotixMessage?> get(String id) async {
    try {
      final snapshot = await _reference.doc(id).get();
      return snapshot.data();
    } catch (e) {
      NotixLog.d('Error getting notification: $e', isError: true);
      return null;
    }
  }

  /// Deletes a notification from Firestore.
  ///
  /// Parameters:
  ///
  /// - `notificationId`: The unique identifier of the notification to delete.
  ///
  /// Returns:
  ///
  /// A [Future] that completes when the notification is successfully deleted.
  Future<void> delete(String notificationId) async {
    try {
      await _reference.doc(notificationId).delete();
    } catch (e) {
      NotixLog.d('Error deleting notification: $e', isError: true);
    }
  }

  /// Saves a notification to Firestore.
  ///
  /// Parameters:
  ///
  /// - `model`: The [NotixMessage] object to save in Firestore.
  ///
  /// Returns:
  ///
  /// A [Future] that completes when the notification is successfully saved.
  Future<void> save(NotixMessage model) async {
    try {
      await _reference.doc(model.id).set(model);
      NotixLog.d('Notification saved to: $collectionPath/${model.id}');
    } catch (e) {
      NotixLog.d('Error saving notification: $e', isError: true);
    }
  }

  /// Marks a notification as seen in Firestore.
  ///
  /// Parameters:
  ///
  /// - `notificationId`: The unique identifier of the notification to mark as seen.
  ///
  /// Returns:
  ///
  /// A [Future] that completes when the notification is successfully marked as seen.
  Future<void> markAsSeen(String notificationId) async {
    try {
      await _reference.doc(notificationId).update({'isSeen': true});
    } catch (e) {
      NotixLog.d('Error marking notification as seen: $e', isError: true);
    }
  }

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
  Future<void> markAllAsSeen([String? userId]) async {
    final targetedUserId = userId ?? Notix.configs.currentUserId?.call();
    if (userId == null) {
      NotixLog.d('No user ID found', isError: true);
    }
    final QuerySnapshot<NotixMessage> snapshot;
    try {
      snapshot = await _reference
          .where('targetedUserId', isEqualTo: targetedUserId)
          .where('isSeen', isEqualTo: false)
          .get();
    } catch (e) {
      NotixLog.d('Error getting unseen notifications: $e', isError: true);
      return;
    }
    final models = snapshot.docs.map((e) => e.data()).toList();
    for (final model in models) {
      await markAsSeen(model.id);
    }
  }

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
  /// final query = firestoreConfig.query;
  /// final notifications = await query.get();
  /// ```
  Query<NotixMessage> query([String? userId]) {
    final targetedUserId = userId ?? Notix.configs.currentUserId?.call();
    if (targetedUserId == null) {
      NotixLog.d('No user ID found', isError: true);
    }
    return _reference
        .where('targetedUserId', isEqualTo: targetedUserId)
        .orderBy('createdAt', descending: true);
  }

  /// Returns a [Stream] that provides the count of unseen notifications.
  ///
  /// The stream emits the count whenever there are changes to the unseen notifications
  /// in Firestore.
  ///
  /// Usage example:
  ///
  /// ```dart
  /// final unseenCountStream = firestoreConfig.unseenCountStream;
  /// unseenCountStream.listen((count) {
  ///   print('Unseen notification count: $count');
  /// });
  /// ```
  Stream<int> get unseenCountStream => _reference
      .where('isSeen', isEqualTo: false)
      .snapshots()
      .map((snapshot) => snapshot.docs.length)
      .handleError(
        (e) =>
            NotixLog.d('Error getting unseen notifications: $e', isError: true),
      );
}
