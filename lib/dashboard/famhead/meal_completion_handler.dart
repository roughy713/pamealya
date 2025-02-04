import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'meal_plan_generator.dart';
import 'famhead_dashboard.dart';

class MealPlanCompletionHandler {
  // Check if all meals in the meal plan are completed
  static Future<bool> checkAllMealsCompleted(
      List<List<Map<String, dynamic>>> mealPlanData) async {
    // First check if the meal plan data is empty
    if (mealPlanData.isEmpty) {
      return false;
    }

    bool validMealFound = false;

    // Check all meals
    for (var dayMeals in mealPlanData) {
      for (var meal in dayMeals) {
        // Only consider meals that have a valid mealplan_id
        if (meal['mealplan_id'] != null) {
          validMealFound = true;
          // If any meal is not completed, return false
          if (meal['is_completed'] != true) {
            return false;
          }
        }
      }
    }

    // Return false if no valid meals were found
    // Return true only if we found valid meals and they were all completed
    return validMealFound;
  }

  // Show the completion dialog with congratulations message and new plan option
  static Future<void> showCompletionDialog(
      BuildContext context, String familyHeadName) async {
    // First check if user has any meal plan
    final supabase = Supabase.instance.client;
    final mealPlanQuery = await supabase
        .from('mealplan')
        .select()
        .eq('family_head', familyHeadName);

    // Don't show dialog for new users with no meal plan
    if (mealPlanQuery.isEmpty) {
      return;
    }

    bool generateNewPlan = false;

    showDialog(
      context: context,
      barrierDismissible: false, // User must use a button to dismiss the dialog
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.celebration,
                    color: Colors.green,
                    size: 30,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Congratulations!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                      fontSize: 24,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You have completed the 7-Day meal plan!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Would you like to generate a new meal plan?',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Checkbox(
                        value: generateNewPlan,
                        activeColor: Colors.green,
                        onChanged: (bool? value) {
                          setState(() {
                            generateNewPlan = value ?? false;
                          });
                        },
                      ),
                      const Text(
                        'Note: This will replace your current meal plan',
                        style: TextStyle(
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                ElevatedButton(
                  onPressed: generateNewPlan
                      ? () => _handleNewPlanGeneration(context, familyHeadName)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Generate New Meal Plan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              actionsPadding: const EdgeInsets.all(16),
            );
          },
        );
      },
    );
  }

  // Handle the generation of a new meal plan
  static Future<void> _handleNewPlanGeneration(
      BuildContext context, String familyHeadName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
            ),
          );
        },
      );

      final supabase = Supabase.instance.client;

      // Delete existing meal plan
      await supabase
          .from('mealplan')
          .delete()
          .eq('family_head', familyHeadName);

      // Remove loading indicator
      Navigator.of(context).pop();

      // Generate new meal plan
      await generateMealPlan(context, familyHeadName);

      // Close the completion dialog
      Navigator.of(context).pop();

      // Split the family head name into first and last name
      final names = familyHeadName.split(' ');
      final firstName = names[0];
      final lastName = names.length > 1 ? names[1] : '';

      // Refresh the dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FamHeadDashboard(
            firstName: firstName,
            lastName: lastName,
            currentUserUsername: '', // Add appropriate value
            currentUserId: '', // Add appropriate value
          ),
        ),
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New meal plan generated successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    } catch (e) {
      // Remove loading indicator if it's still showing
      if (context.mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating new meal plan: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }
}
