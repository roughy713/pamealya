// lib/meal_plan_dashboard.dart
import 'package:flutter/material.dart';

class MealPlanDashboard extends StatelessWidget {
  final List<List<Map<String, dynamic>>> mealPlanData;
  final List<Map<String, dynamic>> familyMembers;

  const MealPlanDashboard({
    Key? key,
    required this.mealPlanData,
    required this.familyMembers,
  }) : super(key: key);

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
          defaultColumnWidth: FixedColumnWidth(100.0),
          border: TableBorder.all(color: Colors.grey),
          children: [
            // Header Row
            TableRow(
              decoration: const BoxDecoration(color: Colors.greenAccent),
              children: [
                _buildHeaderCell('Day'),
                _buildHeaderCell('Breakfast'),
                _buildHeaderCell('1-3'),
                _buildHeaderCell('4-6'),
                _buildHeaderCell('7-9'),
                _buildHeaderCell('Lunch'),
                _buildHeaderCell('1-3'),
                _buildHeaderCell('4-6'),
                _buildHeaderCell('7-9'),
                _buildHeaderCell('Dinner'),
                _buildHeaderCell('1-3'),
                _buildHeaderCell('4-6'),
                _buildHeaderCell('7-9'),
              ],
            ),
            // Meal Plan Rows
            for (int i = 0; i < mealPlanData.length; i++)
              TableRow(
                children: [
                  _buildDataCell('Day ${i + 1}'),
                  _buildMealCell(context,
                      mealPlanData[i].isNotEmpty ? mealPlanData[i][0] : null),
                  _buildPortionCell('1/2'),
                  _buildPortionCell('1'),
                  _buildPortionCell('1 1/2'),
                  _buildMealCell(context,
                      mealPlanData[i].length > 1 ? mealPlanData[i][1] : null),
                  _buildPortionCell('1/2'),
                  _buildPortionCell('1'),
                  _buildPortionCell('1 1/2'),
                  _buildMealCell(context,
                      mealPlanData[i].length > 2 ? mealPlanData[i][2] : null),
                  _buildPortionCell('1/2'),
                  _buildPortionCell('1'),
                  _buildPortionCell('1 1/2'),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildDataCell(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
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

  Widget _buildPortionCell(String portion) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        portion,
        textAlign: TextAlign.center,
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
