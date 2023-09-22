import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notix/src/core/notix.dart';
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
///   - userId (Ascending)
///   - createdAt (Descending)
///
/// 2- for marking notifications as seen:
///  Fields:
///   - userId (Ascending)
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
  NotixFirestore({this.collectionPath = 'Notix'});

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
  Future<NotixMessage> get(String id) async {
    final snapshot = await _reference.doc(id).get();
    return snapshot.data()!;
  }

  /// Deletes a notification from Firestore.
  ///
  /// Parameters:
  ///
  /// - `model`: The [NotixMessage] object to delete from Firestore.
  ///
  /// Returns:
  ///
  /// A [Future] that completes when the notification is successfully deleted.
  Future<void> delete(NotixMessage model) async {
    await _reference.doc(model.id).delete();
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
  Future<void> save(NotixMessage model) {
    return _reference.doc(model.id).set(model, SetOptions(merge: true));
  }

  /// Marks a notification as seen in Firestore.
  ///
  /// Parameters:
  ///
  /// - `model`: The [NotixMessage] object to mark as seen.
  ///
  /// Returns:
  ///
  /// A [Future] that completes when the notification is successfully marked as seen.
  Future<void> markAsSeen(NotixMessage model) {
    return save(model.copyWith(isSeen: true));
  }

  /// Marks all unseen notifications for the current user as seen.
  ///
  /// This method queries Firestore for all unseen notifications associated with
  /// the current user and marks them as seen.
  ///
  /// Returns:
  ///
  /// A [Future] that completes when all unseen notifications are successfully marked as seen.
  Future<void> markAllAsSeen() async {
    final userId = Notix.configs.currentUser?.call();
    if (userId == null) {
      NotixLog.d('No user ID found');
    }
    final snapshot = await _reference
        .where('userId', isEqualTo: userId)
        .where('isSeen', isEqualTo: false)
        .get();
    final models = snapshot.docs.map((e) => e.data()).toList();
    for (final model in models) {
      await markAsSeen(model);
    }
  }

  /// Returns a Firestore query for fetching notifications.
  ///
  /// The query is configured to filter notifications for the current user and order them
  /// by creation date in descending order.
  ///
  /// Usage example:
  ///
  /// ```dart
  /// final query = firestoreConfig.query;
  /// final notifications = await query.get();
  /// ```
  Query<NotixMessage> get query => _reference
      .where('userId', isEqualTo: Notix.configs.currentUser?.call())
      .orderBy('createdAt', descending: true);

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
      .map((snapshot) => snapshot.docs.length);
}
