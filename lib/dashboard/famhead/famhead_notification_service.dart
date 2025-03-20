import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// A service class for managing notifications related to family head actions
/// This service will send notifications to admins when family heads perform various actions
class FamilyHeadNotificationService {
  final SupabaseClient supabase;

  FamilyHeadNotificationService({required this.supabase});

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
      debugPrint('Error fetching admin users: $e');
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
        debugPrint('No admin users found to notify');
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

      debugPrint('Admin notification created successfully');
    } catch (e) {
      debugPrint('Error creating admin notification: $e');
    }
  }

  /// Notifies admins when a family member is added
  Future<void> notifyFamilyMemberAdded(
      String userId, String familyHeadName, String memberName) async {
    await _notifyAdmins(
      senderId: userId,
      title: 'New Family Member Added',
      message: '$familyHeadName has added a new family member: $memberName',
      notificationType: 'family_update',
      relatedId: userId,
    );
  }

  /// Notifies admins when a family member is edited
  Future<void> notifyFamilyMemberEdited(
      String userId, String familyHeadName, String memberName) async {
    await _notifyAdmins(
      senderId: userId,
      title: 'Family Member Updated',
      message: '$familyHeadName has updated family member: $memberName',
      notificationType: 'family_update',
      relatedId: userId,
    );
  }

  /// Notifies admins when a family member is deleted
  Future<void> notifyFamilyMemberDeleted(
      String userId, String familyHeadName, String memberName) async {
    await _notifyAdmins(
      senderId: userId,
      title: 'Family Member Deleted',
      message: '$familyHeadName has deleted family member: $memberName',
      notificationType: 'family_update',
      relatedId: userId,
    );
  }

  /// Notifies admins when a meal plan is generated
  Future<void> notifyMealPlanGenerated(
      String userId, String familyHeadName) async {
    await _notifyAdmins(
      senderId: userId,
      title: 'Meal Plan Generated',
      message: '$familyHeadName has generated a new 7-day meal plan',
      notificationType: 'meal_plan_generation',
      relatedId: userId,
    );
  }

  /// Notifies admins when a meal is regenerated
  Future<void> notifyMealRegenerated(
      String userId, String familyHeadName, String mealName, int day) async {
    await _notifyAdmins(
      senderId: userId,
      title: 'Meal Regenerated',
      message:
          '$familyHeadName has regenerated a meal (${mealName}) for Day $day',
      notificationType: 'meal_plan_generation',
      relatedId: userId,
    );
  }

  /// Notifies admins when a meal is completed
  Future<void> notifyMealCompleted(
      String userId, String familyHeadName, String mealName, int day) async {
    await _notifyAdmins(
      senderId: userId,
      title: 'Meal Completed',
      message:
          '$familyHeadName has completed a meal (${mealName}) for Day $day',
      notificationType: 'meal_completion',
      relatedId: userId,
    );
  }

  /// Notifies admins when the weekly meal plan is completed
  Future<void> notifyWeeklyMealPlanCompleted(
      String userId, String familyHeadName) async {
    await _notifyAdmins(
      senderId: userId,
      title: 'Weekly Meal Plan Completed',
      message: '$familyHeadName has completed the entire 7-day meal plan',
      notificationType: 'meal_completion',
      relatedId: userId,
    );
  }
}
