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
}
