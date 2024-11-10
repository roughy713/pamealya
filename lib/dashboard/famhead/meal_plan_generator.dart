// lib/meal_plan_generator.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> generateMealPlan(BuildContext context) async {
  try {
    // Fetch all meals from the database
    final response = await Supabase.instance.client
        .from('meal')
        .select()
        .then((data) => data as List<dynamic>);

    if (response.isEmpty) {
      throw 'Error fetching meals or no meals found.';
    }

    // Separate meals by categories with correct column name
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

    // Debug: Print the count of each category
    print("Breakfasts count: ${breakfasts.length}");
    print("Lunches count: ${lunches.length}");
    print("Dinners count: ${dinners.length}");

    if (breakfasts.isEmpty || lunches.isEmpty || dinners.isEmpty) {
      throw 'Not enough meals in each category to generate a meal plan.';
    }

    // Random meal selection function
    List<Map<String, dynamic>> generateDailyMeals() {
      final random = Random();
      return [
        breakfasts[random.nextInt(breakfasts.length)],
        lunches[random.nextInt(lunches.length)],
        dinners[random.nextInt(dinners.length)],
      ];
    }

    // Generate meal plan for 7 days
    List<List<Map<String, dynamic>>> mealPlan =
        List.generate(7, (_) => generateDailyMeals());

    // Display success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Meal plan generated successfully!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error generating meal plan: $e')),
    );
  }
}
