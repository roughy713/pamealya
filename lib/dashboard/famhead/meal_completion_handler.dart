import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'meal_plan_generator.dart';
import 'famhead_dashboard.dart';
import 'meal_plan_dashboard.dart';

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
    bool isChecked = false;
    bool isLoading = false;

    final supabase = Supabase.instance.client;

    // Show confirmation dialog first
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Generate New Meal Plan',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Do you want to Generate New Meal Plan?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: isChecked,
                        activeColor: Colors.green,
                        onChanged: (bool? value) {
                          setState(() {
                            isChecked = value ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: const Text(
                          'Note: Please check the details of all the family members including the Family Head, especially the Allergens.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: isChecked
                        ? () async {
                            try {
                              setState(() {
                                isLoading = true;
                              });

                              // Delete existing meal plan
                              await supabase
                                  .from('mealplan')
                                  .delete()
                                  .eq('family_head', familyHeadName);

                              // Generate new meal plan
                              await generateMealPlan(context, familyHeadName);

                              // Split the family head name for later use
                              final names = familyHeadName.split(' ');
                              final firstName = names[0];
                              final lastName = names.length > 1 ? names[1] : '';

                              // Close confirmation dialog
                              Navigator.of(dialogContext).pop();

                              // Show success dialog
                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (BuildContext context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Container(
                                      width: 500, // Increased width
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: const [
                                              Icon(
                                                Icons.check_circle,
                                                color: Color(0xFF4CAF50),
                                                size: 40,
                                              ),
                                              SizedBox(width: 10),
                                              Text(
                                                'Success!',
                                                style: TextStyle(
                                                  color: Color(0xFF4CAF50),
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 24,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          const Text(
                                            'Your 7-day meal plan has been successfully generated!',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 14),
                                          const Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              'The meal plan includes:',
                                              style: TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          const Align(
                                            alignment: Alignment.center,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    '• Daily breakfast options'),
                                                Text('• Lunch selections'),
                                                Text('• Dinner choices'),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(height: 24),
                                          Align(
                                            alignment: Alignment.centerRight,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                Navigator.pushReplacement(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        FamHeadDashboard(
                                                      firstName: firstName,
                                                      lastName: lastName,
                                                      currentUserUsername: '',
                                                      currentUserId: '',
                                                    ),
                                                  ),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    const Color(0xFF4CAF50),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 40,
                                                  vertical: 15,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Got it!',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text(
                                      'Error',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                    content: Text(
                                        'Error generating new meal plan: ${e.toString()}'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
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
}
