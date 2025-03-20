import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'famhead_notification_service.dart';
import 'meal_plan_generator.dart';
import 'famhead_dashboard.dart';

class MealPlanCompletionHandler {
  static Future<bool> checkAllMealsCompleted(
      List<List<Map<String, dynamic>>> mealPlanData) async {
    if (mealPlanData.isEmpty) {
      return false;
    }

    bool validMealFound = false;

    for (var dayMeals in mealPlanData) {
      for (var meal in dayMeals) {
        if (meal['mealplan_id'] != null) {
          validMealFound = true;
          if (meal['is_completed'] != true) {
            return false;
          }
        }
      }
    }

    return validMealFound;
  }

  static Future<void> showCompletionDialog(
      BuildContext context, String familyHeadName, String userId) async {
    final supabase = Supabase.instance.client;

    // Check existing meal plan with both user_id and family_head
    final mealPlanQuery = await supabase
        .from('mealplan')
        .select()
        .eq('user_id', userId)
        .eq('family_head', familyHeadName);

    if (mealPlanQuery.isEmpty) {
      return;
    }

    bool generateNewPlan = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.celebration, color: Colors.green, size: 30),
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                  child: const Text('Close',
                      style: TextStyle(color: Colors.black)),
                ),
                ElevatedButton(
                  onPressed: generateNewPlan
                      ? () => _handleNewPlanGeneration(
                          context, familyHeadName, userId)
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
                    style: TextStyle(fontWeight: FontWeight.bold),
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

  static Future<void> _handleNewPlanGeneration(
      BuildContext context, String familyHeadName, String userId) async {
    bool isChecked = false;
    bool isLoading = false;

    final supabase = Supabase.instance.client;

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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
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
                      const Expanded(
                        child: Text(
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
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.black)),
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

                              // Delete existing meal plan using both user_id and family_head
                              await supabase
                                  .from('mealplan')
                                  .delete()
                                  .eq('user_id', userId)
                                  .eq('family_head', familyHeadName);

                              // Generate new meal plan
                              await generateMealPlan(context, familyHeadName);

                              // Create notification for admin using the notification service
                              final notificationService =
                                  FamilyHeadNotificationService(
                                      supabase: supabase);

                              await notificationService.notifyMealPlanGenerated(
                                  userId, familyHeadName);

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
                                      width: 500,
                                      padding: const EdgeInsets.all(24),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Row(
                                            children: [
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
                                              style: TextStyle(fontSize: 14),
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
                                                      currentUserId: userId,
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
                      style: TextStyle(fontWeight: FontWeight.bold),
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
