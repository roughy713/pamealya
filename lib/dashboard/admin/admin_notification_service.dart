import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class AdminNotificationService {
  final SupabaseClient supabase;

  AdminNotificationService({required this.supabase});

  /// Finds all admin users in the system
  /// Returns a list of admin user IDs
  Future<List<String>> _getAdminUserIds() async {
    try {
      final response = await supabase.from('admin').select('user_id');

      if (response.isNotEmpty) {
        return List<String>.from(response.map((admin) => admin['user_id']));
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Creates a notification for all admin users
  /// This is a helper method used by the public notification methods
  Future<void> _notifyAdmins({
    required String senderId,
    required String title,
    required String message,
    required String notificationType,
    required String? relatedId,
  }) async {
    try {
      final adminIds = await _getAdminUserIds();
      if (adminIds.isEmpty) {
        return;
      }

      // Create notifications for each admin
      for (final adminId in adminIds) {
        // Ensure the notification is NOT the same admin who created it
        if (adminId != senderId) {
          await supabase.from('notifications').insert({
            'notification_id': const Uuid().v4(),
            'recipient_id': adminId,
            'sender_id': senderId,
            'title': title,
            'message': message,
            'notification_type': notificationType,
            'related_id': relatedId,
            'is_read': false,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          });
        }
      }
    } catch (e) {}
  }

  /// Notifies admin when a new cook registers
  Future<void> notifyCookRegistration(String cookId, String cookName) async {
    await _notifyAdmins(
      senderId: cookId,
      title: 'New Cook Registration',
      message: '$cookName has registered as a cook and is awaiting approval.',
      notificationType: 'cook_registration',
      relatedId: cookId,
    );
  }

  /// Notifies admin when a new family head registers
  Future<void> notifyFamilyHeadRegistration(
      String userId, String familyHeadName) async {
    await _notifyAdmins(
      senderId: userId,
      title: 'New Family Head Registration',
      message: '$familyHeadName has registered as a family head.',
      notificationType: 'family_head_registration',
      relatedId: userId,
    );
  }

  // ----- NEW ORDER NOTIFICATION METHODS -----

  /// Notifies admins when a cook accepts a booking request
  Future<void> notifyBookingAccepted(String cookId, String cookName,
      String familyHeadName, String mealName, String bookingId) async {
    await _notifyAdmins(
      senderId: cookId,
      title: 'Booking Accepted',
      message:
          '$cookName has accepted a booking request from $familyHeadName for $mealName.',
      notificationType: 'booking_status',
      relatedId: bookingId,
    );
  }

  /// Notifies admins when a cook declines a booking request
  Future<void> notifyBookingDeclined(String cookId, String cookName,
      String familyHeadName, String mealName, String bookingId) async {
    await _notifyAdmins(
      senderId: cookId,
      title: 'Booking Declined',
      message:
          '$cookName has declined a booking request from $familyHeadName for $mealName.',
      notificationType: 'booking_status',
      relatedId: bookingId,
    );
  }

  /// Notifies admins when a cook updates order status to preparing
  Future<void> notifyOrderPreparing(String cookId, String cookName,
      String familyHeadName, String mealName, String bookingId) async {
    await _notifyAdmins(
      senderId: cookId,
      title: 'Order Status: Preparing',
      message: '$cookName has started preparing $mealName for $familyHeadName.',
      notificationType: 'order_status',
      relatedId: bookingId,
    );
  }

  /// Notifies admins when a cook updates order status to on delivery
  Future<void> notifyOrderOnDelivery(String cookId, String cookName,
      String familyHeadName, String mealName, String bookingId) async {
    await _notifyAdmins(
      senderId: cookId,
      title: 'Order Status: On Delivery',
      message: '$cookName is delivering $mealName to $familyHeadName.',
      notificationType: 'order_status',
      relatedId: bookingId,
    );
  }

  /// Notifies admins when a cook updates order status to completed
  Future<void> notifyOrderCompleted(String cookId, String cookName,
      String familyHeadName, String mealName, String bookingId) async {
    await _notifyAdmins(
      senderId: cookId,
      title: 'Order Status: Completed',
      message:
          '$cookName has completed the order for $mealName to $familyHeadName.',
      notificationType: 'order_status',
      relatedId: bookingId,
    );
  }

  /// Notifies admins when a family head confirms receipt of an order
  Future<void> notifyOrderReceived(String familyHeadId, String familyHeadName,
      String cookName, String mealName, String bookingId) async {
    await _notifyAdmins(
      senderId: familyHeadId,
      title: 'Order Received',
      message:
          '$familyHeadName has confirmed receipt of $mealName from $cookName.',
      notificationType: 'order_received',
      relatedId: bookingId,
    );
  }
}
