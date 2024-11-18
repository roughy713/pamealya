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
    // Check if mealPlanData is empty
    if (mealPlanData.isEmpty || familyMembers.isEmpty) {
      return Center(
        child: Text(
          'No meal plan generated',
          style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 10.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16.0),
            child: Table(
              defaultColumnWidth: FixedColumnWidth(100.0),
              border: TableBorder.all(
                color: Colors.grey.withOpacity(0.5),
                width: 1,
                borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              ),
              children: [
                // Header Row
                TableRow(
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                  ),
                  children: [
                    _buildHeader('Day'),
                    _buildHeader('Breakfast'),
                    for (var member in familyMembers)
                      _buildHeader(member['first_name'] ?? 'Unknown'),
                    _buildHeader('Lunch'),
                    for (var member in familyMembers)
                      _buildHeader(member['first_name'] ?? 'Unknown'),
                    _buildHeader('Dinner'),
                    for (var member in familyMembers)
                      _buildHeader(member['first_name'] ?? 'Unknown'),
                  ],
                ),
                // Rows for each day
                for (int i = 0; i < mealPlanData.length; i++)
                  _buildTableRow(i, mealPlanData[i]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildMealCell(String? mealName) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        mealName ?? 'N/A',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  Widget _buildPortionCell(String portion) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        portion,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }

  TableRow _buildTableRow(int dayIndex, List<Map<String, dynamic>> meals) {
    return TableRow(
      decoration: BoxDecoration(
        color: dayIndex % 2 == 0 ? Colors.white : Colors.grey.withOpacity(0.1),
      ),
      children: [
        _buildMealCell('Day ${dayIndex + 1}'),
        _buildMealCell(meals.isNotEmpty ? meals[0]['meal_name'] : 'N/A'),
        for (var member in familyMembers)
          _buildPortionCell(determinePortionForAge(member['age'] ?? 0)),
        _buildMealCell(meals.length > 1 ? meals[1]['meal_name'] : 'N/A'),
        for (var member in familyMembers)
          _buildPortionCell(determinePortionForAge(member['age'] ?? 0)),
        _buildMealCell(meals.length > 2 ? meals[2]['meal_name'] : 'N/A'),
        for (var member in familyMembers)
          _buildPortionCell(determinePortionForAge(member['age'] ?? 0)),
      ],
    );
  }

  String determinePortionForAge(int age) {
    if (age <= 3) return '1/2';
    if (age <= 6) return '1';
    if (age <= 9) return '1 1/2';
    if (age <= 12) return '2';
    return '2 1/2';
  }
}
