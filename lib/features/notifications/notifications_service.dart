/// Simple notifications service stub for FCM/email integration

class NotificationsService {
  NotificationsService();

  /// Send push notification via FCM (server-side Cloud Function will call FCM)
  Future<void> sendOrderStatusPush(
      String userId, String orderId, String status) async {
    // TODO: implement Cloud Function + FCM integration
  }

  /// Send email receipt
  Future<void> sendOrderReceiptEmail(String userEmail, String orderId) async {
    // TODO: integrate with SendGrid/SES
  }
}
