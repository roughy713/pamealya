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

    // Cast response to List<Map<String, dynamic>> for type safety
    final meals = response.cast<Map<String, dynamic>>();

    // Fetch already assigned recipe IDs for the current family head
    final existingMealPlanResponse = await Supabase.instance.client
        .from('mealplan')
        .select('recipe_id')
        .eq('family_head', familyHeadName);

    final assignedRecipeIds = (existingMealPlanResponse as List<dynamic>?)
            ?.map((meal) => meal['recipe_id'])
            .toSet() ??
        {};

    // Separate meals by category, excluding already assigned meals
    List<Map<String, dynamic>> breakfasts = meals
        .where((meal) =>
            meal['recipe_id'] != null &&
            (meal['meal_category_id'] == 1 || // Breakfast
                meal['meal_category_id'] == 4 || // All
                meal['meal_category_id'] == 6) && // Breakfast & Lunch
            !assignedRecipeIds.contains(meal['recipe_id']))
        .toList();

    List<Map<String, dynamic>> lunches = meals
        .where((meal) =>
            meal['recipe_id'] != null &&
            (meal['meal_category_id'] == 2 || // Lunch
                meal['meal_category_id'] == 4 || // All
                meal['meal_category_id'] == 6 || // Breakfast & Lunch
                meal['meal_category_id'] == 7) && // Lunch & Dinner
            !assignedRecipeIds.contains(meal['recipe_id']))
        .toList();

    List<Map<String, dynamic>> dinners = meals
        .where((meal) =>
            meal['recipe_id'] != null &&
            (meal['meal_category_id'] == 3 || // Dinner
                meal['meal_category_id'] == 4 || // All
                meal['meal_category_id'] == 7) && // Lunch & Dinner
            !assignedRecipeIds.contains(meal['recipe_id']))
        .toList();

    // Validate that there are enough unique meals in each category
    if (breakfasts.length < 7) throw 'Not enough breakfast meals.';
    if (lunches.length < 7) throw 'Not enough lunch meals.';
    if (dinners.length < 7) throw 'Not enough dinner meals.';

    // Shuffle and select 7 meals from each category
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

    // Save meal plan to the database
    for (int day = 0; day < newMealPlan.length; day++) {
      final dailyMeals = newMealPlan[day];
      print(
          'Day ${day + 1} - Breakfast: ${dailyMeals[0]}, Lunch: ${dailyMeals[1]}, Dinner: ${dailyMeals[2]}');
      await _saveMealToDatabase(
          day + 1, 1, dailyMeals[0], familyHeadName); // Breakfast
      await _saveMealToDatabase(
          day + 1, 2, dailyMeals[1], familyHeadName); // Lunch
      await _saveMealToDatabase(
          day + 1, 3, dailyMeals[2], familyHeadName); // Dinner
    }

    // Show success dialog
    _showSuccessDialog(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error generating meal plan: ${e.toString()}')),
    );
  }
}

// Function to save meal to the database
Future<void> _saveMealToDatabase(int day, int mealCategoryId,
    Map<String, dynamic> meal, String familyHeadName) async {
  try {
    if (meal['recipe_id'] == null || meal['name'] == null) {
      throw Exception(
          'Invalid meal data: recipe_id or name is null. Meal: $meal');
    }

    await Supabase.instance.client.from('mealplan').insert({
      'day': day,
      'meal_category_id': mealCategoryId,
      'recipe_id': meal['recipe_id'],
      'meal_name': meal['name'],
      'family_head': familyHeadName,
    });
  } catch (e) {
    print('Error saving meal to database: $e');
  }
}

// Function to show success dialog
void _showSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Success'),
      content: const Text('Meal plan generated and saved successfully!'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
