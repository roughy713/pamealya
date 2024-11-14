import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> generateMealPlan(
    BuildContext context, String familyHeadName) async {
  try {
    // Fetch all meals from the database
    final response = await Supabase.instance.client
        .from('meal')
        .select()
        .then((data) => data as List<dynamic>);

    if (response.isEmpty) {
      throw 'Error fetching meals or no meals found.';
    }

    // Separate meals by category (1 = Breakfast, 2 = Lunch, 3 = Dinner)
    List<Map<String, dynamic>> breakfasts = response
        .where((meal) => meal['meal_category_id'] == 1)
        .cast<Map<String, dynamic>>()
        .toList();
    List<Map<String, dynamic>> lunches = response
        .where((meal) => meal['meal_category_id'] == 2)
        .cast<Map<String, dynamic>>()
        .toList();
    List<Map<String, dynamic>> dinners = response
        .where((meal) => meal['meal_category_id'] == 3)
        .cast<Map<String, dynamic>>()
        .toList();

    // Ensure there are at least 7 unique meals in each category
    if (breakfasts.length < 7 || lunches.length < 7 || dinners.length < 7) {
      throw 'Not enough unique meals in each category to generate a meal plan without repetition.';
    }

    // Shuffle and select 7 unique meals from each category
    breakfasts.shuffle();
    lunches.shuffle();
    dinners.shuffle();

    List<List<Map<String, dynamic>>> newMealPlan = List.generate(
        7,
        (index) => [
              breakfasts[index],
              lunches[index],
              dinners[index],
            ]);

    // Save each day's meals to the database
    for (int day = 0; day < newMealPlan.length; day++) {
      final dailyMeals = newMealPlan[day];
      await _saveMealToDatabase(
          day + 1, 'breakfast', dailyMeals[0], familyHeadName);
      await _saveMealToDatabase(
          day + 1, 'lunch', dailyMeals[1], familyHeadName);
      await _saveMealToDatabase(
          day + 1, 'dinner', dailyMeals[2], familyHeadName);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Meal plan generated and saved successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error generating meal plan: ${e.toString()}')),
    );
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
    print('Error saving meal to database: $e');
  }
}
