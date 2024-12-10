import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> generateMealPlan(
    BuildContext context, String familyHeadName) async {
  try {
    final supabase = Supabase.instance.client;

    // Fetch existing meal plan
    final existingMealPlanResponse = await supabase
        .from('mealplan')
        .select()
        .eq('family_head', familyHeadName);

    if (existingMealPlanResponse.isNotEmpty) {
      // Show dialog if meal plan already exists
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Meal Plan Exists'),
          content: const Text('A meal plan has already been generated.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    // Fetch family members
    final familyMembersResponse = await supabase
        .from('familymember')
        .select('familymember_id, religion')
        .eq('family_head', familyHeadName);

    if (familyMembersResponse.isEmpty) {
      throw 'No family members found for this family head.';
    }

    final familyMembers = familyMembersResponse as List<dynamic>;
    final familyMemberIds =
        familyMembers.map((member) => member['familymember_id']).toList();

    // Fetch allergens for family members
    final allergensResponse = await supabase
        .from('familymember_allergens')
        .select('familymember_id, is_dairy, is_nuts, is_seafood');

    final allergens = allergensResponse
        .where(
            (allergen) => familyMemberIds.contains(allergen['familymember_id']))
        .toList();

    // Consolidate allergy information
    final hasAllergy = {
      'is_dairy': allergens.any((a) => a['is_dairy'] == true),
      'is_nuts': allergens.any((a) => a['is_nuts'] == true),
      'is_seafood': allergens.any((a) => a['is_seafood'] == true),
    };

    // Check if anyone in the family is Islamic
    final isHalalRequired =
        familyMembers.any((member) => member['religion'] == 'Islam');

    // Fetch all meals
    final mealsResponse = await supabase.from('meal').select();
    final meals = mealsResponse as List<dynamic>;

    // Filter meals based on allergens and halal requirements
    final filteredMeals = meals.where((meal) {
      final isExcludedForAllergens =
          (hasAllergy['is_dairy'] == true && meal['is_dairy'] == true) ||
              (hasAllergy['is_nuts'] == true && meal['is_nuts'] == true) ||
              (hasAllergy['is_seafood'] == true && meal['is_seafood'] == true);

      final isExcludedForHalal = isHalalRequired && meal['is_halal'] != true;

      // Include only meals that are not excluded
      return !isExcludedForAllergens && !isExcludedForHalal;
    }).toList();

    // Separate meals by category
    List breakfasts = filteredMeals
        .where((meal) =>
            meal['recipe_id'] != null &&
            (meal['meal_category_id'] == 1 || // Breakfast
                meal['meal_category_id'] == 5 || // All
                meal['meal_category_id'] == 6)) // Breakfast & Lunch
        .toList();

    List lunches = filteredMeals
        .where((meal) =>
            meal['recipe_id'] != null &&
            (meal['meal_category_id'] == 2 || // Lunch
                meal['meal_category_id'] == 5 || // All
                meal['meal_category_id'] == 6 || // Breakfast & Lunch
                meal['meal_category_id'] == 7)) // Lunch & Dinner
        .toList();

    List dinners = filteredMeals
        .where((meal) =>
            meal['recipe_id'] != null &&
            (meal['meal_category_id'] == 3 || // Dinner
                meal['meal_category_id'] == 5 || // All
                meal['meal_category_id'] == 7)) // Lunch & Dinner
        .toList();

    List snacks = filteredMeals
        .where((meal) =>
            meal['recipe_id'] != null && meal['meal_category_id'] == 4) // Snack
        .toList();

    // Validate that there are enough unique meals in each category
    if (breakfasts.length < 7) throw 'Not enough breakfast meals.';
    if (lunches.length < 7) throw 'Not enough lunch meals.';
    if (dinners.length < 7) throw 'Not enough dinner meals.';
    if (snacks.length < 7) throw 'Not enough snack meals.';

    // Shuffle and select 7 meals from each category
    breakfasts.shuffle();
    lunches.shuffle();
    dinners.shuffle();
    snacks.shuffle();

    List<List<Map<String, dynamic>>> newMealPlan = List.generate(
        7,
        (index) => [
              breakfasts[index],
              lunches[index],
              dinners[index],
              snacks[index],
            ]);

    // Save meal plan to the database
    for (int day = 0; day < newMealPlan.length; day++) {
      final dailyMeals = newMealPlan[day];
      await _saveMealToDatabase(
          day + 1, 1, dailyMeals[0], familyHeadName); // Breakfast
      await _saveMealToDatabase(
          day + 1, 2, dailyMeals[1], familyHeadName); // Lunch
      await _saveMealToDatabase(
          day + 1, 3, dailyMeals[2], familyHeadName); // Dinner
      await _saveMealToDatabase(
          day + 1, 4, dailyMeals[3], familyHeadName); // Snack
    }

    // Show success dialog
    _showSuccessDialog(context);
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error generating meal plan: ${e.toString()}')),
    );
  }
}

Future<void> _saveMealToDatabase(int day, int mealCategoryId,
    Map<String, dynamic> meal, String familyHeadName) async {
  try {
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
