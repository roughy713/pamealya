// lib/meal_plan_dashboard.dart
import 'package:flutter/material.dart';

class MealPlanDashboard extends StatelessWidget {
  final List<List<Map<String, dynamic>>> mealPlanData;

  const MealPlanDashboard({Key? key, required this.mealPlanData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isEmpty = mealPlanData.every((day) => day.isEmpty);

    if (isEmpty) {
      return const Center(
        child: Text(
          'No meal plan generated',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: Table(
          defaultColumnWidth: FixedColumnWidth(150.0),
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
                  _buildMealCell(context,
                      mealPlanData[i].isNotEmpty ? mealPlanData[i][0] : null),
                  _buildMealCell(context,
                      mealPlanData[i].length > 1 ? mealPlanData[i][1] : null),
                  _buildMealCell(context,
                      mealPlanData[i].length > 2 ? mealPlanData[i][2] : null),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCell(BuildContext context, Map<String, dynamic>? meal) {
    if (meal == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('', textAlign: TextAlign.center),
      );
    }

    return GestureDetector(
      onTap: () {
        _showMealDetailsDialog(context, meal);
      },
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          meal['meal_name'] ?? 'Unknown',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }

  void _showMealDetailsDialog(BuildContext context, Map<String, dynamic> meal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(meal['meal_name'] ?? 'Meal Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meal Type: ${meal['meal_type'] ?? 'Unknown'}'),
              Text('Meal ID: ${meal['meal_id'] ?? 'N/A'}'),
              // Add more meal details here if available in the data
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
