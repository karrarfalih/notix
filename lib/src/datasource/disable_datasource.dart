import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:notix/src/datasource/datasource.dart';
import 'package:notix/src/models/message.dart';
import 'package:notix/src/utils/log.dart';

class NotixDisabledDatasource extends NotixFirestore {
  const NotixDisabledDatasource();

  @override
  Future<NotixMessage?> get(String id) async {
    NotixLog.d('The Firestore data source is disabled', isError: true);
    return null;
  }

  @override
  Future<void> delete(String notificationId) async {
    NotixLog.d('The Firestore data source is disabled', isError: true);
  }

  @override
  Future<void> save(NotixMessage model) async {
    NotixLog.d('The Firestore data source is disabled', isError: true);
  }

  @override
    Future<void> markAsSeen(String notificationId)async{
    NotixLog.d('The Firestore data source is disabled', isError: true);
  }

  @override
    Future<void> markAllAsSeen([String? userId]) async {
    NotixLog.d('The Firestore data source is disabled', isError: true);
  }

  @override
  Query<NotixMessage> query([String? userId]) => throw UnimplementedError('The Firestore data source is disabled');

  @override
  Stream<int> get unseenCountStream => throw UnimplementedError('The Firestore data source is disabled');
}
