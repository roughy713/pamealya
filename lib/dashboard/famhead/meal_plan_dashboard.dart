// lib/meal_plan_dashboard.dart
import 'package:flutter/material.dart';

class MealPlanDashboard extends StatelessWidget {
  final List<List<Map<String, dynamic>>> mealPlanData;

  const MealPlanDashboard({Key? key, required this.mealPlanData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Check if the meal plan is empty
    bool isEmpty = mealPlanData.every((day) => day.isEmpty);

    if (isEmpty) {
      // If no meal plan data, display a message
      return const Center(
        child: Text(
          'No meal plan generated',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    // Otherwise, display the table
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Table(
          defaultColumnWidth:
              FixedColumnWidth(150.0), // Set fixed width for columns
          border: TableBorder.all(color: Colors.grey),
          children: [
            // Header Row
            TableRow(
              decoration: const BoxDecoration(color: Colors.greenAccent),
              children: [
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Day',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Breakfast',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Lunch',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    'Dinner',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            // Meal Plan Rows
            for (int i = 0; i < mealPlanData.length; i++)
              TableRow(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      'Day ${i + 1}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      mealPlanData[i].isNotEmpty &&
                              mealPlanData[i][0]['meal_name'] != null
                          ? mealPlanData[i][0]['meal_name']
                          : '',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      mealPlanData[i].isNotEmpty &&
                              mealPlanData[i][1]['meal_name'] != null
                          ? mealPlanData[i][1]['meal_name']
                          : '',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      mealPlanData[i].isNotEmpty &&
                              mealPlanData[i][2]['meal_name'] != null
                          ? mealPlanData[i][2]['meal_name']
                          : '',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
