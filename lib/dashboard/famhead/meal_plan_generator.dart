// lib/meal_plan_generator.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> generateMealPlan(
    BuildContext context, String familyHeadName) async {
  try {
    final response = await Supabase.instance.client
        .from('meal')
        .select()
        .then((data) => data as List<dynamic>);

    if (response.isEmpty) {
      throw 'Error fetching meals or no meals found.';
    }

    List<Map<String, dynamic>> allMeals = response.cast<Map<String, dynamic>>();
    List<Map<String, dynamic>> breakfasts = allMeals
        .where((meal) =>
            meal['meal_category_id'] == 1 || meal['meal_category_id'] == '1')
        .toList();
    List<Map<String, dynamic>> lunches = allMeals
        .where((meal) =>
            meal['meal_category_id'] == 2 || meal['meal_category_id'] == '2')
        .toList();
    List<Map<String, dynamic>> dinners = allMeals
        .where((meal) =>
            meal['meal_category_id'] == 3 || meal['meal_category_id'] == '3')
        .toList();

    if (breakfasts.isEmpty || lunches.isEmpty || dinners.isEmpty) {
      throw 'Not enough meals in each category to generate a meal plan.';
    }

    List<List<Map<String, dynamic>>> newMealPlan = List.generate(7, (_) {
      final random = Random();
      return [
        breakfasts[random.nextInt(breakfasts.length)],
        lunches[random.nextInt(lunches.length)],
        dinners[random.nextInt(dinners.length)],
      ];
    });

    for (int day = 0; day < newMealPlan.length; day++) {
      final dailyMeals = newMealPlan[day];
      await _saveMealToDatabase(
          day + 1, 'breakfast', dailyMeals[0], familyHeadName);
      await _saveMealToDatabase(
          day + 1, 'lunch', dailyMeals[1], familyHeadName);
      await _saveMealToDatabase(
          day + 1, 'dinner', dailyMeals[2], familyHeadName);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Meal plan generated and saved successfully!')),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating meal plan: ${e.toString()}')),
      );
    }
  }
}

Future<void> _saveMealToDatabase(int day, String mealType,
    Map<String, dynamic> meal, String familyHeadName) async {
  try {
    if (meal['recipe_id'] == null) {
      throw 'Meal ID is null for $mealType on Day $day: $meal';
    }

    await Supabase.instance.client.from('mealplan').insert({
      'day': day,
      'meal_type': mealType,
      'meal_id': meal['recipe_id'],
      'meal_name': meal['name'] ?? 'Unknown',
      'family_head': familyHeadName, // Add family head name here
    });
  } catch (e) {
    print('Error saving meal to database: $e'); // Log the error if needed
  }
}
