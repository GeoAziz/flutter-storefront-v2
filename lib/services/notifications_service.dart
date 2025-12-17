/// Notifications service interface + stub (console sink)
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class NotificationsService {
  Future<void> sendNotification(String target, Map<String, dynamic> payload);
}

class ConsoleNotificationsService implements NotificationsService {
  final FirebaseFirestore firestore;

  ConsoleNotificationsService({FirebaseFirestore? firestore})
      : firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> sendNotification(
      String target, Map<String, dynamic> payload) async {
    // Console sink
    print('EMITTED NOTIFICATION -> target: $target payload: $payload');
    try {
      await firestore.collection('notifications_log').add({
        'target': target,
        'payload': payload,
        'ts': DateTime.now(),
      });
    } catch (e) {
      // best-effort in Spark-plan safe environment
      print('Failed to persist notification log: $e');
    }
  }
}
