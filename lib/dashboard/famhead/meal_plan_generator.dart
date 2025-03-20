import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'famhead_notification_service.dart';

Future<bool> generateMealPlan(
    BuildContext context, String familyHeadName) async {
  try {
    final supabase = Supabase.instance.client;

    final userId = supabase.auth.currentUser?.id;
    print('Debug - User ID: $userId');
    print('Debug - Family Head Name: $familyHeadName');

    if (userId == null) {
      throw 'User not authenticated';
    }

    // First verify the family head name from the familymember table
    final familyHeadCheck = await supabase
        .from('familymember')
        .select('family_head')
        .eq('user_id', userId)
        .eq('position', 'Family Head')
        .single();

    final verifiedFamilyHead = familyHeadCheck['family_head'] as String;

    // Delete any existing meal plans
    await supabase
        .from('mealplan')
        .delete()
        .eq('user_id', userId)
        .eq('family_head', verifiedFamilyHead);

    // Fetch meals
    final mealsResponse =
        await supabase.from('meal').select().not('recipe_id', 'is', null);

    if (mealsResponse.isEmpty) {
      throw 'No meals available in the database';
    }

    final meals = mealsResponse as List<dynamic>;

    // Group meals by category
    final breakfasts = meals.where((m) => m['meal_category_id'] == 1).toList();
    final lunches = meals.where((m) => m['meal_category_id'] == 2).toList();
    final dinners = meals.where((m) => m['meal_category_id'] == 3).toList();
    final snacks = meals.where((m) => m['meal_category_id'] == 4).toList();

    // Generate meal plan
    for (int day = 1; day <= 7; day++) {
      breakfasts.shuffle();
      lunches.shuffle();
      dinners.shuffle();
      snacks.shuffle();

      // Save each meal type
      for (var mealData in [
        {'category': 1, 'meal': breakfasts[0]},
        {'category': 2, 'meal': lunches[0]},
        {'category': 3, 'meal': dinners[0]},
        {'category': 4, 'meal': snacks[0]},
      ]) {
        final meal = mealData['meal'] as Map<String, dynamic>;

        final mealPlanData = {
          'day': day,
          'meal_category_id': mealData['category'],
          'recipe_id': meal['recipe_id'],
          'meal_name': meal['name'],
          'family_head': verifiedFamilyHead,
          'user_id': userId,
          'is_completed': false,
          'created_at': DateTime.now().toIso8601String(),
        };

        await supabase.from('mealplan').insert(mealPlanData).select();
      }
    }

    // Send only one notification for the complete weekly meal plan
    await supabase.rpc(
      'create_notification',
      params: {
        'p_recipient_id': userId,
        'p_sender_id': userId,
        'p_title': 'Weekly Meal Plan Generated',
        'p_message':
            'Your complete 7-day meal plan has been generated successfully!',
        'p_notification_type': 'meal_plan',
        'p_related_id': userId,
      },
    );

    // Send notification to admins
    final notificationService =
        FamilyHeadNotificationService(supabase: supabase);
    await notificationService.notifyMealPlanGenerated(
        userId, verifiedFamilyHead);

    print('Meal plan generation completed successfully');
    return true;
  } catch (e) {
    print('Error in meal plan generation: $e');
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    return false;
  }
}

Future<void> _saveMealToDatabase(
  int day,
  int mealCategoryId,
  Map<String, dynamic> meal,
  String familyHeadName,
  String userId,
) async {
  try {
    await Supabase.instance.client.from('mealplan').insert({
      'day': day,
      'meal_category_id': mealCategoryId,
      'recipe_id': meal['recipe_id'],
      'meal_name': meal['name'],
      'family_head': familyHeadName,
      'user_id': userId,
      'is_completed': false,
    });
  } catch (e) {
    print('Error saving meal to database: $e');
    rethrow;
  }
}
